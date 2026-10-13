# Adding an app to the family

All apps share one codebase and one engine. Each app is a **flavor**: its own
name, store listing, product IDs, signing key and Supabase project.

## 1. Code (3 edits)

1. `lib/config/app_flavor.dart` — add an `AppFlavor` constant (id, display
   name, store product IDs) and append it to `AppFlavor.all`.
2. `android/app/build.gradle` — add a block under `productFlavors`:
   ```groovy
   toddlersteps {
       dimension "app"
       applicationId "com.nikkyzam.toddlersteps.app"
       resValue "string", "app_name", "ToddlerSteps"
   }
   ```
   Convention: `applicationId` is `com.nikkyzam.<id>.app`; the release
   workflow relies on it unless the `ANDROID_PACKAGE_NAME` environment
   variable overrides it.
3. `.github/workflows/ci.yml` — add the id to the `build-android` matrix.

Per-app content (activities, milestones, theme) is a later step: gate it on
`AppFlavor.current` where the apps diverge.

## 2. Backend

Create a separate Supabase project per app (own database, auth users and
`verify-purchase` function). Never share one project between apps: users,
RLS policies and purchase receipts would mix.

## 3. Store + CI setup (once per app)

- Create the Play Console / App Store Connect record and the products named in
  the flavor.
- Generate an upload keystore for this app (see `RELEASE.md` step 1).
- In GitHub → Settings → Environments, create an environment named exactly
  the app id and add these secrets: `ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`,
  `PLAY_STORE_SERVICE_ACCOUNT_JSON`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

## 4. Build and release

```bash
tool/build_app.sh toddlersteps run              # local run
tool/build_app.sh toddlersteps appbundle        # local release bundle
git tag toddlersteps-v1.0.0 && git push --tags  # CI release for that app only
```

Always build through `tool/build_app.sh` (or pass both `--flavor <id>` and
`--dart-define=APP_FLAVOR=<id>`); plain `flutter run` no longer works on Android
because there is no default flavor.

## Known gap

iOS is not flavored yet: it still builds a single `Runner` target with the
PlaySteps bundle ID. Per-app iOS needs xcconfig/schemes created in Xcode on a
Mac; do that before shipping a second app on iOS.
