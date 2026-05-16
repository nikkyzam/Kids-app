import 'package:flutter_test/flutter_test.dart';
import 'package:playsteps/data/tips_data.dart';

void main() {
  group('TipsData.all', () {
    test('contains tips', () {
      expect(TipsData.all, isNotEmpty);
    });

    test('all tips are non-empty strings', () {
      for (final tip in TipsData.all) {
        expect(tip.trim(), isNotEmpty);
      }
    });

    test('all tips are at least 20 characters long', () {
      for (final tip in TipsData.all) {
        expect(tip.length, greaterThanOrEqualTo(20),
            reason: 'Tip is too short: "$tip"');
      }
    });

    test('contains at least 30 tips for good daily variety', () {
      expect(TipsData.all.length, greaterThanOrEqualTo(30));
    });
  });

  group('TipsData.forToday', () {
    test('returns a non-empty string', () {
      expect(TipsData.forToday(), isNotEmpty);
    });

    test('returned tip is in the all list', () {
      final today = TipsData.forToday();
      expect(TipsData.all, contains(today));
    });

    test('is deterministic within the same day', () {
      final first = TipsData.forToday();
      final second = TipsData.forToday();
      expect(first, equals(second));
    });
  });
}
