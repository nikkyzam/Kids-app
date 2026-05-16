import 'package:flutter/foundation.dart';

import '../models/milestone.dart';
import '../models/milestone_achievement.dart';
import '../data/database_helper.dart';
import '../data/milestones_data.dart';

class MilestoneProvider extends ChangeNotifier {
  List<MilestoneAchievement> _achievements = [];
  MilestoneDomain? _filterDomain;
  bool _isLoading = false;

  List<MilestoneAchievement> get achievements => _achievements;
  MilestoneDomain? get filterDomain => _filterDomain;
  bool get isLoading => _isLoading;

  List<Milestone> get allMilestones => MilestonesData.filterByDomain(
        MilestonesData.all,
        _filterDomain,
      );

  List<int> get ageGroups {
    if (_filterDomain == null) return MilestonesData.ageGroups;
    return MilestonesData.ageGroups
        .where((ag) => MilestonesData.forAgeGroup(ag).any((m) => m.domain == _filterDomain))
        .toList();
  }

  Future<void> loadForProfile(int profileId) async {
    _isLoading = true;
    notifyListeners();

    _achievements = await DatabaseHelper.instance.getAchievements(profileId);

    _isLoading = false;
    notifyListeners();
  }

  bool isAchieved(String milestoneId) =>
      _achievements.any((a) => a.milestoneId == milestoneId);

  MilestoneAchievement? getAchievement(String milestoneId) =>
      _achievements.where((a) => a.milestoneId == milestoneId).firstOrNull;

  Future<void> toggleMilestone(int profileId, String milestoneId) async {
    if (isAchieved(milestoneId)) {
      await DatabaseHelper.instance.deleteAchievement(profileId, milestoneId);
      _achievements.removeWhere((a) => a.milestoneId == milestoneId);
    } else {
      final achievement = MilestoneAchievement(
        profileId: profileId,
        milestoneId: milestoneId,
        achievedDate: DateTime.now(),
      );
      await DatabaseHelper.instance.saveAchievement(achievement);
      _achievements.add(achievement);
    }
    notifyListeners();
  }

  Future<void> updateNotes(int profileId, String milestoneId, String notes) async {
    final existing = getAchievement(milestoneId);
    if (existing == null) return;
    final updated = existing.copyWith(notes: notes);
    await DatabaseHelper.instance.saveAchievement(updated);
    final idx = _achievements.indexWhere((a) => a.milestoneId == milestoneId);
    if (idx != -1) _achievements[idx] = updated;
    notifyListeners();
  }

  void setFilter(MilestoneDomain? domain) {
    _filterDomain = domain;
    notifyListeners();
  }

  int get achievedCount => _achievements.length;
  int get totalCount => MilestonesData.all.length;
}
