# CLAUDE.md — PlaySteps (Kids-app)

Compact map for future sessions. It references paths and contains no code. Read the long docs only when needed:
README.md (setup), REQUIREMENTS.md (spec, quality gates), docs/RELEASE.md (release runbook), PRIVACY.md, PLAY_LISTING.md.

## What it is
PlaySteps (`package:playsteps`, app id `com.nikkyzam.playsteps.app`) is a Flutter app that tracks baby and toddler development for parents of children aged 0–36 months. It offers one age-matched play activity per day, a CDC-aligned milestone checklist, WHO growth charts and a photo "baby book".
It is offline-first and must fully work with no account, no network and no app store. Supabase family sync is opt-in.
Pricing: a 14-day trial with everything unlocked, then a free tier plus Premium (lifetime purchase) or Premium Plus (yearly subscription).

## Tech stack
- **Flutter 3.44.7 stable.** This is the CI pin in `.github/workflows/ci.yml`; `pubspec.lock` needs Dart ≥3.12 and Flutter ≥3.44. The pubspec SDK constraint is `>=3.3.0 <4.0.0`, and the version is 1.0.0+3.
- **State:** provider ^6.1.2, using plain ChangeNotifier (no Riverpod or Bloc, no codegen).
- **Storage:** sqflite ^2.3.3, sqflite_common_ffi_web on web, and shared_preferences.
- **Optional backend:** supabase_flutter ^2.8.4 (email OTP auth plus sync). The receipt-verifier edge function is Deno TypeScript (Deno 2.9.6 in CI).
- **Purchases:** in_app_purchase ^3.2.0; RevenueCat is not used. **Notifications:** flutter_local_notifications ^17 plus timezone, local only.
- **Export and media:** pdf, printing, share_plus, file_picker, image_picker.
- **UI:** Material 3, the Nunito variable font, confetti and intl.
- **Dev:** flutter_test, flutter_lints ^4 (stock rules in `analysis_options.yaml`) and sqflite_common_ffi for an in-memory DB. mocktail is declared but unused.
- **Android:** compile and target SDK 36, AGP 8.9.1, Gradle 8.11.1, Kotlin 1.9.24, Java 11 with core-library desugaring (required, keep it on), Jetifier off.
- **iOS:** deployment target 13.0.

## Directory map
- `lib/main.dart`: bootstrap (plugin init, provider wiring). `lib/app.dart` holds the MaterialApp and `_RootRouter`.
- `lib/config/`: `supabase_config.dart` only. It reads the dart-define URL and anon key and exposes `isConfigured`.
- `lib/models/`: hand-written immutable models with `toMap`/`fromMap` and enums (SkillCategory, MilestoneDomain, …).
- `lib/data/`: static const content catalogs (`XData.all`), plus `database_helper.dart`, the only SQL/DB gateway.
- `lib/providers/`: 5 ChangeNotifiers (profile, activity, milestone, badge, auth).
- `lib/services/`: singleton and static services for sync, auth, purchases, receipts, entitlements, trial, notifications, backup, photos, PDF and WHO maths.
- `lib/screens/<feature>/`: one folder per feature (home, milestones, growth, memories, paywall, settings, …), with the main file named `*_screen.dart`.
- `lib/widgets/`: reusable cards, banners, dialogs, the parental gate, confetti and `local_image` (split into io/web versions).
- `lib/theme/`: `app_theme.dart`, the light-only M3 theme with color constants, shadows and gradients.
- `lib/utils/`: `clock.dart`, `calendar.dart`, `sync_timestamp.dart`, `number_words.dart`.
- `test/`: mirrors `lib/`. `test/support/` holds the harness and hand-written fakes. There are about 45 files and 580 tests.
- `supabase/`: `schema.sql` (applied by hand in the SQL editor, with RLS policies) and `functions/verify-purchase/` (Deno verifier plus tests).
- `android/`, `ios/`, `web/`: platform shells with no meaningful native code. `assets/fonts/`: Nunito. `docs/`: `RELEASE.md`.
- `.github/workflows/`: `ci.yml` (every push and PR) and `release.yml` (`v*.*.*` tags).
- `.claude/`: `settings.json` plus `hooks/session-start.sh`, which installs Flutter in cloud sessions.

