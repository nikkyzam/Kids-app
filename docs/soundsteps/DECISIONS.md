# SoundSteps — decisions log

Decisions made autonomously while building the animation and learning layer,
with the reason for each, so you can overrule any of them. Newest layer last in
each section. "Verified" means tests ran; "unverified" means it needs a real
Android build or device (this environment has Flutter 3.24 and no Android SDK).

## Product

1. **Letters + two games stay the whole product for v1.** No new games. The
   weak points were motion and learning, not breadth; a third game would have
   left both unaddressed.
2. **Progress is saved on the device** (stars, and per-letter first-try wins and
   misses) in `SharedPreferences`. *Why:* repeating tricky letters is the main
   learning lever and needs memory across sessions. *Cost:* the privacy policy
   had to change (done: it now says what is saved and that it never leaves the
   device) and Play's Data safety answer needs a [verify] against current
   wording. It still collects nothing; nothing is transmitted.
3. **No account, no cloud sync for SoundSteps.** Keeps it out of COPPA/GDPR-K
   territory. The Supabase code in the shared codebase is never started.
4. **A star is always earned on a right answer; only a first-try answer counts
   toward mastering the letter.** Keeps encouragement unconditional while
   keeping the "learned" signal honest.
5. **One miss per round, however many wrong taps.** A toddler mashing a wrong
   button must not bury a letter in misses.
6. **Mastered = 3+ first-try wins and more wins than misses.** Deliberately
   reversible: three later misses un-master a letter. Thresholds are guesses;
   tune them after watching a real child.
7. **Practice weighting** (`lib/soundsteps/data/practice.dart`): letters the
   child keeps missing come up up to 11x as often as mastered ones; new letters
   a little more than in-progress ones; mastered letters never drop to zero
   (toddlers forget, and they make easy wins). Never the same letter twice in
   a row. Simple spaced practice, not a scheduler.
8. **The home screen shows `⭐ stars  🔤 learned/26`**, and learned letters wear
   a star on the Letters grid. Progress is visible to the parent and rewarding
   to the child without a separate screen to build and maintain.
9. **Reset is parent-only:** long-press the star count → grown-ups-only
   question → confirmation. Hidden from toddlers, and gives parents the deletion
   control children's-privacy rules expect.

## Animation

10. **Built from Flutter's own animation classes; no new package** (no Lottie,
    no confetti). *Why:* the binary already carries PlaySteps' libraries, and a
    toddler app should stay small and offline. The three effects are
    `Bounce`, `Shake` and `StarBurst` in `lib/soundsteps/widgets/motion.dart`.
11. **Wrong answer = a gentle wobble and "try again", never a buzzer or red.**
12. **Right answer = the tapped letter bounces, a star burst flies out, the
    picture hops, the word appears with its first letter highlighted.**
13. **Animations honour the device's reduce-motion setting** (`disableAnimations`)
    and are tested to be off when it is set (and the test is proven non-vacuous:
    it fails if the guard is removed).
14. **No sound effects beyond speech.** Fewer things to license or get wrong,
    and the spoken feedback is the teaching.

## Engineering

15. **Merged the two games into one `ChoiceGame` screen.** They were ~90%
    identical and each new rule (progress, animation) would have had to be
    written twice. The games are now thin wrappers; the rules live in one place.
16. **Found and fixed a bug while doing so:** on a wrong tap the app said "Try
    again" and then immediately the prompt; the speech engine cancels the first
    utterance when asked to speak again, so "Try again" was never heard. It is
    now one utterance ("Try again. <prompt>").
17. **SoundSteps has its own parental gate** (`widgets/parent_gate.dart`)
    instead of reusing PlaySteps'. That one lives in a file that imports
    PlaySteps' theme, which would have pulled PlaySteps' look into a SoundSteps
    dialog and tied SoundSteps to Flutter-3.44-only theme code. The new gate
    reuses only the number-to-words helper (question and answers in words, so a
    2-4 year old cannot read or calculate them).
18. **Storage failure never reaches the child.** If preferences can't be
    opened or the saved data is corrupt, the app starts fresh/in memory.
19. **Timer for the next round is cancelled on dispose** (was a bare delayed
    future guarded by `mounted`).

## Engagement ("captivating, keeps their attention")

20. **Pip, a mascot chick, drawn in code** (`widgets/mascot.dart`): blinks and
    bobs every few seconds, jumps and grins on a right answer, tilts its head
    encouragingly after a miss, says hello when the app opens and when tapped.
    *Why:* a character to bond with is the single strongest attention hook in
    toddler apps. Drawn with a `CustomPainter` so there is no art to license;
    every motion is one-shot (no endless loop) and off under reduce-motion.
21. **Sticker book: one animal per 5 stars, 30 in all** (`data/stickers.dart`,
    `screens/sticker_book_screen.dart`). Earning one interrupts the game with a
    "New sticker!" moment and Pip names the animal. *Ethics:* fixed unlock
    order (no randomised rewards / loot-box mechanics), finite set (no endless
    treadmill), no streaks, no timers, no "come back tomorrow" pressure.
    Derived from the star count, so nothing new is stored.
22. **Varied praise** ("Wow!", "You did it!", ...) before the teaching sentence,
    which never changes ("pig starts with puh"). Variety holds attention; the
    lesson stays consistent. Wrong-answer feedback stays one calm, fixed
    phrase.
23. **Idle nudge:** after 8 quiet seconds the right answer wiggles and the
    prompt repeats ("Listen! ..."), at most twice per round, so it invites
    rather than nags.
24. **Colour:** the three answer buttons are three different bright colours
    with white letters; the alphabet grid is a soft rainbow.
25. **Not done on purpose:** no session-length nudges *toward* more play, no
    push notifications, no daily rewards. A break reminder for long sessions
    would be a reasonable later addition for parents.

## Build

26. **Kotlin Gradle plugin 1.9.24 → 2.2.20.** `flutter_tts` 4.2.5 is built
    against kotlin-stdlib 2.2, which the old compiler could not read; the
    Android release build failed for *both* flavors from the commit that added
    `flutter_tts` until this fix. I had not checked CI after those pushes.
27. **This environment cannot build Android or iOS locally:** `dl.google.com`
    (Android SDK) is blocked by the network policy, and iOS needs macOS. CI's
    Android and iOS jobs are the build check.

## Deliberately not done

- **Recorded audio / illustrations.** Need assets you must create or license;
  emoji and text-to-speech remain the stand-ins. Biggest remaining quality gap.
- **iOS.** Still needs Xcode on a Mac for the flavor/scheme setup.
- **Real-child testing.** Nothing here has been validated with a toddler.
  Mastery thresholds, animation length and the phonetic spellings are informed
  guesses.
- **Tuning for tablets / landscape.** Portrait phone only, as PlaySteps.

## Still unverified

- A real Android build of either flavor, and CI's new permission check.
- Animation smoothness and speech quality on a physical device.
- The merged release manifest listing no unwanted permissions.
