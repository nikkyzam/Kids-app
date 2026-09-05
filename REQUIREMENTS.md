# PlaySteps — Requirements

Describes what the app is, what it needs to build and run, and what it must
satisfy to ship. Every figure here was read from the source, not from memory —
where a requirement is **not yet met**, it says so.

---

## 1. Purpose and scope

A development tracker for parents of children from birth to 36 months. It
delivers one age-matched play activity per day and a CDC-aligned milestone
ledger, on-device.

**In scope:** daily activities, milestone tracking, growth measurements against
the WHO standards, photo memories and a baby book, streaks and badges, PDF
export for appointments, optional family sharing. Up to three children per
device, each with their own data.

**Explicitly out of scope:** anything a child interacts with (this is a tool for
the adult), medical diagnosis, and any advice that reads as clinical guidance.

**Who it is written for.** A first-time parent, often exhausted, often anxious.
Every string in the app is written as a suggestion from someone who knows a bit
about this, never as an instruction from someone qualified to assess their
child. Two rules follow from that and are enforced by tests rather than left to
judgement:

- Nothing may tell a parent their child is behind, delayed or abnormal. The
  milestone notes are checked against a list of such words on every build.
- Nothing may grade a growth measurement. A percentile is reported as a
  comparison and nothing else; "above average", "underweight" and eight similar
  phrasings fail the suite.

**Babies born early.** A due date is optional at onboarding and editable
afterwards. Where one is given, every content decision — the daily activity,
the library, the plan, leaps, the milestone ledger, the red-flag prompts and
the WHO growth curves — runs off the corrected age until the child turns two.
The chronological age is never replaced, only accompanied.

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

**No store, no problem.** The app must be fully usable where Google Play
Services is absent or unreachable — an Amazon Fire tablet, a de-Googled
device, a region where the store is blocked. Purchasing is *disabled* in that
state, never bypassed and never a dead end: the free trial and the age-based
free tier still work.

**Running out of storage.** Photos are the one thing in this app a parent
cannot recreate, so the storage path is defensive at three points: room is
checked before the camera opens, the copy is length-verified before any
database row points at it, and a failed write leaves no row and no truncated
file. A device that fills up mid-capture says so; it does not lose a memory
quietly.

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
- Optionally capture an original due date ("arrived early") and the child's sex
  — both skippable, and both editable later from Settings
- "Arrived early" without a due date must not be savable: it would be an answer
  that changed nothing
- A due date on or before the birth date corrects nothing; a gap wider than 17
  weeks is clamped, so a typo or a corrupt synced row cannot push a toddler
  back into newborn content
- Sex is asked for one reason only, and says so: the WHO growth curves are
  sex-specific
- Must lay out without overflow at 320×568 (smallest screen still in use)

### 4.2 Daily activity
- Present exactly one activity per day, matched to the child's age in weeks
  (corrected age, where a due date was given)
- Selection is `band[dayOfYear % band.length]` — deterministic for a given day
- `dayOfYear` is counted from the calendar, **never as a Duration from 1
  January**: once a timezone has moved on or off daylight saving, the elapsed
  hours are short of a whole number of days and truncation slides the entire
  rotation by one
- Completion is reversible on the same day
- **Every age band must hold ≥ 10 activities**, enforced by test. Fewer means
  the rotation visibly repeats; at four per band it repeated every four days.
- Library: **120 activities** across 11 age bands, 4 weeks to 36 months

**"Not for us."** An activity can be set aside, with an optional reason from a
fixed list (too easy, too hard, no materials, not right now). A replacement is
offered immediately, and the dismissed activity leaves that child's rotation
for good rather than returning next week. Reasons never leave the device.
Settings shows how many are set aside and can restore them. An activity already
marked complete cannot be dismissed — that would silently drop a day of the
parent's streak.

**History.** Every day back to the child's first is browsable, whether or not
the app was opened that day. A day with a completion reports the activity
actually done; any other day is recomputed from the age the child was *then*.

### 4.3 Milestones
- **99 milestones** across 10 age groups (2, 4, 6, 9, 12, 15, 18, 24, 30, 36
  months) and six domains: gross motor, fine motor, language, cognitive,
  social & emotional, sensory
- Toggleable, with optional free-text notes
- Must never imply a milestone *should* already have been reached

