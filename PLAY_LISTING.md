# Play Console — listing copy and form answers

Everything here is derived from the current code, so it should match what a
reviewer actually sees. Where a field is a judgement call rather than a fact,
it is marked **[decide]**.

**Package name:** `com.nikkyzam.playsteps.app`
**Target audience:** 18 and over — PlaySteps is a tool *for parents*. Do not
tick an under-13 age band; that moves the app into the Families programme and a
much stricter review it does not need.

---

## Store listing

### App name (30 char max)

```
PlaySteps
```

### Short description (80 char max)

```
Daily play activities and milestone tracking for your baby's first 3 years.
```

### Full description (4000 char max)

```
PlaySteps turns "what should we do today?" into a two-minute answer.

Every day it suggests one age-matched play activity for your child — what you
need, what to do, and the skill it builds. Alongside it sits a milestone ledger
covering birth to three years, so you always know what to watch for and what you
have already seen.

WHAT YOU GET

• A daily activity chosen for your child's exact age in weeks
• 120 activities spanning 4 weeks to 36 months
• 99 developmental milestones across six domains, grouped the way your
  paediatrician groups them
• Growth tracking for weight, height and head circumference, with charts
• Photo memories attached to the activity or milestone they belong to
• Streaks and badges, because showing up daily is the hard part
• A one-tap PDF summary to take to a doctor's appointment

SIX DEVELOPMENTAL DOMAINS

Gross motor, fine motor, language, cognitive, social & emotional, and sensory.
The app shows which ones you have been practising and which have gone quiet.

PRIVATE BY DEFAULT

No ads. No tracking. No analytics of any kind. Everything you record stays on
your device unless you deliberately turn on family sharing to bring a co-parent
in. Photos never leave the device that took them, even then.

FOR PARENTS, NOT FOR CHILDREN

PlaySteps is a tool for the adult. There is nothing for a child to tap, and a
parental gate protects the settings.

FREE AND PAID

The first four weeks are completely free. A single one-time purchase unlocks the
full activity library through 36 months — no subscription for the core app.

PlaySteps offers general play ideas and milestone information. It is not medical
advice and does not diagnose anything. Children develop at different paces; if
you have concerns about your child's development, speak to your health visitor
or doctor.
```

> The closing disclaimer is deliberate. The app sits next to a CDC-aligned
> milestone list and a red-flags screen, and a listing that reads as clinical
> guidance invites both reviewer pushback and a parent misreading it.

---

## App content — form answers

### Privacy policy

**A public URL is required.** `PRIVACY.md` in this repo is accurate but is still
marked DRAFT pending legal review. **[decide]** where to host it.

### Data safety

Answer for the **default** build (no Supabase credentials configured), then
adjust if you ship with sync enabled.

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No**, if shipping without Supabase credentials. **Yes**, if family sharing is enabled. |
| Is all data encrypted in transit? | Yes (HTTPS) — only relevant when sync is on |
| Can users request data deletion? | Yes — Settings → Children → delete profile |

If family sharing **is** enabled, declare these as *collected and shared*, all
optional and all tied to the account:

- Name (the child's name or nickname)
- Other personal info (date of birth)
- Health and fitness (growth measurements — weight, height, head circumference)
- App activity (activity completions, milestone achievements, badges)

Do **not** declare photos: `sync_service.dart` no longer syncs photo memories at
all, so images and captions never leave the device.

Do **not** declare: location, contacts, messages, financial info, device
identifiers, or advertising ID — none are collected. There is no analytics,
crash-reporting, advertising, or social SDK in the dependency tree.

### Content rating questionnaire

Category: **Reference / Education**. Everything below is "No":

violence, sexual content, profanity, controlled substances, gambling (real or
simulated), horror, user-generated content, user-to-user communication, sharing
location, personal information collection beyond what is declared above.

Expected outcome: **Everyone / PEGI 3**.

### Ads

**No ads.** The app contains no advertising SDK.

### App access

Reviewers must be told the app is gated, or they will file it as broken:

```
No login is required. All features work offline with no account.

Content for children aged 0–4 weeks is free. Activities beyond 4 weeks require a
one-time in-app purchase; to review that content without purchasing, use a
license-test account.

Cloud sync and family sharing are optional and are disabled in this build, so
the sign-in and family screens intentionally show a "Cloud sync unavailable"
notice.
```

### Government apps / financial features / health

- Government app: **No**
- Financial features: **No**
- Health apps: **[decide]** — the app records growth measurements and
  milestones. It makes no diagnostic claim and offers no medical advice, so
  "No" is defensible, but confirm this with whoever reviews the privacy policy,
  since growth data can be treated as health data under GDPR.

---

## Assets checklist

| Asset | Requirement | Status |
|---|---|---|
| App icon | 512×512, 32-bit PNG, **no alpha** | ✅ `store-icon-512.png` |
| Feature graphic | 1024×500, PNG or JPG, no alpha | ✅ `feature-graphic-1024x500.png` |
| Phone screenshots | 2–8, 16:9 or 9:16, 320–3840 px | ✅ five at 1080×2400 |
| Tablet screenshots | Optional | ❌ not made |

---

## Release checklist

1. Generate the upload keystore and `android/key.properties` (never commit it)
2. `flutter build appbundle --release`
3. Play Console → Testing → Internal testing → Create new release
4. Upload `build/app/outputs/bundle/release/app-release.aab`
5. Accept Play App Signing
6. Add tester emails, save, review, roll out
7. **After** the first upload: Monetise → Products → create
   `playsteps_premium_lifetime` (one-time) and `playsteps_premium_plus_yearly`
   (subscription). Product IDs must match `lib/services/purchase_service.dart`
   exactly or the paywall shows "Store unavailable".
8. Add the same testers to **License testing** so purchases are free for them

## Known gaps before a public launch

- Receipt validation is local-only (`PurchaseService._isValid`); a rooted device
  can defeat it. Needs a server calling Google's `purchases.products.get`.
- The 70 drafted activities in `activities_draft_data.dart` have not been
  professionally reviewed.
- `PRIVACY.md` is a draft pending legal review.
