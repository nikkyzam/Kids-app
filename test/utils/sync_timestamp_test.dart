import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/utils/clock.dart';
import 'package:playsteps/utils/sync_timestamp.dart';

/// Last-write-wins is only correct if "later" is measured on an absolute
/// timeline. These cover the cases where naive string comparison of
/// `updated_at` picked the wrong winner and silently discarded an edit.
void main() {
  group('SyncTimestamp.now', () {
    test('is written in UTC', () {
      final value = SyncTimestamp.now();
      expect(value, endsWith('Z'),
          reason: 'a timestamp without a zone is ambiguous across devices');
      expect(DateTime.parse(value).isUtc, isTrue);
    });
  });

  group('isRemoteNewer across timezones', () {
    test('a later edit further west still wins', () {
      // Device A (UTC+10) edits at 23:00Z; device B (UTC-5) edits 30 minutes
      // later at 23:30Z. Comparing wall-clock text would rank A above B.
      final a = SyncTimestamp.from(DateTime.utc(2026, 5, 20, 23, 0));
      final b = SyncTimestamp.from(DateTime.utc(2026, 5, 20, 23, 30));

      expect(SyncTimestamp.isRemoteNewer(b, a), isTrue);
      expect(SyncTimestamp.isRemoteNewer(a, b), isFalse);
    });

    test('an explicit offset is normalised before comparing', () {
      // Same instant expressed two ways: neither is newer than the other.
      const utc = '2026-05-20T18:30:00.000Z';
      const plusTen = '2026-05-21T04:30:00.000+10:00';

      expect(SyncTimestamp.isRemoteNewer(plusTen, utc), isFalse);
      expect(SyncTimestamp.isRemoteNewer(utc, plusTen), isFalse);
    });

    test('a legacy zone-less local timestamp remains comparable', () {
      // Rows written before timestamps were normalised have no Z. They meant
      // local time, so they must still be interpreted that way.
      final legacyLocal = DateTime(2026, 5, 20, 12, 0).toIso8601String();
      final laterUtc = SyncTimestamp.from(
        DateTime(2026, 5, 20, 12, 0).add(const Duration(hours: 1)),
      );

      expect(legacyLocal, isNot(endsWith('Z')));
      expect(SyncTimestamp.isRemoteNewer(laterUtc, legacyLocal), isTrue);
    });
  });

  group('isRemoteNewer edge cases', () {
    test('identical timestamps are not newer', () {
      const t = '2026-05-20T18:30:00.000Z';
      expect(SyncTimestamp.isRemoteNewer(t, t), isFalse,
          reason: 'equal timestamps must not cause a redundant overwrite');
    });

    test('sub-second differences are respected', () {
      const earlier = '2026-05-20T18:30:00.100Z';
      const later = '2026-05-20T18:30:00.200Z';
      expect(SyncTimestamp.isRemoteNewer(later, earlier), isTrue);
    });

    test('a missing local timestamp lets the remote win', () {
      expect(SyncTimestamp.isRemoteNewer('2026-05-20T18:30:00.000Z', null),
          isTrue);
      expect(
          SyncTimestamp.isRemoteNewer('2026-05-20T18:30:00.000Z', ''), isTrue);
    });

    test('a missing or malformed remote never overwrites local data', () {
      const local = '2026-05-20T18:30:00.000Z';
      expect(SyncTimestamp.isRemoteNewer(null, local), isFalse);
      expect(SyncTimestamp.isRemoteNewer('', local), isFalse);
      expect(SyncTimestamp.isRemoteNewer('not-a-date', local), isFalse);
      expect(
          SyncTimestamp.isRemoteNewer('2026-13-45T99:99:99Z', local), isFalse,
          reason: 'corrupt remote data must not clobber a good local row');
    });

    test('both missing resolves to not-newer', () {
      expect(SyncTimestamp.isRemoteNewer(null, null), isFalse);
    });

    test('parse returns null rather than throwing on rubbish', () {
      expect(SyncTimestamp.parse('nonsense'), isNull);
      expect(SyncTimestamp.parse(null), isNull);
      expect(SyncTimestamp.parse(''), isNull);
    });

    test('an out-of-range date does not become a far-future timestamp', () {
      // DateTime.tryParse rolls these over instead of rejecting them:
      // 2026-13-45T99:99:99Z parses as 2027-02-18.
      expect(DateTime.tryParse('2026-13-45T99:99:99Z'), isNotNull,
          reason: 'documents the tryParse behaviour being guarded against');
      expect(SyncTimestamp.parse('2026-13-45T99:99:99Z'), isNull);
    });

    test('a timestamp beyond the tolerated clock skew is rejected', () {
      Clock.freeze(DateTime.utc(2026, 5, 20, 12, 0));
      addTearDown(Clock.reset);

      final farFuture = SyncTimestamp.from(DateTime.utc(2027, 1, 1));
      expect(SyncTimestamp.parse(farFuture), isNull);
    });

    test('a small clock skew between devices is still accepted', () {
      Clock.freeze(DateTime.utc(2026, 5, 20, 12, 0));
      addTearDown(Clock.reset);

      // A co-parent's phone running an hour fast must not have its edits
      // silently dropped.
      final slightlyAhead =
          SyncTimestamp.from(DateTime.utc(2026, 5, 20, 13, 0));
      expect(SyncTimestamp.parse(slightlyAhead), isNotNull);
      expect(
        SyncTimestamp.isRemoteNewer(
          slightlyAhead,
          SyncTimestamp.from(DateTime.utc(2026, 5, 20, 11, 0)),
        ),
        isTrue,
      );
    });

    test('comparison holds across a year boundary', () {
      // Frozen just after New Year so both timestamps are in the past and the
      // clock-skew guard does not reject them.
      Clock.freeze(DateTime.utc(2027, 1, 2));
      addTearDown(Clock.reset);

      final dec = SyncTimestamp.from(DateTime.utc(2026, 12, 31, 23, 59));
      final jan = SyncTimestamp.from(DateTime.utc(2027, 1, 1, 0, 1));
      expect(SyncTimestamp.isRemoteNewer(jan, dec), isTrue);
    });
  });
}