**Context.** Each of the 99 carries a "What to look for" — concrete and
observable, describing the wobble rather than the hold — and a "When to talk to
your pediatrician". A test asserts all 99 are covered, so a new milestone
cannot ship as a bare checkbox. The doctor note is *derived*, not authored:
where the CDC's "Learn the Signs, Act Early" programme flags a milestone it
names the CDC's own age; everywhere else it says ranges are wide and to raise
it at the next check-up. A test walks all 99 for "delay", "behind", "abnormal",
"concerning" and seven more, and fails on any of them.

The context opens from its own control, never the row — the row toggles the
milestone, and a parent reading up on what to look for must not tick it by
accident.

### 4.4 Growth
- Record weight, height, head circumference over time; chart each
- Metric and imperial
- Chart must not divide by zero on a single measurement or on identical values

**WHO percentiles.** The chart draws the 3rd, 15th, 50th, 85th and 97th
percentile curves behind the child's own line, and one sentence says where the
latest measurement falls.

- The bundled data is the WHO Child Growth Standards LMS parameters (Multicentre
  Growth Reference Study, 2006) by month, birth to 36 months, per sex and
  metric. Everything drawn or reported is computed from L, M and S rather than
  stored, so there is one source of truth per age.
- Length-for-age (lying down) to 23 months; height-for-age (standing) from 24 —
  WHO's own changeover, with the 0.7 cm step pinned by test.
- WHO's tail correction is applied to weight past ±3 SD, without which a
  genuinely small baby's z-score runs away to an absurd number.
- A preemie is plotted against their corrected age; these curves describe babies
  born at term, and the birth date would put a normally growing child at the
  bottom of every chart. The screen says that is what it is doing.
- Where there is no honest answer — no sex recorded, an age past three years —
  the screen says which and why rather than showing nothing.
- The number is never a grade. See the tone rules in §1.

### 4.5 Streaks and badges
- Streaks counted in **calendar days, never 24-hour durations** — a calendar day
  is 23 or 25 hours across a DST transition
- 14 badges; each awarded once and never re-awarded on reload

### 4.6 Photo memories
- Capture against an activity, a milestone, or nothing in particular — a first
  smile does not hang off either
- **Photos are copied into storage the app owns.** The picker returns a file in
  the OS cache, which Android and iOS purge whenever they want the space;
  keeping that path meant a memory could quietly stop existing weeks later
- The copy is length-verified before a row points at it, and a failed write
  leaves neither row nor file
- Deleting a memory deletes its file. Nothing outside the app's own photo
  directory is ever deleted — a path from an older build could point into the
  picker's cache or the user's own library
- A missing file must explain itself, not show a broken image

**Baby book.** Photos, milestones (with their notes) and growth measurements in
one chronological column, newest first, grouped by month. A photo taken for a
milestone appears on that milestone rather than a second time on its own.
Completed activities are deliberately excluded: there is one nearly every day,
and three hundred identical lines would bury the first steps.

### 4.7 Monetisation
- **Free trial: 14 days from first launch, everything unlocked.** The
  age-based tier alone gave the parent of a newborn four weeks of content
  before a paywall, which is not enough time to evaluate anything on no sleep
- When the trial lapses the app falls back to the age-based free tier rather
  than locking the door; nothing already recorded becomes unreachable, and the
  paywall says so
- A reinstall does grant a fresh trial. The alternative is requiring an
  account, which this app deliberately does not
- The paywall and the Premium Plus screen key their "you already have this"
  states to the **purchase**, not the effective unlock — keyed to the unlock
  they would be unreachable for the whole fortnight
- A one-time purchase includes every future activity pack and content update
- Free after the trial: activities for ages 0–4 weeks
  (`isInFreeTier => ageBandMinWeeks < 4`)
- Paid: `playsteps_premium_lifetime` (one-time),
  `playsteps_premium_plus_yearly` (subscription)
- **Entitlements may only be granted by the store**, never locally
- **Receipts are verified server-side** where a backend is configured
  (`supabase/functions/verify-purchase`). A rejection is final and revokes the
  entitlement on the next launch — this is how refunds, chargebacks and lapsed
  subscriptions arrive. A server that cannot be *reached* must never revoke
  anything: the purchase stands, the receipt is stored unverified, and it is
  re-checked later. Collapsing "could not ask" into "no" would take a real
  purchase away every time the backend had a bad day
- Confirmed entitlements are re-checked weekly, or as soon as a known
  subscription expiry passes
