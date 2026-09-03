# PlaySteps — Requirements

Describes what the app is, what it needs to build and run, and what it must
satisfy to ship. Every figure here was read from the source, not from memory —
where a requirement is **not yet met**, it says so.

---

## 1. Purpose and scope

A development tracker for parents of children from birth to 36 months. It
delivers one age-matched play activity per day and a CDC-aligned milestone
ledger, on-device.

**In scope:** daily activities, milestone tracking, growth measurements, photo
memories, streaks and badges, PDF export for appointments, optional family
sharing.

**Explicitly out of scope:** anything a child interacts with (this is a tool for
the adult), medical diagnosis, and any advice that reads as clinical guidance.

---

## 2. Build requirements

| Component | Version | Notes |
|---|---|---|
| Flutter SDK | 3.44.7 | pinned in both CI workflows |
| Dart SDK | ≥ 3.3.0 < 4.0.0 | `pubspec.yaml` |
| JDK | 17 or 21 | Gradle needs it; CI uses Temurin 17 |
| Gradle | 8.11.1 | Flutter 3.44 requires ≥ 8.7 |
| Android Gradle Plugin | 8.9.1 | androidx.browser/activity require ≥ 8.9.1 |
| Kotlin plugin | 1.9.24 | |
| Android compileSdk | 36 | required by androidx.browser 1.9 |
| Android Build-Tools | 36.0.0 | |
| Xcode | ≥ 15 | iOS only |
| CocoaPods | current | iOS only |

These versions move as a set — see the table in `README.md` for which file each
lives in and why each floor exists.

**Core library desugaring must stay enabled.** `flutter_local_notifications`
schedules with `java.time`, so its AAR requires it; that is also why
source/target compatibility is Java 11 rather than 8. Removing either breaks
the Android build.

**Jetifier must stay off.** Nothing depends on legacy `com.android.support`, and
the transform exhausts the heap on CI runners.

---

## 3. Runtime requirements

| | Minimum | Target |
|---|---|---|
| Android | 7.0 (API 24) | API 36 |
| iOS | 13.0 | — |

Play requires new apps to target an API level within a year of the latest
Android release, which is why targetSdk is 36 rather than lower. Targeting 35+
also opts the app into **enforced edge-to-edge display** — verified working on
an Android 16 emulator.

**Architectures:** arm64-v8a, armeabi-v7a, x86_64.

**Network:** none required. The app must boot, onboard, and run every core
feature with no connectivity and no backend configured.

### Permissions

| Permission | Used for | Optional? |
|---|---|---|
| `POST_NOTIFICATIONS`, `VIBRATE` | daily reminder | yes |
| `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` | reminder fires at the chosen time | yes |
| `RECEIVE_BOOT_COMPLETED` | reminder survives a restart | yes |
| `CAMERA` | photo memories | yes |

Denying any of these must leave the rest of the app fully usable.

iOS declares `NSCameraUsageDescription`, `NSPhotoLibrary(Add)UsageDescription`,
`NSMicrophoneUsageDescription` and `NSFaceIDUsageDescription`. **iOS terminates
the process if a usage description is missing**, so these are load-bearing, not
paperwork.

---

## 4. Functional requirements

### 4.1 Onboarding
- Capture a child's name and date of birth; both required before proceeding
- Reject a whitespace-only name
- Show computed age immediately once a date is chosen
- Must lay out without overflow at 320×568 (smallest screen still in use)

### 4.2 Daily activity
- Present exactly one activity per day, matched to the child's age in weeks
- Selection is `band[dayOfYear % band.length]` — deterministic for a given day
- Completion is reversible on the same day
- **Every age band must hold ≥ 10 activities**, enforced by test. Fewer means
  the rotation visibly repeats; at four per band it repeated every four days.
- Library: **120 activities** across 11 age bands, 4 weeks to 36 months

### 4.3 Milestones
- **99 milestones** across 10 age groups (2, 4, 6, 9, 12, 15, 18, 24, 30, 36
  months) and six domains: gross motor, fine motor, language, cognitive,
  social & emotional, sensory
