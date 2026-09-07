# Release runbook

Everything in this file is a step only the account owner can take. The code is
finished and CI proves it builds; what is left is credentials, store records
and a keystore that must never exist on a build machine.

Work through it in order. Steps 1–3 are one-time setup; step 5 is what you
repeat for every release after that.

| App identity | Value |
|---|---|
| Android application ID | `com.nikkyzam.playsteps.app` |
| iOS bundle ID | `com.nikkyzam.playsteps.app` |
| Version | `pubspec.yaml` → `version: 1.0.0+1` |
| Premium product ID | `playsteps_premium_lifetime` (non-consumable) |
| Premium Plus product ID | `playsteps_premium_plus_yearly` (yearly subscription) |

---

## 1. Create the Android upload keystore

**Do this on your own machine, not in CI and not in a cloud session.** The
keystore is the only proof that a future update comes from you. Google cannot
reissue it: lose it and the listing can never be updated again, only replaced
under a new package name, and every installed user has to reinstall by hand.

```bash
keytool -genkey -v \
  -keystore ~/playsteps-upload.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Then:

- Back the `.jks` file up somewhere that is not this repository and not the
  same disk — a password manager attachment or an encrypted backup.
- Record the store password, key password and alias in the same place.
- Never commit it. `android/key.properties` and `android/app/release.keystore`
  are written by CI at build time and deleted in the same job.

Base64-encode it for the GitHub secret:

```bash
base64 -w0 ~/playsteps-upload.jks > ~/playsteps-upload.jks.b64   # Linux
base64 -i ~/playsteps-upload.jks -o ~/playsteps-upload.jks.b64   # macOS
```

## 2. Add the GitHub Actions secrets

**Settings → Secrets and variables → Actions → New repository secret.**

| Secret | Required | What it is |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | yes | The base64 from step 1. Release fails loudly without it. |
| `ANDROID_KEY_ALIAS` | yes | `upload`, unless you chose another. |
| `ANDROID_KEY_PASSWORD` | yes | Key password from step 1. |
| `ANDROID_STORE_PASSWORD` | yes | Store password from step 1. |
| `SUPABASE_URL` | see below | Project URL, e.g. `https://abcd.supabase.co`. |
| `SUPABASE_ANON_KEY` | see below | The project's anon/public key. |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | optional | Enables the automatic internal-track upload in step 5. |

The two Supabase values are compiled into the binary with `--dart-define`. A
build without them still succeeds — that degradation is deliberate — but it
ships with family sharing off and **receipt verification falling back to the
local check**, which is defeatable on a rooted device. Do not release without
them.

## 3. Deploy the receipt verifier

The function is written and tested (`supabase/functions/verify-purchase/`, 36
Deno tests in CI) but does nothing until it is deployed and given credentials.

```bash
supabase functions deploy verify-purchase

supabase secrets set \
  ANDROID_PACKAGE_NAME=com.nikkyzam.playsteps.app \
  GOOGLE_SERVICE_ACCOUNT_EMAIL=<service-account>@<project>.iam.gserviceaccount.com \
  GOOGLE_SERVICE_ACCOUNT_KEY="$(cat google-service-account-private-key.pem)" \
  APPLE_BUNDLE_ID=com.nikkyzam.playsteps.app \
  APPLE_ISSUER_ID=<App Store Connect issuer id> \
  APPLE_KEY_ID=<App Store Connect key id> \
  APPLE_PRIVATE_KEY="$(cat AuthKey_XXXXXXXX.p8)"
```

Where those come from:

- **Google**: Play Console → Setup → API access → link a Google Cloud project,
  create a service account, grant it *View financial data* and *Manage orders
  and subscriptions*, then download a JSON key. The email and the
  `private_key` field are the two values above.
- **Apple**: App Store Connect → Users and Access → Integrations → In-App
  Purchase keys. Download the `.p8` **once** — it cannot be downloaded again.
  The issuer ID is on the same page.

Set the secrets **before or at the same time as** the deploy. A deployed
function with a secret missing answers 503 ("could not ask"), which the client
correctly treats as an outage and does not act on — but leaving it in that
state means nothing is actually being verified.

