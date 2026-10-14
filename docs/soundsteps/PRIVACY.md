# SoundSteps Privacy Policy

**Status: DRAFT — requires review by a qualified lawyer before publication.**
This describes what the app does today, checked against the source code. It is
a starting point for counsel, not legal advice. Because SoundSteps is for
children, have counsel confirm it against COPPA (US), GDPR-K / UK Children's
Code (EU/UK) and Google Play's Families Policy for the markets you ship in.

**Last updated:** _[date of publication]_
**Contact:** _[privacy@yourdomain.example]_
**Developer:** _[legal entity name and address]_

---

## Summary

SoundSteps is a letters-and-sounds app for toddlers (ages 2–4). It collects no
personal information, has no accounts, shows no ads, contains no analytics or
third-party tracking, and does not need an internet connection.

## What we collect

**Nothing.** The app does not ask for, store or transmit your name, your
child's name, age, photos, voice, location, contacts, device identifiers or
advertising IDs.

The star count shown during games is held in memory while a game is open and is
discarded when it closes. It is not saved or sent anywhere.

## Permissions

SoundSteps requests no camera, microphone, location, contacts, storage,
notifications or network permissions. The build removes the ones it could
inherit from the shared codebase and CI fails if any returns (see
`android/app/src/soundsteps/AndroidManifest.xml` and `ci.yml`). _[Before
publishing, confirm the final merged manifest of the release build lists no
permissions at all.]_

## How the app speaks

Letter sounds and words are spoken by your device's built-in text-to-speech
engine. The text spoken (for example "buh. B is for ball") is fixed content
inside the app, never anything about your child. The engine is part of your
device (commonly Google Text-to-Speech on Android) and is governed by that
provider's own privacy policy, not ours. _[Counsel: confirm wording.]_

## Third parties

We share no data with anyone because we collect none. The app contains no
advertising, analytics or social-media components that run in SoundSteps.

> **Engineering note, remove before publishing:** SoundSteps is built from the
> same codebase as PlaySteps, so the binary still contains PlaySteps' libraries
> (cloud sync, purchases, notifications). They are never started by SoundSteps
> (`main()` boots a separate path) and their permissions are removed from the
> manifest, but the code is present. If counsel wants the policy to say "contains
> no such software", split SoundSteps into its own package first.

## Children's privacy

SoundSteps is designed for use by young children with a parent nearby. Because
it collects no personal information, there is nothing to consent to, access,
correct or delete. We do not knowingly collect information from children.

## Changes and contact

If we ever add features that collect data (for example saved progress synced to
an account), we will update this policy and the app's Play Store data-safety
information first, and ask for verifiable parental consent where the law
requires it. Questions: _[privacy@yourdomain.example]_.
