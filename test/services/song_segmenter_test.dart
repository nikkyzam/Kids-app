import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/models/song.dart';

/// Splitting a song into sections without ever touching its audio.
///
/// The arithmetic is the whole feature: YouTube's terms forbid downloading a
/// track to analyse it, so the only input is the runtime the player reports.
/// These pin down that the sections always tile the video exactly — no gaps to
/// fall into, no overshoot past the end, and never a zero-length chip.
void main() {
  const oneLine = SongPart(label: 'A', lines: ['x']);
  const twoLines = SongPart(label: 'B', lines: ['x', 'y']);

  group('split', () {
    test('returns nothing when there is nothing to split', () {
      expect(
          SongSegmenter.split(const Duration(minutes: 2), const []), isEmpty);
      expect(SongSegmenter.split(Duration.zero, const [oneLine]), isEmpty);
      expect(SongSegmenter.split(const Duration(seconds: -5), const [oneLine]),
          isEmpty);
    });

    test('a single part runs to the end of the video', () {
      const total = Duration(seconds: 100);
      final parts = SongSegmenter.split(total, const [oneLine]);

      expect(parts, hasLength(1));
      expect(parts.single.end, total,
          reason: 'the last part is pinned to the end, never accumulated');
    });

    test('skips an intro before the first part starts', () {
      final parts =
          SongSegmenter.split(const Duration(seconds: 100), const [oneLine]);

      expect(parts.single.start, greaterThan(Duration.zero),
          reason: 'uploads open on a title card, not the first note');
    });

    test('parts tile the video with no gaps and no overlap', () {
      final parts = SongSegmenter.split(
        const Duration(seconds: 137),
        const [oneLine, twoLines, oneLine],
      );

      expect(parts, hasLength(3));
      for (var i = 1; i < parts.length; i++) {
        expect(parts[i].start, parts[i - 1].end,
            reason: 'part $i must begin exactly where part ${i - 1} ended');
      }
      expect(parts.last.end, const Duration(seconds: 137));
    });

    test('a longer part gets more of the runtime', () {
      final parts = SongSegmenter.split(
        const Duration(seconds: 200),
        const [oneLine, twoLines],
      );

      expect(parts[1].length, greaterThan(parts[0].length),
          reason: 'two lines should occupy about twice one line');
    });

    test('every part has real duration, so no chip is unplayable', () {
      final parts = SongSegmenter.split(
        const Duration(seconds: 30),
        const [oneLine, oneLine, oneLine, oneLine],
      );

      for (final part in parts) {
        expect(part.length, greaterThan(Duration.zero));
      }
    });

    test('weightless parts are refused rather than divided by zero', () {
      const weightless = SongPart(label: 'A', lines: [], weightOverride: 0);
      expect(
        SongSegmenter.split(const Duration(seconds: 60), const [weightless]),
        isEmpty,
      );
    });
  });

  group('splitEvenly', () {
    test('cuts an unknown video into equal, labelled slices', () {
      final parts = SongSegmenter.splitEvenly(const Duration(seconds: 120), 4);

      expect(parts, hasLength(4));
      expect(parts.map((p) => p.part.label),
          ['Part 1', 'Part 2', 'Part 3', 'Part 4']);
      expect(parts.last.end, const Duration(seconds: 120));

      // Every slice but the last is the same length; the last absorbs the
      // rounding so the sections still reach the end exactly.
      final first = parts.first.length.inMilliseconds;
      expect(parts[1].length.inMilliseconds, closeTo(first, 2));
      expect(parts[2].length.inMilliseconds, closeTo(first, 2));
    });

    test('a non-positive count produces nothing', () {
      expect(SongSegmenter.splitEvenly(const Duration(minutes: 2), 0), isEmpty);
      expect(
          SongSegmenter.splitEvenly(const Duration(minutes: 2), -3), isEmpty);
    });
  });

  group('TimedPart.contains', () {
    test('claims its own span and not the next part\'s first instant', () {
      const part = TimedPart(
        part: oneLine,
        start: Duration(seconds: 10),
        end: Duration(seconds: 20),
      );

      expect(part.contains(const Duration(seconds: 10)), isTrue);
      expect(part.contains(const Duration(seconds: 19)), isTrue);
      expect(part.contains(const Duration(seconds: 20)), isFalse,
          reason: 'the end is exclusive, or two parts claim the same moment');
      expect(part.contains(const Duration(seconds: 9)), isFalse);
    });
  });
}
