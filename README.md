# PlaySteps

## Project Overview

PlaySteps is a baby and toddler development tracker for parents of children from birth through 36 months. It delivers daily age-appropriate play activities and a CDC-aligned milestone ledger — entirely on-device, with no accounts, no cloud sync, and no subscription required for the core experience. The freemium model offers full access for birth–4 weeks at no cost; a single one-time purchase of $4.99 unlocks all content through 36 months. Because all data lives in a local SQLite database, parents retain full ownership of their child's developmental records.

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | ≥ 3.3.0 | [Install guide](https://docs.flutter.dev/get-started/install) |
| Dart SDK | ≥ 3.3.0 | Bundled with Flutter |
| Xcode | ≥ 15 | macOS only, required for iOS builds |
| Android Studio / Android SDK | Latest stable | Include NDK via SDK Manager |
| CocoaPods | Latest | iOS dependency management |
| Ruby | ≥ 2.7 | Required for CocoaPods and Fastlane |

Verify your Flutter environment before starting:

```bash
flutter doctor -v
```

All items should show a checkmark. Address any reported issues before proceeding.

---

## Clone & Setup

```bash
git clone <repo-url>
cd Kids-app
flutter pub get
cd ios && pod install && cd ..
```

After `pod install` completes, open the iOS project only via `ios/Runner.xcworkspace` — never via `ios/Runner.xcodeproj`.

---

## Platform-Specific Configuration

### Android

**`android/app/build.gradle`** — confirm the following SDK versions:

```groovy
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

**In-App Purchase** — the `in_app_purchase` plugin pulls in `com.android.billingclient` automatically. No manual dependency entry is required.

**Scheduled Notifications** — add the `SCHEDULE_EXACT_ALARM` permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

**File Picker** — add storage permissions to `AndroidManifest.xml`:

```xml
<!-- Android ≤ 12 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<!-- If full external storage access is needed (rare) -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

**Release Signing** — generate a keystore and configure signing:

```bash
keytool -genkey -v \
  -keystore android/app/release.keystore \
  -alias playsteps \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Create `android/key.properties` (do not commit this file):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=playsteps
storeFile=release.keystore
```

Reference `key.properties` in `android/app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

Add `android/key.properties` and `android/app/release.keystore` to `.gitignore`.

---

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode (not the `.xcodeproj`).
2. Select the **Runner** target → **General** tab:
   - Set **Bundle Identifier** to your reverse-domain ID (e.g., `com.yourcompany.playsteps`).
   - Set **Deployment Target** to **iOS 12.0**.
3. Under **Signing & Capabilities**, select your development team and enable automatic signing.
4. Add the following capabilities via **+ Capability**:
   - **Push Notifications**
   - **In-App Purchase**
5. Add these entries to `ios/Runner/Info.plist`:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>PlaySteps sends daily activity reminders to help you stay on track.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PlaySteps can read photos for backup and restore.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>PlaySteps can save exported PDFs to your photo library.</string>
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

---

## Running Locally

```bash
# List available devices and simulators
flutter devices

# Run on a connected device or running simulator
flutter run

# Run in release mode (no hot reload, closer to production performance)
flutter run --release
```

During a debug session, hot reload is available:
- Press `r` in the terminal to hot reload.
- Press `R` to hot restart.
- In VS Code or Android Studio, save any file to trigger automatic hot reload.

---

## Running Tests

```bash
# All unit and widget tests
flutter test

# Specific test file
flutter test test/providers/activity_provider_test.dart

# With coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html   # macOS
```

The test suite uses `sqflite_common_ffi` to run SQLite queries against an in-memory database without a connected device, and `mocktail` for mock objects. No device or emulator is required to run the tests.

---

## Building Release Artifacts

### Android APK / AAB

```bash
# Signed APK — suitable for direct installation / QA testing
flutter build apk --release

# App Bundle — required format for Google Play Store submission
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA

```bash
# Build the iOS app without code signing (signing happens in Xcode)
flutter build ios --release --no-codesign
```

After the build completes, archive and export from Xcode:

1. **Product → Archive**
2. In the Xcode Organizer, select the archive and click **Distribute App**.
3. Choose **App Store Connect** and follow the export wizard.

---

## Deploying to Google Play Store

1. **Create a Google Play Developer account** at [play.google.com/console](https://play.google.com/console) ($25 one-time registration fee).

2. **Create a new app** in the Play Console:
   - Package name: `com.yourcompany.playsteps`
   - Default language and app type (App / Free).

3. **Set up an internal test track** first to validate the build end-to-end before promoting to production.

4. **Upload the `.aab`** to the internal test release track.

5. **Complete the store listing**:
   - Title (≤ 30 characters)
   - Short description (≤ 80 characters)
   - Full description (≤ 4000 characters)
   - Screenshots: at least 2 phone screenshots; 7-inch tablet screenshots recommended
   - Feature graphic: 1024 × 500 px PNG or JPG

6. **Set content rating** via the rating questionnaire. PlaySteps should qualify as **Everyone**.

7. **Configure In-App Products**:
   - Navigate to **Monetize → Products → In-app products**.
   - Add a one-time (Managed) product:
     - Product ID: `premium_upgrade`
     - Price: $4.99
     - Status: Active

8. **Submit for review**. New apps typically take 1–3 business days. Monitor the Play Console for policy violations or metadata rejections.

9. **Optional CI/CD**: [Fastlane Supply](https://docs.fastlane.tools/actions/supply/) can automate AAB uploads and metadata updates from your CI pipeline.

---

## Deploying to Apple App Store

1. **Enroll in the Apple Developer Program** at [developer.apple.com](https://developer.apple.com) ($99/year).

2. **Create an App ID** in Certificates, Identifiers & Profiles:
   - Enable the **In-App Purchases** and **Push Notifications** capabilities.

3. **Create the app record** in [App Store Connect](https://appstoreconnect.apple.com):
   - Platform: iOS
   - Bundle ID: matches the App ID created above
   - SKU: any unique internal identifier

4. **In Xcode**, confirm:
   - Team and bundle ID match your Developer account.
   - Signing certificates and provisioning profiles are valid.

5. **Archive the app**: `Product → Archive`.

6. **Upload to App Store Connect** via the Xcode Organizer (**Distribute App → App Store Connect → Upload**), or use the command-line tool:

   ```bash
   xcrun altool --upload-app \
     --type ios \
     --file build/ios/ipa/PlaySteps.ipa \
     --apiKey <key-id> \
     --apiIssuer <issuer-id>
   ```

7. **Configure In-App Purchase** in App Store Connect:
   - Navigate to your app → **In-App Purchases → Manage**.
   - Add a **Non-Consumable** IAP:
     - Reference Name: Premium Upgrade
     - Product ID: `premium_upgrade`
     - Price: $4.99 (Tier 5)
   - Add localized display name and description, then submit for review alongside the app or separately.

8. **Set App Privacy details**:
   - PlaySteps collects no data — select **Data Not Collected** on the App Privacy page.

9. **Upload screenshots**:
   - Required: 6.5-inch iPhone (1284 × 2778 px) and 5.5-inch iPhone (1242 × 2208 px).
   - Optional but recommended: 12.9-inch iPad Pro.

10. **Submit for review**. First-time submissions typically take 24–48 hours. Rejections are common for IAP issues — ensure the premium paywall is functional with a Sandbox Apple ID before submitting.

11. **Optional CI/CD**: [Fastlane Deliver](https://docs.fastlane.tools/actions/deliver/) automates metadata uploads, screenshot management, and build submission.

---

## Continuous Integration & Deployment

Two GitHub Actions workflows live in `.github/workflows/`:

### `ci.yml` — on every push & pull request

Runs on `ubuntu-latest` against `main`/`master`:

1. `flutter pub get`
2. `dart format --set-exit-if-changed` — fails the build on unformatted code
3. `flutter analyze`
4. `flutter test --coverage` (uploads `coverage/lcov.info` as an artifact)

Run the same checks locally before pushing:

```bash
dart format . && flutter analyze && flutter test
```

### `release.yml` — on version tags (`v*.*.*`)

Cut a release by tagging a commit:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow then:

- **Android** — decodes the release keystore from secrets, generates `android/key.properties`, and builds a signed `.aab` and `.apk`. If `PLAY_STORE_SERVICE_ACCOUNT_JSON` is configured, it also uploads the bundle to the Play Store **internal** track.
- **iOS** — compiles `flutter build ios --release --no-codesign` to catch build breakage. Full App Store upload requires signing certificates/provisioning (wire up Fastlane Match + `deliver` in this job when ready).
- **GitHub Release** — attaches the `.aab` and `.apk` to an auto-generated GitHub Release for the tag.

The signed release build is driven by `android/key.properties`: when that file is present (as it is in CI), Gradle signs with the release keystore; otherwise it falls back to debug signing so local `flutter run --release` still works.

---

## Environment Variables / Secrets

These variables are required for CI/CD pipelines (GitHub Actions, Bitrise, etc.). Store them as encrypted secrets in your CI provider — never commit them to the repository.

| Variable | Purpose |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded release keystore file |
| `ANDROID_KEY_ALIAS` | Keystore key alias (e.g., `playsteps`) |
| `ANDROID_KEY_PASSWORD` | Password for the key entry |
| `ANDROID_STORE_PASSWORD` | Password for the keystore file |
| `APPLE_ID` | Apple ID email used for App Store Connect |
| `APP_STORE_CONNECT_API_KEY` | JSON key file for Fastlane App Store Connect API authentication |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google Play service-account JSON — enables automated AAB upload to the internal track (optional; the release job builds artifacts without it) |

To encode the keystore for CI:

```bash
base64 -i android/app/release.keystore | pbcopy   # macOS — copies to clipboard
```

---

## Troubleshooting

**`CocoaPods not found` when running `pod install`**

```bash
sudo gem install cocoapods
pod setup
```

If you have Ruby version conflicts, consider using `rbenv` or `rvm` to manage Ruby versions.

---

**`flutter_local_notifications` build error on Android**

Ensure `compileSdkVersion` is set to at least 34 in `android/app/build.gradle`. The plugin requires API 34 symbols at compile time even if `minSdkVersion` is lower.

---

**`file_picker` crash on Android 13+**

Android 13 (API 33) replaced `READ_EXTERNAL_STORAGE` with granular media permissions. Add the following to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

---

**`Bad CPU type in executable` error on Apple Silicon (M1/M2) Mac**

Some older CocoaPods versions produce x86_64 binaries that fail on arm64. Run pod install under Rosetta:

```bash
arch -x86_64 pod install
```

Alternatively, ensure all pods support arm64 by adding `EXCLUDED_ARCHS` to your Podfile or upgrading to a newer CocoaPods version.

---

**In-app purchase not working during testing**

- On iOS, sandbox purchases require a Sandbox Apple ID. Create one in App Store Connect under **Users and Access → Sandbox Testers**, then sign into it under **Settings → App Store** on the test device (not the main Apple ID settings).
- On Android, add tester email addresses to the internal test track before installing the build.

---

## Project Structure

```
lib/
├── main.dart                  # App entry point; initializes providers and timezone
├── app.dart                   # Root MaterialApp widget and routing
│
├── data/                      # Static data and database layer
│   ├── database_helper.dart   # SQLite schema, migrations, and query helpers (sqflite)
│   ├── activities_data.dart   # Hardcoded age-banded activity definitions
│   ├── milestones_data.dart   # CDC-aligned milestone definitions by domain
│   ├── badges_data.dart       # Achievement badge definitions and unlock criteria
│   └── tips_data.dart         # Daily parenting tips by age range
│
├── models/                    # Plain Dart data classes
│   ├── child_profile.dart
│   ├── activity.dart
│   ├── activity_completion.dart
│   ├── milestone.dart
│   ├── milestone_achievement.dart
│   └── badge_definition.dart
│
├── providers/                 # State management (provider package)
│   ├── profile_provider.dart  # Active child profile; premium status
│   ├── activity_provider.dart # Daily activity selection, completion, streaks
│   ├── milestone_provider.dart# Milestone ledger and achievement recording
│   └── badge_provider.dart    # Badge unlock logic and persistence
│
├── screens/                   # Full-page UI screens
│   ├── home/                  # Daily activity feed and streak banner
│   ├── milestones/            # Milestone checklist by developmental domain
│   ├── history/               # Past activity completions calendar/list
│   ├── library/               # Browsable activity library with filters
│   ├── badges/                # Earned and locked achievement badges
│   ├── onboarding/            # First-launch child profile creation
│   ├── paywall/               # Premium upgrade screen
│   └── settings/              # Notifications, backup/restore, parental gate
│
├── services/                  # Business logic that crosses screen boundaries
│   ├── notification_service.dart  # flutter_local_notifications scheduling
│   ├── backup_service.dart        # JSON export/import via file_picker
│   └── pdf_export_service.dart    # Weekly recap and milestone PDF generation
│
├── theme/
│   └── app_theme.dart         # Color palette, text styles, and ThemeData
│
└── widgets/                   # Reusable UI components
    ├── activity_card.dart
    ├── streak_banner.dart
    ├── skill_coverage_card.dart
    ├── weekly_recap_card.dart
    ├── milestone_item.dart
    ├── daily_tip_card.dart
    ├── badge_unlocked_dialog.dart
    ├── streak_milestone_dialog.dart
    ├── confetti_overlay.dart
    ├── parental_gate_dialog.dart
    └── child_profile_dropdown.dart
```

---

## Contributing

Fork the repository and create a feature branch from `main` (e.g., `feature/weekly-recap-chart`). Before opening a pull request, run `flutter analyze` to catch static issues and `flutter test` to confirm the full test suite passes. Keep pull requests focused — one feature or fix per PR makes review faster. For significant changes, open an issue first to discuss the approach. All contributions are expected to maintain offline-first behavior: no network calls, no third-party analytics SDKs.

---

## License

MIT License

Copyright (c) 2024 PlaySteps Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
