import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/soundsteps/data/letters.dart';
import 'package:playsteps/soundsteps/data/stickers.dart';

/// Text-default symbols (☀ ☂ 🖼) need an invisible U+FE0F to ask for colour,
/// and some renderers ignore it and draw a black glyph. Found by running the
/// app in a browser: the sun in Picture words was a black asterisk.
void main() {
  const variationSelector = 0xFE0F;

  test('letter pictures are colourful-by-default emoji', () {
    for (final l in letters) {
      expect(l.emoji.runes, isNot(contains(variationSelector)),
          reason: '${l.letter} (${l.word}) uses a text-default emoji');
    }
  });

  test('sticker emoji are colourful-by-default', () {
    for (final s in stickers) {
      expect(s.emoji.runes, isNot(contains(variationSelector)),
          reason: '${s.name} uses a text-default emoji');
    }
  });

  test('no SoundSteps source file uses a text-default emoji anywhere', () {
    final offenders = <String>[];
    for (final f in Directory('lib/soundsteps')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].runes.contains(variationSelector)) {
          offenders.add('${f.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
