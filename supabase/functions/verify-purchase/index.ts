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
// Deploy:
//   supabase functions deploy verify-purchase
//   supabase secrets set \
//     ANDROID_PACKAGE_NAME=com.nikkyzam.playsteps.app \
//     GOOGLE_SERVICE_ACCOUNT_EMAIL=...@...iam.gserviceaccount.com \
//     GOOGLE_SERVICE_ACCOUNT_KEY="$(cat key.pem)" \
//     APPLE_SHARED_SECRET=...
//
// See README.md → "Add server-side receipt validation" for how to obtain each.

interface VerifyRequest {
  platform: "android" | "ios";
  productId: string;
  /// Android: the purchase token. iOS: the base64 app receipt.
  token: string;
  /// Android only: whether this product is a subscription.
  subscription?: boolean;
}

interface VerifyResponse {
  valid: boolean;
  /// Present when a subscription's expiry is known, so the client can stop
  /// asking until then. Milliseconds since epoch.
  expiresAt?: number;
  /// Why a receipt was rejected. Never shown to a parent verbatim — the app
  /// says "that purchase could not be verified" — but it is what makes a
  /// support conversation possible.
  reason?: string;
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

// ─── Google Play ─────────────────────────────────────────────────────────────

/// Cached across invocations because an edge function instance is reused, and
/// minting a token costs a round trip and an RSA signature. Refreshed a minute
/// early so a token cannot expire mid-request.
let googleToken: { value: string; expiresAt: number } | null = null;

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

function base64Url(bytes: Uint8Array | string): string {
  const binary = typeof bytes === "string"
    ? bytes
    : String.fromCharCode(...bytes);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

/// Mints a Google OAuth access token from the service account key, by signing
/// a JWT assertion with Web Crypto. Done by hand rather than with a library so
/// this function has no third-party dependency in the path that decides
/// whether someone paid.
async function getGoogleAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (googleToken && googleToken.expiresAt > now + 60) return googleToken.value;

  const email = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_EMAIL");
  const key = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_KEY");
  if (!email || !key) throw new Error("Google service account is not configured");

  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
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
    throw new Error(`Google token exchange failed: ${await response.text()}`);
  }

  const body = await response.json();
  googleToken = {
    value: body.access_token,
    expiresAt: now + (body.expires_in ?? 3600),
  };
  return googleToken.value;
}

async function verifyAndroid(request: VerifyRequest): Promise<VerifyResponse> {
  const pkg = Deno.env.get("ANDROID_PACKAGE_NAME");
  if (!pkg) return { valid: false, reason: "android package not configured" };

  const accessToken = await getGoogleAccessToken();
  const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}`;
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

  // Google answers 404 for a token it has never issued — which is exactly what
  // a forged one looks like, and is a definite "no" rather than an outage.
  if (response.status === 404) {
    return { valid: false, reason: "unknown purchase token" };
  }
  if (!response.ok) {
    throw new Error(
      `Play API ${response.status}: ${await response.text()}`,
    );
  }

  const body = await response.json();

  if (request.subscription) {
    // subscriptionsv2: ACTIVE or IN_GRACE_PERIOD still entitle the parent.
    const state = body.subscriptionState;
    const entitled = state === "SUBSCRIPTION_STATE_ACTIVE" ||
      state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
    const expiry = body.lineItems?.[0]?.expiryTime;
    return {
      valid: entitled,
      expiresAt: expiry ? Date.parse(expiry) : undefined,
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

const APPLE_PRODUCTION = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt";

async function postAppleReceipt(url: string, receipt: string, secret: string) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receipt,
      password: secret,
      "exclude-old-transactions": true,
    }),
  });
  if (!response.ok) {
    throw new Error(`App Store ${response.status}: ${await response.text()}`);
  }
  return await response.json();
}

async function verifyIos(request: VerifyRequest): Promise<VerifyResponse> {
  const secret = Deno.env.get("APPLE_SHARED_SECRET");
  if (!secret) return { valid: false, reason: "apple secret not configured" };

  // Always production first. Apple's 21007 means "this is a sandbox receipt
  // sent to production", and it is the documented way to tell the two apart —
  // a build cannot know which store its receipt came from.
  let body = await postAppleReceipt(APPLE_PRODUCTION, request.token, secret);
  if (body.status === 21007) {
    body = await postAppleReceipt(APPLE_SANDBOX, request.token, secret);
  }

  if (body.status !== 0) {
    return { valid: false, reason: `apple status ${body.status}` };
  }

  const purchases = [
    ...(body.latest_receipt_info ?? []),
    ...(body.receipt?.in_app ?? []),
  ];
  const matching = purchases.filter(
    (p: Record<string, string>) => p.product_id === request.productId,
  );
  if (matching.length === 0) {
    return { valid: false, reason: "product not present in receipt" };
  }

  // A refunded purchase carries a cancellation date; it is no longer valid
  // however recent it is.
  const live = matching.filter(
    (p: Record<string, string>) => !p.cancellation_date_ms,
  );
  if (live.length === 0) {
    return { valid: false, reason: "purchase was refunded" };
  }

  // A subscription entry carries an expiry; a non-consumable does not, and is
  // owned forever.
  const expiries = live
    .map((p: Record<string, string>) => Number(p.expires_date_ms))
    .filter((ms: number) => Number.isFinite(ms) && ms > 0);
  if (expiries.length === 0) return { valid: true };

  const latest = Math.max(...expiries);
  return {
    valid: latest > Date.now(),
    expiresAt: latest,
    reason: latest > Date.now() ? undefined : "subscription expired",
  };
}

// ─── Entry point ─────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
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
    // A 5xx, not a `valid: false`. The difference matters: the app treats a
    // rejection as final and revokes, but treats an outage as "ask again
    // later" and leaves the parent's purchase working. Collapsing the two
    // would revoke a real purchase every time this function had a bad day.
    console.error("verification failed", error);
    return json(
      { valid: false, reason: "verification unavailable" },
      503,
    );
  }
});