## Commands
- **Dependencies:** `flutter pub get`. For iOS also run `cd ios && pod install`, and always open `ios/Runner.xcworkspace`.
- **Run:** `flutter run`. No defines are needed; without Supabase config the app runs fully offline.
- **Run with sync:** add `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`, after applying `supabase/schema.sql`.
- **Web:** run `dart run sqflite_common_ffi_web:setup` once (it fetches `web/sqlite3.wasm`, which is gitignored), then `flutter run -d chrome`.
- **Tests:** `flutter test` for all; `flutter test test/providers/activity_provider_test.dart` for one file; `flutter test --coverage` for coverage.
  CI also runs a DST pass: `TZ=America/New_York flutter test`.
- **Format and lint (CI gates):** `dart format --output=none --set-exit-if-changed .` and `flutter analyze` (infos fail it).
  Before pushing: `dart format . && flutter analyze && flutter test`.
- **Edge function:** `deno check supabase/functions/verify-purchase/*.ts`, `deno test --allow-env supabase/functions/verify-purchase/`, `deno fmt --check supabase/functions/verify-purchase/`.
- **Build:** `flutter build appbundle --release`, `flutter build apk --release`, `flutter build ios --release --no-codesign`, `flutter build web --release`.
  - Release builds need both Supabase defines. Without them, sync and server receipt checks are silently off.
  - Signing uses `android/key.properties` (gitignored); if it is absent, the build falls back to debug signing. To release, tag `vX.Y.Z` and see `docs/RELEASE.md`.

## Entry points and data flow
1. **Startup (`lib/main.dart`):**
   - Lock to portrait. Initialize Supabase only if `SupabaseConfig.isConfigured`.
   - Set the web DB factory, load SharedPreferences and open the DB (a DB error is swallowed only on web). Initialize `NotificationService`, then create `ActivityProvider(prefs)` and start the trial clock.
   - Wire the `PurchaseService` callbacks (`onEntitlement`/`onEntitlementRevoked` go to ActivityProvider; the verifier is `HttpReceiptVerifier`), then call `init()`. Finally `runApp(MultiProvider(...))`.
2. **Root routing (`lib/app.dart`):** `_RootRouter` loads profiles and shows a spinner, then `OnboardingScreen` (no profiles) or `HomeScreen`. It syncs on start and on app resume if the user is signed in. There is no auth gate.
3. **Home shell (`lib/screens/home/home_screen.dart`):**
   - An IndexedStack plus NavigationBar with two tabs: Today's Play and Milestones.
   - It loads the per-profile providers on init and when the profile changes. AppBar actions push History, Badges and Settings.
   - All navigation is `Navigator.push(MaterialPageRoute)`. There are no named routes and no go_router.
4. **Writes:** widget → provider method (`context.read`) → awaited `DatabaseHelper.instance.*` (which stamps `updated_at`) → in-memory list is mutated → `notifyListeners` → `context.watch`/`Consumer` rebuild. Providers coordinate in the UI, not through DI; for example `lib/widgets/activity_card.dart` toggles a completion and then calls `BadgeProvider.checkAndUnlock`.
5. **Content:** catalogs are read synchronously from `XData.all`. Today's activity is a deterministic pick by day of year from the child's age band (`lib/data/activities_data.dart`).
6. **Sync:** `SyncService.syncAll()` pushes and then pulls rows by `updated_at` since the `last_sync_at` pref. Last write wins, and it only upserts (deletes are never propagated). Providers are not reloaded after a sync.
7. **Purchases:** store `purchaseStream` → `PurchaseService` → `ReceiptVerifier` (edge function) → `ActivityProvider.grantEntitlement`/`revokeEntitlement` → prefs plus `EntitlementLedger`.

## Conventions
- **Files and classes:** files are snake_case with one public class or widget per file; private `_Helper` widgets and `_buildX` methods live in the same file.
  Suffixes: `*_screen`, `*_sheet`, `*_card`, `*_banner`, `*_dialog`, `*_provider`, `*_service`, `*_data`. Dialogs and sheets expose a static `show(...)`.
- **Singletons and platform splits:** singletons use a private `._()` constructor plus `static instance`, and tests swap them through `@visibleForTesting` seams. Stateless services are static classes.
  Platform splits use conditional imports: `*_io.dart`/`*_web.dart`, and `database_platform_web`/`_stub`.