Sanity-check it after deploying:

```bash
curl -i -X POST "$SUPABASE_URL/functions/v1/verify-purchase" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"platform":"android","productId":"playsteps_premium_lifetime","token":"not-a-real-token"}'
```

A **400** (malformed token — Play's own verdict) means the whole path works. A
**503** means a secret is missing or the store could not be reached; the
response body says which.

## 4. Create the store records

### Google Play

1. Play Console → Create app. Package name `com.nikkyzam.playsteps.app`, free
   app.
2. **Upload the first AAB by hand.** The automated upload in step 5 can only
   push to a track that already has a release; there is no way around this
   first manual one.
   ```bash
   flutter build appbundle --release \
     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   # build/app/outputs/bundle/release/app-release.aab
   ```
   Testing → Internal testing → Create new release → upload.
3. Add internal testers (an email list; they accept an opt-in link).
4. Monetise → Products: create both product IDs from the table at the top,
   exactly as spelled. A mismatch shows the parent "Store unavailable".
5. Complete the content rating questionnaire, data safety form, and store
   listing. None of these block internal testing; all of them block
   production.

### App Store

1. App Store Connect → create the app record with bundle ID
   `com.nikkyzam.playsteps.app`.
2. In-App Purchases: create both products with the IDs from the table.
3. App Privacy: PlaySteps collects no data — *Data Not Collected*.
4. Archive and upload from Xcode (`Product → Archive` → Distribute). CI builds
   iOS unsigned on every tag to catch breakage, but the upload needs your
   signing certificates and is done from a Mac.

## 5. Cut a release

Once steps 1–4 are done, releasing is a tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

`.github/workflows/release.yml` then:

1. builds a signed AAB and APK with the Supabase defines,
2. attaches both to a GitHub Release,
3. uploads the AAB to the Play **internal** track — only if
   `PLAY_STORE_SERVICE_ACCOUNT_JSON` is set; otherwise it skips silently and
   you upload the artifact by hand.

Bump `version:` in `pubspec.yaml` before each tag. The build number (the part
after `+`) must increase for every upload Play or Apple accepts, even a
re-upload of the same version name.

## 6. Smoke-test the internal build

On a real device, signed in as an internal tester. The simulator and the web
build cannot do purchases at all.

- [ ] Fresh install, onboarding completes, a child profile saves.
- [ ] Today's activity appears; completing it records a streak.
- [ ] The trial banner counts down and the paywall opens from it.
- [ ] The paywall lists both products **with prices from the store** — prices
      are read at runtime, so placeholder text means the product IDs do not
      match.
- [ ] Buy Premium with a test account: the entitlement unlocks immediately.
- [ ] Force-quit and relaunch: still unlocked (the receipt re-verifies against
      the deployed function).
- [ ] Turn airplane mode on and relaunch: still unlocked. An unreachable
      server must never revoke a purchase.
- [ ] Reinstall the app and use *Restore purchases*: the entitlement comes
      back.
- [ ] Refund the test purchase in the Play Console, then relaunch after the
      weekly re-check window: the entitlement is revoked. This is the one path
      that proves server-side validation is really on.
- [ ] Add a photo memory, then Settings → Delete all data: photos and rows are
      gone and the app still launches.

## If something goes wrong

| Symptom | Cause |
|---|---|
| Release job fails at "Decode release keystore" | `ANDROID_KEYSTORE_BASE64` is unset or was encoded with line wrapping. Re-encode with `base64 -w0`. |
| Play upload step never runs | `PLAY_STORE_SERVICE_ACCOUNT_JSON` is unset — by design. |
| Play rejects the upload: "track has no releases" | Step 4.2 was skipped; the first AAB must be uploaded manually. |
| Paywall says "Store unavailable" | Product IDs do not match the console, or the tester account is not on the internal track. |
| Purchases work but nothing is verified server-side | `SUPABASE_URL`/`SUPABASE_ANON_KEY` were missing at build time, so the app fell back to the local check. Rebuild. |
| Verifier returns 503 for everything | A `supabase secrets set` value is missing or malformed — most often a PEM whose newlines were lost. |
