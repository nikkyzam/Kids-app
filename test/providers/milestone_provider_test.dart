import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:playsteps/providers/milestone_provider.dart';
import 'package:playsteps/models/milestone.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/data/milestones_data.dart';

Future<ChildProfile> _insertTestProfile() async {
  return DatabaseHelper.instance.insertProfile(
    ChildProfile(name: 'Test', dateOfBirth: DateTime(2024, 1, 1), createdAt: DateTime.now()),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.instance.resetForTesting();
  });

  group('MilestoneProvider — initial state', () {
    test('starts with no achievements and not loading', () {
      final provider = MilestoneProvider();
      expect(provider.achievements, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.filterDomain, isNull);
    });

    test('achievedCount is 0 initially', () {
      final provider = MilestoneProvider();
      expect(provider.achievedCount, 0);
    });

    test('totalCount equals all milestones when no filter', () {
      final provider = MilestoneProvider();
      expect(provider.totalCount, MilestonesData.all.length);
    });
  });

  group('MilestoneProvider — domain filter', () {
    test('setFilter narrows allMilestones to one domain', () {
      final provider = MilestoneProvider();
      provider.setFilter(MilestoneDomain.grossMotor);
      expect(provider.filterDomain, MilestoneDomain.grossMotor);
      expect(
        provider.allMilestones.every((m) => m.domain == MilestoneDomain.grossMotor),
        isTrue,
      );
    });

    test('setFilter(null) restores all milestones', () {
      final provider = MilestoneProvider();
      provider.setFilter(MilestoneDomain.language);
      provider.setFilter(null);
      expect(provider.filterDomain, isNull);
      expect(provider.allMilestones.length, MilestonesData.all.length);
    });

    test('each domain filter returns non-empty results', () {
      final provider = MilestoneProvider();
      for (final domain in MilestoneDomain.values) {
        provider.setFilter(domain);
        expect(provider.allMilestones, isNotEmpty,
            reason: '${domain.label} filter returned no milestones');
      }
    });

    test('ageGroups with filter only includes groups that have matching domain', () {
      final provider = MilestoneProvider();
      provider.setFilter(MilestoneDomain.cognitive);
      final groups = provider.ageGroups;
      expect(groups, isNotEmpty);
      for (final ag in groups) {
        final hasMatch = MilestonesData.forAgeGroup(ag)
            .any((m) => m.domain == MilestoneDomain.cognitive);
        expect(hasMatch, isTrue, reason: 'Age group $ag should have cognitive milestones');
      }
    });
  });

  group('MilestoneProvider — toggle milestones', () {
    test('isAchieved is false before toggling', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      expect(provider.isAchieved('m_2_gm_1'), isFalse);
    });

    test('isAchieved is true after toggling on', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      await provider.toggleMilestone(profile.id!, 'm_2_gm_1');
      expect(provider.isAchieved('m_2_gm_1'), isTrue);
      expect(provider.achievedCount, 1);
    });

    test('isAchieved is false after toggling on then off', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      await provider.toggleMilestone(profile.id!, 'm_2_gm_1');
      await provider.toggleMilestone(profile.id!, 'm_2_gm_1');
      expect(provider.isAchieved('m_2_gm_1'), isFalse);
      expect(provider.achievedCount, 0);
    });

    test('achievedCount increments correctly', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      await provider.toggleMilestone(profile.id!, 'm_2_gm_1');
      await provider.toggleMilestone(profile.id!, 'm_2_la_1');
      await provider.toggleMilestone(profile.id!, 'm_4_se_1');
      expect(provider.achievedCount, 3);
    });

    test('getAchievement returns null before toggling', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);
      expect(provider.getAchievement('m_2_gm_1'), isNull);
    });

    test('getAchievement returns achievement after toggling', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      await provider.toggleMilestone(profile.id!, 'm_2_gm_1');
      final achievement = provider.getAchievement('m_2_gm_1');
      expect(achievement, isNotNull);
      expect(achievement!.milestoneId, 'm_2_gm_1');
      expect(achievement.profileId, profile.id);
    });

    test('achievement date is set to approximately now', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await provider.toggleMilestone(profile.id!, 'm_6_gm_1');
      final after = DateTime.now().add(const Duration(seconds: 1));

      final achievement = provider.getAchievement('m_6_gm_1');
      expect(achievement!.achievedDate.isAfter(before), isTrue);
      expect(achievement.achievedDate.isBefore(after), isTrue);
    });
  });

  group('MilestoneProvider — notes', () {
    test('updateNotes saves a note on an achieved milestone', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      await provider.toggleMilestone(profile.id!, 'm_2_se_1');
      await provider.updateNotes(profile.id!, 'm_2_se_1', 'First smile at grandma!');

      final achievement = provider.getAchievement('m_2_se_1');
      expect(achievement!.notes, 'First smile at grandma!');
    });

    test('updateNotes does nothing if milestone not achieved', () async {
      final profile = await _insertTestProfile();
      final provider = MilestoneProvider();
      await provider.loadForProfile(profile.id!);

      // Should not throw
      await provider.updateNotes(profile.id!, 'm_2_gm_1', 'Note on unachieved');
      expect(provider.getAchievement('m_2_gm_1'), isNull);
    });
  });

  group('MilestoneProvider — persistence', () {
    test('achievements persist across provider reload', () async {
      final profile = await _insertTestProfile();

      final provider1 = MilestoneProvider();
      await provider1.loadForProfile(profile.id!);
      await provider1.toggleMilestone(profile.id!, 'm_2_gm_1');
      await provider1.toggleMilestone(profile.id!, 'm_4_la_1');

      // Create new provider instance and reload
      final provider2 = MilestoneProvider();
      await provider2.loadForProfile(profile.id!);

      expect(provider2.isAchieved('m_2_gm_1'), isTrue);
      expect(provider2.isAchieved('m_4_la_1'), isTrue);
      expect(provider2.achievedCount, 2);
    });
  });
}
