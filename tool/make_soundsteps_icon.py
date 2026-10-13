#!/usr/bin/env python3
"""Generate the SoundSteps launcher icon (Android adaptive + legacy PNGs).

    python3 tool/make_soundsteps_icon.py

Design: warm orange field, white speech bubble holding an "S", and three sound
waves leaving it. Everything lives inside the adaptive-icon safe zone (the
central 66dp of the 108dp canvas) so no launcher mask can clip it.
Writes into android/app/src/soundsteps/res/ so PlaySteps' icon is untouched.
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android/app/src/soundsteps/res")
FONT = os.path.join(ROOT, "assets/fonts/Nunito-Variable.ttf")

BG = (0xFF, 0x8A, 0x5B)  # matches the in-app seed colour
WHITE = (255, 255, 255)

# Adaptive foreground is 108dp; launchers mask to roughly the central 72dp.
FG_DP, VISIBLE_DP = 108, 72
SS = 4  # supersample factor for smooth edges
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def foreground(size):
    """Transparent canvas with the bubble artwork, `size` px square."""
    s = size * SS
    u = s / 108.0  # pixels per dp
    # Artwork is authored in a 108dp space with its bounding box centred at
    # (57.5, 55.5); K shrinks it and the shift centres it on the canvas so the
    # outermost wave keeps a margin inside the launcher mask.
    K = 0.82

    def P(x, y):
        return ((54 + (x - 57.5) * K) * u, (54 + (y - 55.5) * K) * u)

    def L(v):
        return v * K * u

    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Bubble: rounded rectangle + tail.
    left, top = P(24, 31)
    right, bottom = P(70, 71)
    d.rounded_rectangle((left, top, right, bottom), radius=L(12), fill=WHITE)
    d.polygon([P(32, 68), P(32, 80), P(46, 68)], fill=WHITE)

    # The letter, in the background colour so it reads as cut out.
    font = ImageFont.truetype(FONT, int(L(34)))
    try:
        font.set_variation_by_axes([900])  # heaviest Nunito weight
    except Exception:
        pass
    d.text(((left + right) / 2, (top + bottom) / 2), "S", font=font, fill=BG, anchor="mm")

    # Sound waves: three arcs leaving the right side of the bubble.
    wcx, wcy = P(70, 51)
    for r in (9, 15, 21):
        box = (wcx - L(r), wcy - L(r), wcx + L(r), wcy + L(r))
        d.arc(box, start=-42, end=42, fill=WHITE, width=int(L(3.2)))

    return img.resize((size, size), Image.LANCZOS)


def legacy(size, fg_full):
    """Pre-Android-8 icon: rounded square background + the visible centre."""
    s = size * SS
    base = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(base).rounded_rectangle((0, 0, s - 1, s - 1), radius=int(s * 0.22), fill=BG + (255,))
    fw = fg_full.width
    crop = int(fw * VISIBLE_DP / FG_DP)
    off = (fw - crop) // 2
    art = fg_full.crop((off, off, off + crop, off + crop)).resize((s, s), Image.LANCZOS)
    base.alpha_composite(art)
    return base.resize((size, size), Image.LANCZOS)


def main():
    for name, scale in DENSITIES.items():
        out = os.path.join(RES, f"mipmap-{name}")
        os.makedirs(out, exist_ok=True)
        fg = foreground(int(FG_DP * scale))
        fg.save(os.path.join(out, "ic_launcher_foreground.png"))
        legacy(int(48 * scale), fg).save(os.path.join(out, "ic_launcher.png"))

    anydpi = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
    values = os.path.join(RES, "values")
    os.makedirs(values, exist_ok=True)
    with open(os.path.join(values, "ic_launcher_background.xml"), "w") as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- SoundSteps brand orange; same as the in-app colour seed. -->
    <color name="ic_launcher_background">#FF8A5B</color>
</resources>
''')

    # 1024px preview (full-bleed square, as the stores want) for review and
    # for the Play listing's hi-res icon.
    preview = Image.new("RGBA", (1024, 1024), BG + (255,))
    art = foreground(1024 * 108 // 72)
    off = (art.width - 1024) // 2
    preview.alpha_composite(art.crop((off, off, off + 1024, off + 1024)))
    preview.convert("RGB").save(os.path.join(ROOT, "docs/soundsteps_icon_1024.png"))


if __name__ == "__main__":
    main()