- Toggleable, with optional free-text notes
- Must never imply a milestone *should* already have been reached

### 4.4 Growth
- Record weight, height, head circumference over time; chart each
- Metric and imperial
- Chart must not divide by zero on a single measurement or on identical values

### 4.5 Streaks and badges
- Streaks counted in **calendar days, never 24-hour durations** — a calendar day
  is 23 or 25 hours across a DST transition
- 14 badges; each awarded once and never re-awarded on reload

### 4.6 Photo memories
- Capture against an activity or a milestone
- Stored on-device only; a missing file must explain itself, not show a broken
  image

### 4.7 Monetisation
- Free: activities for ages 0–4 weeks (`isInFreeTier => ageBandMinWeeks < 4`)
- Paid: `playsteps_premium_lifetime` (one-time),
  `playsteps_premium_plus_yearly` (subscription)
- **Entitlements may only be granted by the store**, never locally
- Prices must be read from the store, never hard-coded — a hard-coded figure is
  wrong in every non-USD currency
- With no store available, purchasing must be **disabled**, never bypassed

### 4.8 Parental gate
- Settings sit behind a spelled-out arithmetic question ("What is three times
  four?") so a child who can read digits cannot pass
- A wrong answer must say so

### 4.9 Family sharing (optional)
- Off unless Supabase credentials are supplied at build time
- Sync covers profiles, completions, milestones, badges, growth — **not photos**
- Conflicts resolve by **absolute time**, not string comparison of timestamps
- A corrupt or far-future remote timestamp must never overwrite local data

---

## 5. Data requirements

- Local SQLite is the source of truth; the app is offline-first
- **Foreign keys must be enforced** (`PRAGMA foreign_keys = ON`) so deleting a
  child deletes their completions, milestones, badges, growth and photos.
  SQLite disables them per-connection by default and the schema's cascades are
  inert without it.
- `updated_at` is written in **UTC**; local wall-clock time makes a device's
  timezone offset look like recency
- Backup/restore is a transaction: a malformed file rolls back rather than
  destroying existing data

### Privacy
- No analytics, advertising, crash-reporting or social SDK — verified absent
  from the dependency tree
- No collection of name, email, phone, location, contacts or advertising ID
- Nothing leaves the device unless family sharing is explicitly enabled

---

## 6. Quality gates

All enforced in CI on every branch:

| Gate | Requirement |
|---|---|
| `flutter analyze` | zero issues (`flutter_lints`) |
| `dart format` | no diff |
| `flutter test` | all pass — currently **394** |
| Android | debug APK builds |
| iOS | builds without code signing |
| Web | release build succeeds |
| Timezone | suite re-run under `TZ=America/New_York` |

The timezone job exists because CI runners are UTC and therefore cannot catch
DST bugs — three real ones were found this way.

**Layout:** every screen must render without overflow at 360 px wide.

---

## 7. Store requirements

See `PLAY_LISTING.md` for the filled-in answers.

- Package: `com.nikkyzam.playsteps.app` (permanent once uploaded)
- Distribution: App Bundle (`.aab`), signed with an upload key
- Target audience: **18 and over** — this is a tool for parents; declaring an
  under-13 audience pulls the app into the Families programme
- Assets: 512×512 icon (no alpha), 1024×500 feature graphic, ≥2 phone
  screenshots — all present
- Required forms: privacy policy URL, Data safety, content rating, App access

---

## 8. Requirements not yet met

| Requirement | Status | Owner |
|---|---|---|
| Release signing key | ❌ no `key.properties`; builds are debug-signed | you |
| Store products created | ❌ paywall shows "Store unavailable" until then | you |
| Server-side receipt validation | ❌ `PurchaseService._isValid` is local-only and defeatable on a rooted device | needs a backend |
| Privacy policy published | ❌ `PRIVACY.md` is a draft pending legal review | lawyer |
| Activity content reviewed | ❌ 70 of 120 activities drafted by an AI, unreviewed | paediatric OT / health visitor |
| iOS release build | ⚠️ compiles in CI; never signed, archived or run on a device | you |

The first two are the only ones blocking an internal-testing upload. The rest
block a public launch.
