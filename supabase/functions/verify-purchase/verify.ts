// Server-side receipt validation for PlaySteps.
//
// The app's local check — "the store handed us a non-empty token" — is
// defeatable on a rooted or jailbroken device. This asks the store itself
// whether a purchase is real, which is the only answer that cannot be forged
// on the client.
//
// It grants nothing and stores nothing. It answers one question about one
// receipt, and the app decides what to do with the answer. That keeps the
// function stateless, keeps a parent's purchase history off this server, and
// means an outage degrades to "unverified" rather than to "logged out".
//
// ─── The one rule ────────────────────────────────────────────────────────────
//
// A 200 means the store gave a verdict. Anything else means we could not get
// one. The client revokes on a verdict and does nothing on an outage, so
// answering `valid: false` for a problem of our own — a missing secret, a
// throttled API, an Apple hiccup — takes a purchase away from someone who paid
// for it. Every "we could not ask" path therefore throws [Unavailable], and
// the only things that reach `valid: false` are the store saying no.
//
// Deploy:
//   supabase functions deploy verify-purchase
//   supabase secrets set \
//     ANDROID_PACKAGE_NAME=com.nikkyzam.playsteps.app \
//     GOOGLE_SERVICE_ACCOUNT_EMAIL=...@...iam.gserviceaccount.com \
//     GOOGLE_SERVICE_ACCOUNT_KEY="$(cat google-key.pem)" \
//     APPLE_BUNDLE_ID=com.nikkyzam.playsteps.app \
//     APPLE_ISSUER_ID=... APPLE_KEY_ID=... \
//     APPLE_PRIVATE_KEY="$(cat AuthKey_XXXX.p8)"
//
// See README.md → "Deploy server-side receipt validation" for how to obtain
// each.

export interface VerifyRequest {
  platform: "android" | "ios";
  productId: string;
  /// Android: the purchase token. iOS: the JWS signed transaction that
  /// StoreKit 2 hands back as `serverVerificationData`.
  token: string;
  /// Android only: whether this product is a subscription.
  subscription?: boolean;
}

export interface VerifyResponse {
  valid: boolean;
  /// Present when a subscription's expiry is known, so the client can stop
  /// asking until then. Milliseconds since epoch.
  expiresAt?: number;
  /// Why a receipt was rejected. Never shown to a parent verbatim — the app
  /// says "that purchase could not be verified" — but it is what makes a
  /// support conversation possible.
  reason?: string;
}

/// We could not obtain a verdict. Always becomes a 503, never a rejection.
export class Unavailable extends Error {}

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  // A missing secret is our problem, not evidence against the parent. Throwing
  // here is the difference between "verification is down" and "every paying
  // customer is revoked on their next launch".
  if (!value) throw new Unavailable(`${name} is not configured`);
  return value;
}

