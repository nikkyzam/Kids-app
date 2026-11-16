# SoundSteps store images

Everything in `docs/soundsteps/store/` is rendered from the real app, so the
listing never drifts from what a parent installs. Regenerate after any visible
UI change:

```bash
# 1. The app and the feature-graphic page, as web builds
flutter build web -t lib/soundsteps/main.dart --web-renderer html --release
flutter build web -t tool/soundsteps_store_art.dart --web-renderer html --release -o build/store_art

# 2. Capture (needs Node + the `playwright` package + Chromium)
NODE_PATH=$(npm root -g) node tool/soundsteps_store_shots.js
```

| File | Play Console slot | Size |
|---|---|---|
| `feature_graphic_1024x500.png` | Feature graphic | 1024×500 |
| `01_home.png` … `06_grown_ups.png` | Phone screenshots (in this order) | 1080×1920 (9:16) |
| `../icon_512.png` | App icon | 512×512 |

The script seeds a believable few weeks of play for a child called "Mia" (23
stars, 7 letters learned, D tricky, ~70 minutes this week) so screens show a
lived-in app, not an empty one. All of it is fake demo data in the browser's
storage; nothing is uploaded.

`--web-renderer html` is for the Flutter version in this repo's cloud
container (3.24). On newer Flutter, which dropped that flag, omit it.

Caveats: these are web renders of the Flutter UI. The layout, art and text
match the Android app; system chrome (status bar) is not shown, and emoji are
drawn with the Noto Color Emoji font, as on most Android phones.
