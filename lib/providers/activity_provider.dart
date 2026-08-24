import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/activity_completion.dart';
import '../data/database_helper.dart';
import '../data/activities_data.dart';
import '../services/purchase_service.dart';
import '../utils/clock.dart';

class ActivityProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  PlayActivity? _todayActivity;
  ActivityCompletion? _todayCompletion;
  List<ActivityCompletion> _allCompletions = [];
  bool _isPremium = false;
  bool _isPremiumPlus = false;
  bool _isLoading = false;

  ActivityProvider(this._prefs) {
    _isPremium = _prefs.getBool('is_premium') ?? false;
    _isPremiumPlus = _prefs.getBool('is_premium_plus') ?? false;
  }

  PlayActivity? get todayActivity => _todayActivity;
  ActivityCompletion? get todayCompletion => _todayCompletion;
  List<ActivityCompletion> get allCompletions =>
      List.unmodifiable(_allCompletions);
  bool get isCompleted => _todayCompletion != null;
  bool get isPremium => _isPremium;
  bool get isPremiumPlus => _isPremiumPlus;
  bool get isLoading => _isLoading;
  int get totalCompletions => _allCompletions.length;

  String get todayKey => DateFormat('yyyy-MM-dd').format(Clock.now());

  String _keyFor(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  bool completedOnDay(DateTime day) =>
      _allCompletions.any((c) => c.dateKey == _keyFor(day));

  /// The calendar day before [d].
  ///
  /// Built from date components rather than `subtract(Duration(days: 1))`:
  /// a Duration is exactly 24 hours, but a calendar day is 23 or 25 hours
  /// across a daylight-saving transition, which silently skips or repeats a
  /// date near midnight.
  static DateTime _previousDay(DateTime d) =>
      DateTime(d.year, d.month, d.day - 1);

  int get currentStreak {
    if (_allCompletions.isEmpty) return 0;
    final days = _allCompletions.map((c) => c.dateKey).toSet();
    int streak = 0;
    var day = Clock.today();
    // Allow today to not yet be done without breaking the streak
    if (!days.contains(_keyFor(day))) {
      day = _previousDay(day);
    }
    while (days.contains(_keyFor(day))) {
      streak++;
      day = _previousDay(day);
    }
    return streak;
  }

  int get longestStreak {
    if (_allCompletions.isEmpty) return 0;
    final days = _allCompletions.map((c) => c.dateKey).toSet().toList()..sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < days.length; i++) {
      final prev = DateTime.parse(days[i - 1]);
      final curr = DateTime.parse(days[i]);
      // Compare calendar days, not elapsed hours: across a DST boundary two
      // consecutive dates are 23 hours apart, so `difference().inDays` is 0
      // and the streak would break for every user in a DST timezone.
      final expected = DateTime(prev.year, prev.month, prev.day + 1);
      if (curr.year == expected.year &&
          curr.month == expected.month &&
          curr.day == expected.day) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  Map<SkillCategory, int> get skillCoverage {
    final counts = <SkillCategory, int>{};
    for (final completion in _allCompletions) {
      final activity = ActivitiesData.all
          .where((a) => a.id == completion.activityId)
          .firstOrNull;
      if (activity != null) {
        counts[activity.skillCategory] =
            (counts[activity.skillCategory] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<ActivityCompletion> get recentCompletions {
    final sorted = [..._allCompletions]
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return sorted;
  }

  PlayActivity? activityForCompletion(ActivityCompletion completion) =>
      ActivitiesData.all
          .where((a) => a.id == completion.activityId)
          .firstOrNull;

  Future<void> loadForProfile(int profileId, int ageInWeeks) async {
    _isLoading = true;
    notifyListeners();

    _todayActivity = ActivitiesData.todayActivity(ageInWeeks);
    _allCompletions = await DatabaseHelper.instance.getCompletions(profileId);
    _todayCompletion =
        _allCompletions.where((c) => c.dateKey == todayKey).firstOrNull;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleCompletion(int profileId) async {
    if (_todayActivity == null) return;

    if (isCompleted) {
      await DatabaseHelper.instance.deleteCompletion(profileId, todayKey);
      _allCompletions.removeWhere((c) => c.dateKey == todayKey);
      _todayCompletion = null;
    } else {
      final completion = ActivityCompletion(
        profileId: profileId,
        activityId: _todayActivity!.id,
        dateKey: todayKey,
        completedAt: Clock.now(),
      );
      await DatabaseHelper.instance.saveCompletion(completion);
      _allCompletions.add(completion);
      _todayCompletion = completion;
    }
    notifyListeners();
  }

  bool activityRequiresPremium(PlayActivity activity) =>
      !activity.isInFreeTier && !_isPremium;

  bool get todayRequiresPremium {
    if (_todayActivity == null) return false;
    return activityRequiresPremium(_todayActivity!);
  }

  /// Persists an entitlement confirmed by the store.
  ///
  /// Only [PurchaseService] should call this — it is driven by the platform
  /// purchase stream, so it also covers restores and purchases that finish
  /// while the app was closed. The cached flag is a convenience for offline
  /// launches; the store remains the source of truth and re-confirms on init.
  Future<void> grantEntitlement(Entitlement entitlement) async {
    switch (entitlement) {
      case Entitlement.premium:
        if (_isPremium) return;
        _isPremium = true;
        await _prefs.setBool('is_premium', true);
      case Entitlement.premiumPlus:
        if (_isPremiumPlus) return;
        _isPremiumPlus = true;
        await _prefs.setBool('is_premium_plus', true);
    }
    notifyListeners();
  }

  /// Asks the store to replay past purchases.
  ///
  /// Entitlements arrive asynchronously through [grantEntitlement]; this only
  /// kicks off the request.
  Future<void> restorePurchases() => PurchaseService.instance.restore();
}
