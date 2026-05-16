import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/activity_completion.dart';
import '../data/database_helper.dart';
import '../data/activities_data.dart';

class ActivityProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  PlayActivity? _todayActivity;
  ActivityCompletion? _todayCompletion;
  bool _isPremium = false;
  bool _isLoading = false;

  ActivityProvider(this._prefs) {
    _isPremium = _prefs.getBool('is_premium') ?? false;
  }

  PlayActivity? get todayActivity => _todayActivity;
  ActivityCompletion? get todayCompletion => _todayCompletion;
  bool get isCompleted => _todayCompletion != null;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;

  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> loadForProfile(int profileId, int ageInWeeks) async {
    _isLoading = true;
    notifyListeners();

    _todayActivity = ActivitiesData.todayActivity(ageInWeeks);
    _todayCompletion = await DatabaseHelper.instance.getCompletion(profileId, todayKey);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleCompletion(int profileId) async {
    if (_todayActivity == null) return;

    if (isCompleted) {
      await DatabaseHelper.instance.deleteCompletion(profileId, todayKey);
      _todayCompletion = null;
    } else {
      final completion = ActivityCompletion(
        profileId: profileId,
        activityId: _todayActivity!.id,
        dateKey: todayKey,
        completedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.saveCompletion(completion);
      _todayCompletion = completion;
    }
    notifyListeners();
  }

  bool activityRequiresPremium(PlayActivity activity) {
    return !activity.isInFreeTier && !_isPremium;
  }

  bool get todayRequiresPremium {
    if (_todayActivity == null) return false;
    return activityRequiresPremium(_todayActivity!);
  }

  Future<void> unlockPremium() async {
    _isPremium = true;
    await _prefs.setBool('is_premium', true);
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    // In production: call StoreKit / Google Play restore API
    // For now this is a placeholder
    _isPremium = _prefs.getBool('is_premium') ?? false;
    notifyListeners();
  }
}
