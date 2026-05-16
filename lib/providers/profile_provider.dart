import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';
import '../data/database_helper.dart';

class ProfileProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  List<ChildProfile> _profiles = [];
  ChildProfile? _activeProfile;
  bool _isLoading = true;

  ProfileProvider(this._prefs);

  List<ChildProfile> get profiles => _profiles;
  ChildProfile? get activeProfile => _activeProfile;
  bool get isLoading => _isLoading;
  bool get canAddMore => _profiles.length < 3;

  Future<void> loadProfiles() async {
    _isLoading = true;
    notifyListeners();

    _profiles = await DatabaseHelper.instance.getProfiles();
    final savedId = _prefs.getInt('active_profile_id');
    if (savedId != null) {
      _activeProfile = _profiles.where((p) => p.id == savedId).firstOrNull;
    }
    _activeProfile ??= _profiles.firstOrNull;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProfile(ChildProfile profile) async {
    if (!canAddMore) return;
    final saved = await DatabaseHelper.instance.insertProfile(profile);
    _profiles.add(saved);
    await setActiveProfile(saved);
  }

  Future<void> setActiveProfile(ChildProfile profile) async {
    _activeProfile = profile;
    await _prefs.setInt('active_profile_id', profile.id!);
    notifyListeners();
  }

  Future<void> updateProfile(ChildProfile profile) async {
    await DatabaseHelper.instance.updateProfile(profile);
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) _profiles[idx] = profile;
    if (_activeProfile?.id == profile.id) _activeProfile = profile;
    notifyListeners();
  }

  Future<void> deleteProfile(ChildProfile profile) async {
    await DatabaseHelper.instance.deleteProfile(profile.id!);
    _profiles.removeWhere((p) => p.id == profile.id);
    if (_activeProfile?.id == profile.id) {
      _activeProfile = _profiles.firstOrNull;
      if (_activeProfile != null) {
        await _prefs.setInt('active_profile_id', _activeProfile!.id!);
      } else {
        await _prefs.remove('active_profile_id');
      }
    }
    notifyListeners();
  }
}
