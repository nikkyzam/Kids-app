class SupabaseConfig {
  // Credentials can be injected at build time (recommended — keeps secrets out
  // of source control):
  //   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  // or by replacing the placeholder default values below.
  //   Dashboard → Project Settings → API
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  /// Whether real Supabase credentials have been supplied.
  ///
  /// PlaySteps is offline-first: when this is `false` the app runs entirely
  /// on-device and every cloud-sync feature is disabled gracefully, rather than
  /// crashing at startup on the placeholder values above.
  static bool get isConfigured {
    final hasValidUrl = url.startsWith('http') && !url.contains('YOUR_SUPABASE');
    final hasValidKey = anonKey.isNotEmpty && !anonKey.contains('YOUR_SUPABASE');
    return hasValidUrl && hasValidKey;
  }
}