- **Models:** hand-written, const constructor, final fields, `toMap`/`fromMap` with snake_case columns and ISO-8601 dates. `copyWith` uses explicit `clearX` flags. There is no codegen and no `==`/`hashCode` (that is why `Map.identity` is used where needed).
- **Time:** always use `Clock.now()`/`Clock.today()` (`lib/utils/clock.dart`), never `DateTime.now()`. Count days with calendar components or `calendarDaysBetween`, never `Duration(days:)`, because of DST.
  Write `updated_at` via `SyncTimestamp` (UTC).
- **Age maths:** always use the `ChildProfile` content-age getters, which apply preterm correction via `effectiveDueDate`. Never compute age from the raw DOB or `dueDate`.
- **Database:** all SQL lives in `lib/data/database_helper.dart`. A schema change means: bump `version`, add an `if (oldVersion < N)` block in `_onUpgrade`, update `_onCreate`, and extend `test/data/migration_test.dart`.
- **Errors:** there are no Result types. Services throw typed exceptions (`SyncUnavailableException`, `PurchaseUnavailableException`, `PhotoStorageException`), and callers map them to UI state.
  Services that take a BuildContext (backup, photo memory) catch errors themselves and show a SnackBar. `ReceiptVerifier` never throws; failures map to `unavailable`. Corrupt prefs are handled with `tryParse` and treated as null.
- **Logging and privacy:** `debugPrint` only, and rarely (just `main.dart`); there is no logger package. No analytics, ads, crash reporting or social SDKs, and no network calls outside opt-in sync or receipt checks.
- **UI:**
  - Use `context.watch`/`Consumer` in `build` and `context.read` in callbacks. Guard async gaps with `mounted`/`context.mounted`. Use `withValues(alpha:)`, not `withOpacity`.
  - Use `AppTheme` constants and `Theme.of(context).textTheme`; the existing raw `fontSize`/`Color(0x…)` literals are debt, so don't copy them.
  - Use `Expanded`/`Flexible`, not `Spacer`. Every screen must fit 320×568 at 1.3 text scale (`test/screens/small_screen_layout_test.dart`).
- **Copy and tone:** strings are hardcoded English; there is no l10n. Never tell a parent the child is "behind", and never grade a growth measurement; tests enforce banned words.
  Use the parental gate (`lib/widgets/parental_gate_dialog.dart`) in front of Settings and exports.
- **Comments:** long "why" doc comments that record past bugs are house style. Keep and extend them.
- **Tests:** all fakes are hand-written, with no mocktail or mockito. Use `test/support/harness.dart`: in-memory FFI DB, clock frozen at 2026-05-20 10:00, seeded child "Emma", and pump helpers.
  DB reads inside `testWidgets` need `Harness.realAsync` or `settleAsync`, or they hang. No golden tests, on purpose.
- **Git:** the default branch is `development`; name branches `feature/…` or `fix/…`.

