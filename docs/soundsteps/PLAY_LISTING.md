# SoundSteps — Play Console listing and release checklist

Derived from the current code. **[decide]** marks a judgement call for you;
**[verify]** marks something you must confirm in the Play Console because the
rules change.

**Package name:** `com.nikkyzam.soundsteps.app`
**Category:** Education **[decide]** (alternative: Educational → Early learning)
**Price:** Free, no ads, no in-app purchases (none are wired up)

---

## Store listing

### App name (30 char max)

```
SoundSteps
```

### Short description (80 char max)

```
Letter sounds and picture words for toddlers. No ads. No internet needed.
```

### Full description (4000 char max)

```
SoundSteps helps toddlers meet letters and the sounds they make, through big,
simple, tap-and-listen play.

LETTERS
Tap any letter from A to Z to hear its sound and a picture word: "buh. B is
for ball."

MATCH THE SOUND
Hear a sound, then tap the letter that makes it. Three big choices, and a
gentle "try again" if it isn't right. No scores to lose, no timers.

PICTURE WORDS
See a picture, hear its word, and tap the letter it starts with. When you find
it, the word appears with its first letter highlighted.

MADE FOR LITTLE HANDS
• Big buttons, no reading needed to get around
• Spoken instructions for every activity
• No ads, no purchases, no tracking
• No accounts, and no internet connection needed
• Collects no personal information

Best played together: sit with your child, say the sounds along with the app,
and talk about the pictures.

SoundSteps uses your device's built-in text-to-speech voice. Make sure a voice
is installed in your device's settings.
```

Keep claims modest: do **not** write "teaches your child to read" or any
outcome claim you cannot back up.

### Graphics

| Asset | Requirement | Status |
|---|---|---|
| App icon | 512×512 PNG | Done — `docs/soundsteps/icon_512.png` |
| Feature graphic | 1024×500 PNG/JPG | **Missing** |
| Phone screenshots | 2–8, 16:9 or 9:16 | **Missing** — capture Home, Letters, Match, Picture words from a real device |

---

## Policy forms

**Target audience and content** **[verify]**
- Age groups: select the youngest band that applies (ages 5 and under). This
  puts the app in the **Designed for Families** programme, which is correct for
  SoundSteps (unlike PlaySteps, which targets parents).
- Appeals to children: yes.
- Ads: none.

**Data safety** (matches the code today)
- Does the app collect or share any user data? **No.**
- Is all data encrypted in transit / can users request deletion? Not
  applicable — no data is collected. Answer per the form's wording.

**Content rating:** complete the IARC questionnaire honestly: no violence, no
user interaction, no location sharing, no purchases. Expect the lowest rating.

**Privacy policy URL:** required. Publish `docs/soundsteps/PRIVACY.md` (after
legal review, and with the engineering note removed) at a public URL, e.g. a
GitHub Pages page, and paste the URL in the listing.

**Families Policy checklist**
- [x] No behavioural ads or ad SDKs
- [x] No collection of personal or device identifiers
- [x] No sensitive permissions (CI fails the build if camera, notifications,
      alarms, boot, billing or network permissions leak in). **[verify]** open
      the release build's merged manifest once and confirm it is clean
- [x] No in-app purchases, links out or social features
- [ ] **[verify]** If you later add a link out or a purchase, put it behind a
      parental gate (see `test/support/parental_gate.dart` for the PlaySteps
      pattern)

---

## Release checklist

Code (done)
- [x] `soundsteps` flavor, app ID, icon, CI matrix entry
- [x] Permissions stripped and enforced in CI

Accounts and secrets (you)
- [ ] Google Play developer account; create the app record for
      `com.nikkyzam.soundsteps.app`
- [ ] Generate a SoundSteps upload keystore (`docs/RELEASE.md` step 1). Keep it
      backed up off this repo; Google cannot recover it.
- [ ] GitHub → Settings → Environments → create **`soundsteps`** with secrets:
      `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`,
      `ANDROID_STORE_PASSWORD`, `PLAY_STORE_SERVICE_ACCOUNT_JSON`.
      (`SUPABASE_*` are not needed.)
- [ ] Also move PlaySteps' existing secrets into a `playsteps` environment, or
      its next release will fail to find them
- [ ] Check "SoundSteps" is not already a trademark or an existing Play app name

Verify on hardware
- [ ] CI is green for both flavors, including the new permissions check
- [ ] Install on a real Android phone: the sounds are intelligible ("buh",
      "sss", "aw" for O), and all three games work
- [ ] Check the picture emoji render on your oldest target Android version
      (🪺 nest and 🪁 kite are missing on older systems)

Publish
- [ ] Add listing text, icon, feature graphic, screenshots
- [ ] Fill in Target audience, Data safety, Content rating, Privacy policy URL
- [ ] `git tag soundsteps-v1.0.0 && git push --tags` → uploads to the
      **internal** track
- [ ] **[verify]** New personal developer accounts must run a closed test with
      a minimum number of testers for a minimum period before applying for
      production. Check Play's current numbers in the Console.
- [ ] Promote through closed testing to production

Not blocking a first Android release, but open
- [ ] iOS flavor (needs Xcode on a Mac)
- [ ] Separate version numbers per app (`pubspec.yaml` is shared today)