- An entitlement with no stored receipt — granted before validation existed, or
  by a build with no backend — is left alone. Absence of evidence is not
  grounds to take away what someone bought
- A revoked entitlement drops the app to the free tier and touches nothing the
  parent recorded
- Prices must be read from the store, never hard-coded — a hard-coded figure is
  wrong in every non-USD currency
- With no store available, purchasing must be **disabled**, never bypassed

### 4.8 Parental gate
- Settings sit behind an arithmetic question with **random operands and a random
  operator** (plus, minus, times) — a gate that always multiplies is a gate whose
  shape a child learns
- The whole exchange is in words, answers included: a child who cannot read
  still recognises digits and can match them, and a question in digits pastes
  straight into a calculator
- Six options, not four, with distractors within six of the answer so the right
  one cannot be found by being the largest
- Subtraction is ordered so the answer is never negative
- A wrong answer must say so, and asks a different question

### 4.9 Family sharing (optional)
- Off unless Supabase credentials are supplied at build time
- Sync covers profiles, completions, milestones, badges, growth — **not photos**
- Conflicts resolve by **absolute time**, not string comparison of timestamps
- A corrupt or far-future remote timestamp must never overwrite local data

**Deferred, deliberately:** a QR or link-based invite, and a shared family feed.
Both need a working sync deployment to design against — the invite flow is a
Supabase auth question rather than a Flutter one, and a feed that shows one
parent what the other did is only meaningful once sync has been run between two
real devices. Sharing is off by default and unconfigured in this repository, so
neither can be built honestly yet. See §8.

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
- **Schema upgrades are tested against the schema users actually have.** The
  migration suite builds an older schema by hand, seeds it, opens it through
  the app and checks the rows survived and the new columns are writable
- **Delete All Data** wipes every table, every photo file and every preference
  the parent chose, behind the parental gate and behind a typed confirmation,
  then returns to onboarding. Entitlements survive: they record a purchase, not
  data the parent entered. If the file sweep fails the records are still wiped
  and the parent is told plainly — an all-or-nothing failure serves nobody

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
| `flutter test` | all pass — currently **574** |
| Android | debug APK builds |
| iOS | builds without code signing |
| Web | release build succeeds |
| Timezone | suite re-run under `TZ=America/New_York` |

The timezone job exists because CI runners are UTC and therefore cannot catch
DST bugs — three real ones were found this way.

**Layout:** every screen must render without overflow at **320×568 and
360×640**, with real content, scrolled end to end, and again at a 1.3 text
scale on the narrowest phone — 48 checks, run as their own CI step so a layout
regression reads as one.

Not golden-file tests, deliberately. A committed PNG has to be produced on the
same platform, fonts and renderer as CI, and when it drifts it fails with
"13,208 pixels differ" — which is a rewritten reference far more often than it
is a fixed bug. What actually breaks on a small phone is content that does not
fit, and Flutter reports that precisely.

**Performance:** the activity feed and the milestone list should hold 60fps on
a low-end device (a three-year-old Moto G, an iPhone SE). ⚠️ Not yet measured —
see §8.

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
| Server-side receipt validation deployed | ⚠️ function, client, revocation and tests are written; nobody has deployed it or supplied the Google service account and Apple shared secret, so builds still fall back to the local check | you |
| Receipt validation tested against a real store | ❌ verified by unit tests against a fake transport only — no sandbox purchase has been round-tripped through it | you |
| Privacy policy published | ❌ `PRIVACY.md` is a draft pending legal review | lawyer |
| Activity content reviewed | ❌ 70 of 120 activities drafted by an AI, unreviewed | paediatric OT / health visitor |
| Milestone context reviewed | ❌ 99 "what to look for" notes drafted by an AI, unreviewed | paediatric OT / health visitor |
| WHO table spot-checked | ⚠️ transcribed from a third-party machine-readable copy and validated against the SD values shipped alongside it; nobody has yet compared a row to WHO's own published PDF | you |
| Scroll performance measured | ❌ no profile run on a low-end device | you |
| Family invite flow (QR / link) | ❌ deferred — needs a live Supabase deployment to design against | you |
| Shared family feed | ❌ deferred — only meaningful once sync runs between two real devices | you |
| iOS release build | ⚠️ compiles in CI; never signed, archived or run on a device | you |

The first two are the only ones blocking an internal-testing upload. The rest
block a public launch.