/// Whether a store's HTTP status is the store saying no, as opposed to the
/// store being unable to answer.
///
/// 401/403 mean our credentials are wrong, 408/429 mean try later, 5xx means
/// the store is unwell — none of those are facts about the purchase. Every
/// other 4xx is the store telling us this token is not a thing it issued.
export function isDefiniteRejection(status: number): boolean {
  if (status < 400 || status >= 500) return false;
  return status !== 401 && status !== 403 && status !== 408 && status !== 429;
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: VerifyResponse, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

// ─── JOSE helpers ────────────────────────────────────────────────────────────

function pemToDer(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN [A-Z ]+-----/, "")
    .replace(/-----END [A-Z ]+-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(body);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function base64Url(input: Uint8Array | string): string {
  let binary: string;
  if (typeof input === "string") {
    binary = input;
  } else {
    // Built with a loop rather than String.fromCharCode(...bytes): spreading a
    // large array blows the call-argument limit, and this helper is one edit
    // away from being handed something bigger than a signature.
    binary = "";
    for (const byte of input) binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

/// Reads the payload of a JWS **without verifying it**.
///
/// Only ever used on the token the client sent, and only to pull out the
/// transaction id we then ask Apple about. A forged JWS gets us a transaction
/// id Apple has never heard of, or one belonging to another app — both of
/// which its authoritative answer rejects below. Nothing from here is trusted.
export function decodeJwsPayload(jws: string): Record<string, unknown> {
  const segments = jws.split(".");
  if (segments.length !== 3) throw new Error("not a JWS");
  const padded = segments[1].replace(/-/g, "+").replace(/_/g, "/");
  return JSON.parse(
    new TextDecoder().decode(
      Uint8Array.from(atob(padded), (c) => c.charCodeAt(0)),
    ),
  );
}

// ─── Google Play ─────────────────────────────────────────────────────────────

/// Cached across invocations because an edge function instance is reused, and
/// minting a token costs a round trip and an RSA signature. Refreshed a minute
/// early so a token cannot expire mid-request. The imported key is cached too:
/// it never changes for the life of the instance.
let googleToken: { value: string; expiresAt: number } | null = null;
let googleKey: CryptoKey | null = null;

async function getGoogleAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (googleToken && googleToken.expiresAt > now + 60) return googleToken.value;

  const email = requireEnv("GOOGLE_SERVICE_ACCOUNT_EMAIL");
  const key = requireEnv("GOOGLE_SERVICE_ACCOUNT_KEY");

  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  googleKey ??= await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      googleKey,
      new TextEncoder().encode(`${header}.${claims}`),
    ),
  );
  const assertion = `${header}.${claims}.${base64Url(signature)}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    throw new Unavailable(
      `Google token exchange failed: ${await response.text()}`,
    );
  }

  const body = await response.json();
  googleToken = {
    value: body.access_token,
    expiresAt: now + (body.expires_in ?? 3600),
  };
  return googleToken.value;
}

/// Subscription states in which the parent still has access.
///
/// CANCELED is on this list deliberately: Google uses it for "auto-renew is
/// off", not "over". A parent who cancels a yearly plan in month two keeps it
/// until month twelve, and treating that as a rejection would revoke ten
/// months they have paid for. Expiry, not intent, is what ends access.
const ENTITLING_SUBSCRIPTION_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_CANCELED",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
]);

export async function verifyAndroid(
  request: VerifyRequest,
): Promise<VerifyResponse> {
  const pkg = requireEnv("ANDROID_PACKAGE_NAME");

  const accessToken = await getGoogleAccessToken();
  const base =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}`;
  const url = request.subscription
    ? `${base}/purchases/subscriptionsv2/tokens/${
      encodeURIComponent(request.token)
    }`
    : `${base}/purchases/products/${
      encodeURIComponent(request.productId)
    }/tokens/${encodeURIComponent(request.token)}`;

  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  // 404 for a token Google never issued, 400 for one that is malformed, 410
  // for a subscription token old enough to have been purged — all of them the
  // store saying "no such purchase", which is exactly what a forgery and a
  // long-lapsed subscription look like.
  if (isDefiniteRejection(response.status)) {
    return {
      valid: false,
      reason: `play rejected the token (${response.status})`,
    };
  }
  if (!response.ok) {
    throw new Unavailable(
      `Play API ${response.status}: ${await response.text()}`,
    );
  }

  const body = await response.json();

  if (request.subscription) {
    const state = body.subscriptionState;
    const expiry = body.lineItems?.[0]?.expiryTime;
    const expiresAt = expiry ? Date.parse(expiry) : undefined;
    // Both must hold: a state that entitles, and time left on the clock.
    const entitled = ENTITLING_SUBSCRIPTION_STATES.has(state) &&
      (expiresAt === undefined || expiresAt > Date.now());
    return {
      valid: entitled,
      expiresAt,
      reason: entitled ? undefined : `subscription state ${state}`,
    };
  }

  // One-time product: 0 = purchased, 1 = cancelled, 2 = pending. A refunded or
  // revoked purchase reports as cancelled, which is how a chargeback reaches
  // us.
  const purchased = body.purchaseState === 0;
  return {
    valid: purchased,
    reason: purchased ? undefined : `purchase state ${body.purchaseState}`,
  };
}

// ─── App Store ───────────────────────────────────────────────────────────────

const APPLE_PRODUCTION = "https://api.storekit.itunes.apple.com";
const APPLE_SANDBOX = "https://api.storekit-sandbox.itunes.apple.com";

let appleKey: CryptoKey | null = null;

/// Mints the ES256 token the App Store Server API authenticates with.
async function getAppleToken(): Promise<string> {
  const issuerId = requireEnv("APPLE_ISSUER_ID");
  const keyId = requireEnv("APPLE_KEY_ID");
  const privateKey = requireEnv("APPLE_PRIVATE_KEY");
  const bundleId = requireEnv("APPLE_BUNDLE_ID");

  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(
    JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }),
  );
  const claims = base64Url(JSON.stringify({
    iss: issuerId,
    iat: now,
    exp: now + 600,
    aud: "appstoreconnect-v1",
    bid: bundleId,
  }));

  appleKey ??= await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  // Web Crypto emits the raw r||s pair that JWS ES256 wants, so no DER
  // unwrapping is needed here.
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      appleKey,
      new TextEncoder().encode(`${header}.${claims}`),
    ),
  );
  return `${header}.${claims}.${base64Url(signature)}`;
}

