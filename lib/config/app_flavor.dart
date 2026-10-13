/// Per-app identity for the family of apps built from this codebase.
///
/// Every app shares the same engine (tracker, sync, purchases); what differs
/// is its name, store product IDs and the backend it talks to. The active
/// flavor is chosen at build time:
///
///   flutter run --flavor playsteps --dart-define=APP_FLAVOR=playsteps
///
/// The Android `--flavor` (applicationId, launcher label) and the Dart-side
/// `APP_FLAVOR` must name the same app. `tool/build_app.sh` passes both.
///
/// To add an app: add an entry to [AppFlavor.all], a matching
/// `productFlavors` block in `android/app/build.gradle`, and its secrets.
/// See docs/ADDING_AN_APP.md.
class AppFlavor {
  const AppFlavor({
    required this.id,
    required this.displayName,
    required this.premiumProductId,
    required this.premiumPlusProductId,
  });

  /// Stable lowercase identifier; matches the Android flavor name.
  final String id;

  /// Name shown to parents (window title, launcher label).
  final String displayName;

  /// Store product IDs. Must match App Store Connect / Play Console exactly.
  final String premiumProductId;
  final String premiumPlusProductId;

  static const playsteps = AppFlavor(
    id: 'playsteps',
    displayName: 'PlaySteps',
    premiumProductId: 'playsteps_premium_lifetime',
    premiumPlusProductId: 'playsteps_premium_plus_yearly',
  );

  static const soundsteps = AppFlavor(
    id: 'soundsteps',
    displayName: 'SoundSteps',
    premiumProductId: 'soundsteps_premium_lifetime',
    premiumPlusProductId: 'soundsteps_premium_plus_yearly',
  );

  static const List<AppFlavor> all = [playsteps, soundsteps];

  static const String _selected = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'playsteps',
  );

  /// The flavor this binary was built as. An unknown `APP_FLAVOR` throws
  /// rather than silently shipping one app under another app's identity.
  static final AppFlavor current = byId(_selected);

  static AppFlavor byId(String id) => all.firstWhere(
        (f) => f.id == id,
        orElse: () => throw StateError(
          'Unknown APP_FLAVOR "$id". Known: ${all.map((f) => f.id).join(', ')}',
        ),
      );
}
