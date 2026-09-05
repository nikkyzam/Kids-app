// Tests for the receipt verifier.
//
// The point of nearly all of them is one rule: a 200 means the store gave a
// verdict, and anything else means we could not get one. The client revokes on
// a verdict and does nothing on an outage, so every case where those two blur
// costs a real parent a purchase they paid for. Code review found six such
// leaks in the first version of this file; these are the tests that would have
// caught them.
//
// Run: deno test --allow-env supabase/functions/verify-purchase/

import { handleRequest, resetCachesForTesting } from "./verify.ts";

// Three assertions, written here rather than pulled from @std/assert: this
// suite gates whether a parent keeps what they paid for, and it should not
// need the network to run.
function assert(condition: unknown, message = "expected true"): void {
  if (!condition) throw new Error(message);
}

function assertFalse(condition: unknown, message = "expected false"): void {
  if (condition) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message?: string): void {
  if (!Object.is(actual, expected)) {
    throw new Error(
      message ??
        `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

// ─── Harness ─────────────────────────────────────────────────────────────────

const ANDROID_PACKAGE = "com.nikkyzam.playsteps.app";
const APPLE_BUNDLE = "com.nikkyzam.playsteps.app";
const PREMIUM = "playsteps_premium_lifetime";
const PREMIUM_PLUS = "playsteps_premium_plus_yearly";

const ENV_KEYS = [
  "ANDROID_PACKAGE_NAME",
  "GOOGLE_SERVICE_ACCOUNT_EMAIL",
  "GOOGLE_SERVICE_ACCOUNT_KEY",
  "APPLE_BUNDLE_ID",
  "APPLE_ISSUER_ID",
  "APPLE_KEY_ID",
  "APPLE_PRIVATE_KEY",
];

function pem(der: ArrayBuffer): string {
  const bytes = new Uint8Array(der);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  const body = btoa(binary).replace(/(.{64})/g, "$1\n");
  return `-----BEGIN PRIVATE KEY-----\n${body}\n-----END PRIVATE KEY-----`;
}

/// Real keys, generated per run. The signing paths are part of what is under
/// test — a malformed assertion would fail against the store, and a stub key
/// would hide that.
async function generateKeys(): Promise<{ rsa: string; ec: string }> {
  const rsa = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const ec = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  return {
    rsa: pem(await crypto.subtle.exportKey("pkcs8", rsa.privateKey)),
    ec: pem(await crypto.subtle.exportKey("pkcs8", ec.privateKey)),
  };
}

const keys = await generateKeys();

function configureAll(): void {
  Deno.env.set("ANDROID_PACKAGE_NAME", ANDROID_PACKAGE);
  Deno.env.set(
    "GOOGLE_SERVICE_ACCOUNT_EMAIL",
    "sa@example.iam.gserviceaccount.com",
  );
  Deno.env.set("GOOGLE_SERVICE_ACCOUNT_KEY", keys.rsa);
  Deno.env.set("APPLE_BUNDLE_ID", APPLE_BUNDLE);
  Deno.env.set("APPLE_ISSUER_ID", "issuer-1");
  Deno.env.set("APPLE_KEY_ID", "key-1");
  Deno.env.set("APPLE_PRIVATE_KEY", keys.ec);
}

function clearEnv(): void {
  for (const key of ENV_KEYS) Deno.env.delete(key);
}

interface Reply {
  status: number;
  body?: unknown;
}

/// Answers store requests from a table of URL substrings, and records what was
/// asked so the sandbox-fallback order can be checked.
function stubFetch(replies: Array<[string, Reply | Reply[]]>): string[] {
  const seen: string[] = [];
  const queues = new Map<string, Reply[]>(
    replies.map(([k, v]) => [k, Array.isArray(v) ? [...v] : [v]]),
  );

  globalThis.fetch = ((input: string | URL | Request) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.href
      : input.url;
    seen.push(url);

    // The Google token exchange is incidental to every Android test.
    if (url.includes("oauth2.googleapis.com")) {
      return Promise.resolve(
        new Response(JSON.stringify({ access_token: "t", expires_in: 3600 }), {
          status: 200,
        }),
      );
    }

    for (const [fragment, queue] of queues) {
      if (!url.includes(fragment)) continue;
      const reply = queue.length > 1 ? queue.shift()! : queue[0];
      return Promise.resolve(
        new Response(
          reply.body === undefined ? "" : JSON.stringify(reply.body),
          { status: reply.status },
        ),
      );
    }
    throw new Error(`unstubbed request: ${url}`);
  }) as typeof fetch;

  return seen;
}

const realFetch = globalThis.fetch;

function post(body: unknown): Request {
  return new Request("https://edge.test/verify-purchase", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

interface Outcome {
  status: number;
  valid: boolean;
  reason?: string;
  expiresAt?: number;
}

async function verify(body: unknown): Promise<Outcome> {
  const response = await handleRequest(post(body));
  const json = await response.json();
  return { status: response.status, ...json };
}

/// Wraps a test so env, caches and fetch cannot leak into the next one.
function scenario(name: string, fn: () => Promise<void>): void {
  Deno.test(name, async () => {
    resetCachesForTesting();
    clearEnv();
    configureAll();
    try {
      await fn();
    } finally {
      globalThis.fetch = realFetch;
      clearEnv();
      resetCachesForTesting();
    }
  });
}

const androidRequest = {
  platform: "android",
  productId: PREMIUM,
  token: "play-token",
};

/// A JWS is three base64url segments; only the middle one is ever read, and
/// only to find the transaction id. Nothing here is trusted.
function fakeJws(payload: Record<string, unknown>): string {
  const encode = (value: unknown) =>
    btoa(JSON.stringify(value)).replace(/\+/g, "-").replace(/\//g, "_")
      .replace(/=+$/, "");
  return `${encode({ alg: "ES256" })}.${encode(payload)}.signature`;
}

function iosRequest(
  payload: Record<string, unknown> = { transactionId: "tx-1" },
  productId = PREMIUM,
) {
  return { platform: "ios", productId, token: fakeJws(payload) };
}

function appleTransaction(fields: Record<string, unknown>): Reply {
  return {
    status: 200,
    body: {
      signedTransactionInfo: fakeJws({
        bundleId: APPLE_BUNDLE,
        productId: PREMIUM,
        transactionId: "tx-1",
        ...fields,
      }),
    },
  };
}

// ─── Misconfiguration is never a rejection ───────────────────────────────────

scenario("a missing Android package answers 503, not a rejection", async () => {
  Deno.env.delete("ANDROID_PACKAGE_NAME");
  stubFetch([]);

  const result = await verify(androidRequest);

  // The README's deploy-then-set-secrets order opens exactly this window. A
  // 200 here would revoke every paying customer on their next launch.
  assertEquals(result.status, 503);
});

scenario("a missing Google key answers 503", async () => {
  Deno.env.delete("GOOGLE_SERVICE_ACCOUNT_KEY");
  stubFetch([]);

  assertEquals((await verify(androidRequest)).status, 503);
});

scenario("a missing Apple bundle id answers 503", async () => {
  Deno.env.delete("APPLE_BUNDLE_ID");
  stubFetch([]);

  assertEquals((await verify(iosRequest())).status, 503);
});

scenario("a missing Apple private key answers 503", async () => {
  Deno.env.delete("APPLE_PRIVATE_KEY");
  stubFetch([]);

  assertEquals((await verify(iosRequest())).status, 503);
});

// ─── Google Play: outage versus verdict ──────────────────────────────────────

scenario("Play 404 is the store saying no such purchase", async () => {
  stubFetch([["androidpublisher", { status: 404 }]]);

  const result = await verify(androidRequest);

  assertEquals(result.status, 200);
  assertFalse(result.valid);
});

scenario("Play 400 rejects a malformed token", async () => {
  // What a forged token looks like. Treating it as an outage would grant it
  // permanently, since every later launch gets the same answer.
  stubFetch([["androidpublisher", { status: 400 }]]);

  const result = await verify(androidRequest);

  assertEquals(result.status, 200);
  assertFalse(result.valid);
});

scenario("Play 410 rejects a purged subscription token", async () => {
  // Google purges tokens for subscriptions lapsed long enough; an outage here
  // would keep Premium Plus alive forever.
  stubFetch([["androidpublisher", { status: 410 }]]);

  const result = await verify({ ...androidRequest, subscription: true });

  assertEquals(result.status, 200);
  assertFalse(result.valid);
});

for (const status of [401, 403, 408, 429, 500, 503]) {
  scenario(`Play ${status} is an outage, not a verdict`, async () => {
    stubFetch([["androidpublisher", { status }]]);

    assertEquals((await verify(androidRequest)).status, 503);
  });
}

// ─── Google Play: what the answers mean ──────────────────────────────────────

scenario("a purchased one-time product is valid", async () => {
  stubFetch([["androidpublisher", {
    status: 200,
    body: { purchaseState: 0 },
  }]]);

  const result = await verify(androidRequest);

  assert(result.valid);
});

scenario("a cancelled one-time product is not", async () => {
  stubFetch([["androidpublisher", {
    status: 200,
    body: { purchaseState: 1 },
  }]]);

  assertFalse((await verify(androidRequest)).valid);
});

scenario("an active subscription is valid and reports its expiry", async () => {
  const expiry = new Date(Date.now() + 60 * 86_400_000);
  stubFetch([["androidpublisher", {
    status: 200,
    body: {
      subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
      lineItems: [{ expiryTime: expiry.toISOString() }],
    },
  }]]);

  const result = await verify({
    ...androidRequest,
    productId: PREMIUM_PLUS,
    subscription: true,
  });

  assert(result.valid);
  assertEquals(result.expiresAt, expiry.getTime());
});

scenario("a cancelled subscription keeps its remaining months", async () => {
  // Google's CANCELED means auto-renew is off, not that access has ended.
  // Reading it as a rejection revoked ten months a parent had paid for.
  const expiry = new Date(Date.now() + 300 * 86_400_000);
  stubFetch([["androidpublisher", {
    status: 200,
    body: {
      subscriptionState: "SUBSCRIPTION_STATE_CANCELED",
      lineItems: [{ expiryTime: expiry.toISOString() }],
    },
  }]]);

  const result = await verify({
    ...androidRequest,
    productId: PREMIUM_PLUS,
    subscription: true,
  });

  assert(result.valid);
  assertEquals(result.expiresAt, expiry.getTime());
});

scenario("a cancelled subscription past its expiry is not valid", async () => {
  stubFetch([["androidpublisher", {
    status: 200,
    body: {
      subscriptionState: "SUBSCRIPTION_STATE_CANCELED",
      lineItems: [{
        expiryTime: new Date(Date.now() - 86_400_000).toISOString(),
      }],
    },
  }]]);

  const result = await verify({
    ...androidRequest,
    productId: PREMIUM_PLUS,
    subscription: true,
  });

  assertFalse(result.valid);
});

scenario("an expired subscription is not valid", async () => {
  stubFetch([["androidpublisher", {
    status: 200,
    body: {
      subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
      lineItems: [{
        expiryTime: new Date(Date.now() - 86_400_000).toISOString(),
      }],
    },
  }]]);

  assertFalse(
    (await verify({
      ...androidRequest,
      productId: PREMIUM_PLUS,
      subscription: true,
    }))
      .valid,
  );
});

// ─── App Store ───────────────────────────────────────────────────────────────

scenario("a token that is not a signed transaction is rejected", async () => {
  stubFetch([]);

  const result = await verify({
    platform: "ios",
    productId: PREMIUM,
    token: "not-a-jws",
  });

  assertEquals(result.status, 200);
  assertFalse(result.valid);
});

scenario(
  "a signed transaction with no transaction id is rejected",
  async () => {
    stubFetch([]);

    assertFalse((await verify(iosRequest({ productId: PREMIUM }))).valid);
  },
);

scenario("a confirmed non-consumable is valid and never expires", async () => {
  stubFetch([["api.storekit", appleTransaction({})]]);

  const result = await verify(iosRequest());

  assert(result.valid);
  assertEquals(result.expiresAt, undefined);
});

scenario("production is asked before sandbox", async () => {
  const seen = stubFetch([
    ["api.storekit-sandbox", appleTransaction({})],
    ["api.storekit.itunes", { status: 404 }],
  ]);

  const result = await verify(iosRequest());

  assert(result.valid);
  assertEquals(seen.length, 2);
  assert(seen[0].includes("api.storekit.itunes"), seen[0]);
  assert(seen[1].includes("api.storekit-sandbox"), seen[1]);
});

scenario("a transaction neither environment knows is rejected", async () => {
  stubFetch([["api.storekit", { status: 404 }]]);

  const result = await verify(iosRequest());

  assertEquals(result.status, 200);
  assertFalse(result.valid);
});

scenario("an App Store 500 is an outage", async () => {
  stubFetch([["api.storekit", { status: 500 }]]);

  assertEquals((await verify(iosRequest())).status, 503);
});

scenario("an App Store 401 is an outage, not a rejection", async () => {
  // Our credentials being wrong is our problem.
  stubFetch([["api.storekit", { status: 401 }]]);

  assertEquals((await verify(iosRequest())).status, 503);
});

scenario("a transaction from another app is rejected", async () => {
  stubFetch([[
    "api.storekit",
    appleTransaction({ bundleId: "com.someone.else" }),
  ]]);

  assertFalse((await verify(iosRequest())).valid);
});

scenario(
  "Apple's answer governs the product, not the client's claim",
  async () => {
    // The forgery this design has to stop: a JWS asserting the lifetime unlock
    // when Apple's own record is for something else entirely.
    stubFetch([[
      "api.storekit",
      appleTransaction({ productId: "some_other_sku" }),
    ]]);

    const result = await verify(iosRequest({ transactionId: "tx-1" }, PREMIUM));

    assertFalse(result.valid);
  },
);

scenario("a refunded purchase is rejected", async () => {
  stubFetch([[
    "api.storekit",
    appleTransaction({ revocationDate: Date.now() }),
  ]]);

  assertFalse((await verify(iosRequest())).valid);
});

scenario("a live subscription is valid and reports its expiry", async () => {
  const expiresDate = Date.now() + 30 * 86_400_000;
  stubFetch([[
    "api.storekit",
    appleTransaction({ productId: PREMIUM_PLUS, expiresDate }),
  ]]);

  const result = await verify(
    iosRequest({ transactionId: "tx-1" }, PREMIUM_PLUS),
  );

  assert(result.valid);
  assertEquals(result.expiresAt, expiresDate);
});

scenario("a lapsed subscription is rejected", async () => {
  stubFetch([[
    "api.storekit",
    appleTransaction({
      productId: PREMIUM_PLUS,
      expiresDate: Date.now() - 86_400_000,
    }),
  ]]);

  const result = await verify(
    iosRequest({ transactionId: "tx-1" }, PREMIUM_PLUS),
  );

  assertFalse(result.valid);
});

// ─── Entry point ─────────────────────────────────────────────────────────────

scenario("a GET is refused", async () => {
  const response = await handleRequest(
    new Request("https://edge.test/verify-purchase"),
  );

  assertEquals(response.status, 405);
});

scenario("a malformed body is refused", async () => {
  const response = await handleRequest(
    new Request("https://edge.test/verify-purchase", {
      method: "POST",
      body: "{ not json",
    }),
  );

  assertEquals(response.status, 400);
});

scenario("a request with no token is refused", async () => {
  assertEquals(
    (await verify({ platform: "android", productId: PREMIUM })).status,
    400,
  );
});