/// Asks Apple about one transaction, trying production and then sandbox.
///
/// A build cannot know which environment its transaction came from, and Apple
/// answers 404 from the wrong one — the same shape as "no such transaction",
/// so the sandbox attempt has to happen before a 404 can be called a rejection.
async function fetchAppleTransaction(
  transactionId: string,
  token: string,
): Promise<Record<string, unknown> | null> {
  for (const host of [APPLE_PRODUCTION, APPLE_SANDBOX]) {
    const response = await fetch(
      `${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );

    if (response.ok) {
      const body = await response.json();
      // Apple's own answer, over TLS, about a transaction it issued. This is
      // the authoritative record; the client's copy was only ever a pointer.
      return decodeJwsPayload(body.signedTransactionInfo);
    }
    if (response.status === 404) continue;
    if (isDefiniteRejection(response.status)) return null;
    throw new Unavailable(
      `App Store API ${response.status}: ${await response.text()}`,
    );
  }
  return null;
}

export async function verifyIos(
  request: VerifyRequest,
): Promise<VerifyResponse> {
  const bundleId = requireEnv("APPLE_BUNDLE_ID");
  const token = await getAppleToken();

  // StoreKit 2 hands the app a JWS signed transaction, not the base64 app
  // receipt StoreKit 1 produced. Rather than verify that signature here, we
  // read the transaction id out of it and ask Apple directly — the same shape
  // as the Play path, where the client's token is a claim and the store's
  // answer is the fact.
  let claimed: Record<string, unknown>;
  try {
    claimed = decodeJwsPayload(request.token);
  } catch {
    return { valid: false, reason: "token is not a signed transaction" };
  }

  const transactionId = claimed.transactionId;
  if (typeof transactionId !== "string" || transactionId.length === 0) {
    return { valid: false, reason: "token carries no transaction id" };
  }

  const transaction = await fetchAppleTransaction(transactionId, token);
  if (transaction === null) {
    return { valid: false, reason: "unknown transaction" };
  }

  // Everything below is checked against Apple's copy, never the client's.
  if (transaction.bundleId !== bundleId) {
    return { valid: false, reason: "transaction belongs to another app" };
  }
  if (transaction.productId !== request.productId) {
    return { valid: false, reason: "transaction is for another product" };
  }
  if (typeof transaction.revocationDate === "number") {
    return { valid: false, reason: "purchase was refunded" };
  }

  // A subscription carries an expiry; a non-consumable does not, and is owned
  // forever.
  const expiresAt = typeof transaction.expiresDate === "number"
    ? transaction.expiresDate
    : undefined;
  if (expiresAt === undefined) return { valid: true };

  return {
    valid: expiresAt > Date.now(),
    expiresAt,
    reason: expiresAt > Date.now() ? undefined : "subscription expired",
  };
}

// ─── Request handling ────────────────────────────────────────────────────────

/// Clears the module-level caches. Tests only: an edge function instance is
/// reused deliberately, but a test that inherits another's cached key or token
/// is testing the wrong thing.
export function resetCachesForTesting(): void {
  googleToken = null;
  googleKey = null;
  appleKey = null;
}

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ valid: false, reason: "method not allowed" }, 405);
  }

  let request: VerifyRequest;
  try {
    request = await req.json();
  } catch {
    return json({ valid: false, reason: "malformed request" }, 400);
  }

  if (!request.token || !request.productId) {
    return json({ valid: false, reason: "missing token or productId" }, 400);
  }

  try {
    const result = request.platform === "ios"
      ? await verifyIos(request)
      : await verifyAndroid(request);
    return json(result);
  } catch (error) {
    // A 5xx, not a `valid: false` — see "The one rule" at the top of the file.
    console.error("verification unavailable", error);
    return json({ valid: false, reason: "verification unavailable" }, 503);
  }
}