## Gotchas (look wrong, mostly intentional)
- **Cloud-session SDK mismatch:** `.claude/hooks/session-start.sh` installs Flutter **3.24.0**, but the code needs 3.44.x (for example `Color.withValues`). As a result `flutter analyze` and `flutter test` won't compile in-session.
- **Lockfile rewrite:** the hook's `pub get` also rewrites `pubspec.lock` with downgraded packages. Never commit that diff; revert it with `git checkout -- pubspec.lock`.
- **Premium includes the trial:** `isPremium` and `isPremiumPlus` are TRUE during the trial. Use `hasPurchasedPremium*` for real purchase state, which is what the paywall screens do on purpose.
- **Revocation is strict:** only an explicit store "invalid" verdict revokes. An offline or unreachable verifier still grants. On its own failures the edge function returns 503, never `valid:false`. With no backend configured, nothing is ever revoked.
- **Delete-all:** it keeps the entitlement and receipt prefs but clears `first_launch_at`, so the trial restarts. A reinstall also gives a fresh trial.
- **Not synced:** photos are never synced (privacy). `activity_skips` are also not in sync.
- **Unreviewed content ships:** `ActivitiesData.all` includes AI-drafted, unreviewed items (`ActivitiesDraftData.pendingReview`); see the header of `lib/data/activities_draft_data.dart`.
- **Age bands:** bands are in weeks, min inclusive and max exclusive. Children aged 156 weeks or more get no daily activity (the app covers 0–36 months).
- **Preterm correction:** prematurity is capped at 119 days, and correction stops at 24 months (`lib/models/child_profile.dart`).
- **Generated file:** `lib/data/who_growth_standards_data.dart` is GENERATED; don't hand-edit it.
- **Foreign-key cascades:** `PRAGMA foreign_keys = ON`, so deleting `child_profiles` cascades to growth and photo rows. Backup restore deletes profiles first (`lib/services/backup_service.dart`).
- **Premium Plus gating:** Growth, Leaps, Plan and Digest are gated only by the home-screen tiles (`_buildPremiumPlusRow`), not inside the screens.
- **Prices:** always come from the store via `PurchaseService.priceFor`, never hardcoded. Product IDs are in `lib/services/purchase_service.dart`.
- **Callback order:** the `PurchaseService` callbacks must be assigned before `init()` in `main.dart`.
- **Docs drift:** README says targetSdk 34 (it is really 36); `docs/RELEASE.md` has an old version; the PLAY_LISTING "known gaps" and the REQUIREMENTS test count are stale. Trust the code and `ci.yml`.

## Where to look for X
- **Bootstrap and init order:** `lib/main.dart`. **Root routing, sync on resume:** `lib/app.dart`. **Dart-defines:** `lib/config/supabase_config.dart`.
- **DB schema, migrations, all SQL:** `lib/data/database_helper.dart` (tests in `test/data/migration_test.dart`).
- **Activity catalog and daily pick:** `lib/data/activities_data.dart`, `lib/data/activities_draft_data.dart`.
- **Milestones, red flags, "what to look for":** `lib/data/milestones_data.dart`, `red_flags_data.dart`, `milestone_context_data.dart`.
- **Leaps, tips, badges:** `lib/data/developmental_leaps_data.dart`, `tips_data.dart`, `badges_data.dart`. Badge thresholds are in `lib/providers/badge_provider.dart`.
- **Age and prematurity maths:** `lib/models/child_profile.dart`.
- **Streaks, completions, dismissals, premium and trial flags:** `lib/providers/activity_provider.dart`.
- **Auth (email OTP) and families:** `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`, `lib/screens/auth/`, `lib/screens/settings/family_sharing_screen.dart`.
- **Sync:** `lib/services/sync_service.dart`, `sync_backend.dart`, `lib/utils/sync_timestamp.dart`. Server tables and RLS are in `supabase/schema.sql`.
- **Purchases and entitlement:** `lib/services/purchase_service.dart`, `receipt_verifier.dart`, `entitlement_ledger.dart`, `trial_service.dart`. The UI is in `lib/screens/paywall/`.
- **Server receipt check:** `supabase/functions/verify-purchase/verify.ts`, which lists its required secrets at the top; `index.ts` is wiring only.
- **Growth and WHO percentiles:** `lib/services/who_growth_standards.dart`, `lib/data/who_growth_standards_data.dart`, `lib/screens/growth/`.
- **Photos and baby book:** `lib/services/photo_memory_service.dart`, `photo_storage*.dart`, `baby_book.dart`, `lib/screens/memories/`.
- **Notifications:** `lib/services/notification_service.dart`. **Backup, PDF, delete-all:** `lib/services/backup_service.dart`, `pdf_export_service.dart`, `data_reset_service.dart`.
- **Insights (On Track, Doctor Prep), plan, digest:** `lib/screens/insights/`, `lib/screens/plan/`, `lib/screens/digest/`.
- **Theme and colors:** `lib/theme/app_theme.dart`. **Time and DST helpers:** `lib/utils/clock.dart`, `lib/utils/calendar.dart`.
- **Test harness and fakes:** `test/support/harness.dart`, `fake_auth.dart`, `parental_gate.dart`.
- **CI and release:** `.github/workflows/ci.yml`, `release.yml`, `docs/RELEASE.md`. **Android SDKs and signing:** `android/app/build.gradle`.
- **Product, privacy and tone rules:** `REQUIREMENTS.md`, `PRIVACY.md`.
