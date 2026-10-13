import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads width and height from a PNG's IHDR chunk without decoding it.
(int, int) pngSize(File f) {
  final b = f.readAsBytesSync();
  int u32(int o) =>
      (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
  return (u32(16), u32(20));
}

void main() {
  const res = 'android/app/src/soundsteps/res';
  // density -> (legacy px, adaptive foreground px)
  const sizes = {
    'mdpi': (48, 108),
    'hdpi': (72, 162),
    'xhdpi': (96, 216),
    'xxhdpi': (144, 324),
    'xxxhdpi': (192, 432),
  };

  group('SoundSteps launcher icon', () {
    sizes.forEach((density, px) {
      test('$density has correctly sized legacy and foreground PNGs', () {
        expect(pngSize(File('$res/mipmap-$density/ic_launcher.png')),
            (px.$1, px.$1));
        expect(pngSize(File('$res/mipmap-$density/ic_launcher_foreground.png')),
            (px.$2, px.$2));
      });
    });

    test('adaptive icon and brand background are defined', () {
      expect(File('$res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync(),
          contains('@mipmap/ic_launcher_foreground'));
      expect(File('$res/values/ic_launcher_background.xml').readAsStringSync(),
          contains('#FF8A5B'));
    });

    test('store icon is 1024x1024', () {
      expect(pngSize(File('docs/soundsteps_icon_1024.png')), (1024, 1024));
    });
  });
}
