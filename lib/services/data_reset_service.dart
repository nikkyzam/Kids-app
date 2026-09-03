import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import 'photo_storage.dart';

/// Returns the app to a fresh install.
///
/// Ordered deliberately: photo *files* are removed before the rows that name
/// them, so a failure part-way leaves rows pointing at missing files — which
/// the timeline already handles and explains — rather than orphaned files with
/// nothing left to find or delete them.
class DataResetService {
  DataResetService._();

  /// Preference keys that survive a wipe.
  ///
  /// Entitlements are not data the parent entered; they record a purchase. The
  /// store is the source of truth and re-confirms on launch, but keeping the
  /// cached flags means a paying parent who wipes their data on a plane is not
  /// locked out of what they bought until they are back online.
  static const Set<String> keptPreferences = {
    'is_premium',
    'is_premium_plus',
  };

  /// Returns true when the photo files went too.
  ///
  /// The records are wiped either way. A parent who asks to delete everything
  /// is better served by losing their records and keeping some inert image
  /// files than by an all-or-nothing failure that deletes neither — so the
  /// file sweep is attempted first, its failure is reported rather than
  /// thrown, and the database and preferences are cleared regardless.
  static Future<bool> deleteEverything() async {
    bool photosDeleted = true;
    try {
      await PhotoStorage.deleteAll();
    } catch (_) {
      photosDeleted = false;
    }

    await DatabaseHelper.instance.wipeAllData();

    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toSet()) {
      if (keptPreferences.contains(key)) continue;
      await prefs.remove(key);
    }
    return photosDeleted;
  }
}
