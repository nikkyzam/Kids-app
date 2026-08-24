import 'package:flutter/foundation.dart';

import '../data/badges_data.dart';
import '../data/database_helper.dart';
import '../models/activity.dart';
import '../models/badge_definition.dart';
import '../providers/activity_provider.dart';
import '../providers/milestone_provider.dart';

class BadgeProvider extends ChangeNotifier {
  List<String> _unlockedIds = [];

  int get unlockedCount => _unlockedIds.length;
  int get totalCount => BadgesData.all.length;

  bool isUnlocked(String id) => _unlockedIds.contains(id);

  Future<void> loadBadges(int profileId) async {
    _unlockedIds = await DatabaseHelper.instance.getUnlockedBadgeIds(profileId);
    notifyListeners();
  }

  /// Checks all badge conditions and unlocks any newly earned ones.
  /// Returns the list of newly unlocked BadgeDefinitions (so caller can show dialogs).
  Future<List<BadgeDefinition>> checkAndUnlock({
    required int profileId,
    required ActivityProvider ap,
    required MilestoneProvider mp,
  }) async {
    final newly = <BadgeDefinition>[];

    Future<void> tryUnlock(String id) async {
      if (_unlockedIds.contains(id)) return;
      final def = BadgesData.findById(id);
      if (def == null) return;
      await DatabaseHelper.instance.saveBadge(profileId, id);
      _unlockedIds = [..._unlockedIds, id];
      newly.add(def);
    }

    final completions = ap.recentCompletions;
    final total = completions.length;
    final streak = ap.currentStreak;
    final coverage = ap.skillCoverage;
    final achievedCount = mp.achievedCount;

    if (total >= 1) await tryUnlock('first_step');
    if (streak >= 7) await tryUnlock('week_warrior');
    if (streak >= 30) await tryUnlock('monthly_marvel');
    if (total >= 100) await tryUnlock('century');
    if (coverage.length >= 6) await tryUnlock('all_skills');
    if (achievedCount >= 1) await tryUnlock('milestone_first');
    if (achievedCount >= 25) await tryUnlock('milestone_25');

    // Perfect week: Mon–Sun all completed
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final isPerfect = List.generate(7, (i) => weekStart.add(Duration(days: i)))
        .every((day) => ap.completedOnDay(day));
    if (isPerfect) await tryUnlock('perfect_week');

    // Per-skill counts
    final skillCount = <SkillCategory, int>{};
    for (final completion in completions) {
      final activity = ap.activityForCompletion(completion);
      if (activity != null) {
        skillCount[activity.skillCategory] =
            (skillCount[activity.skillCategory] ?? 0) + 1;
      }
    }
    if ((skillCount[SkillCategory.grossMotor] ?? 0) >= 10) {
      await tryUnlock('gross_motor_10');
    }
    if ((skillCount[SkillCategory.language] ?? 0) >= 10) {
      await tryUnlock('language_10');
    }
    if ((skillCount[SkillCategory.cognitive] ?? 0) >= 10) {
      await tryUnlock('cognitive_10');
    }
    if ((skillCount[SkillCategory.socialEmotional] ?? 0) >= 10) {
      await tryUnlock('social_10');
    }
    if ((skillCount[SkillCategory.sensory] ?? 0) >= 10) {
      await tryUnlock('sensory_10');
    }
    if ((skillCount[SkillCategory.fineMotor] ?? 0) >= 10) {
      await tryUnlock('fine_motor_10');
    }

    if (newly.isNotEmpty) notifyListeners();
    return newly;
  }
}
