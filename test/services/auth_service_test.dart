import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/config/supabase_config.dart';
import 'package:playsteps/services/auth_service.dart';

void main() {
  group('SupabaseConfig', () {
    test('is not configured with placeholder credentials', () {
      // A default build supplies no --dart-define values, so sync stays off and
      // the app runs fully offline instead of crashing at startup.
      expect(SupabaseConfig.isConfigured, isFalse);
    });
  });

  group('AuthService (offline-first, no Supabase configured)', () {
    final auth = AuthService.instance;

    test('reports sync as unavailable', () {
      expect(auth.isAvailable, isFalse);
    });

    test('read accessors are safe and never touch an uninitialized client', () {
      // None of these may throw even though Supabase.initialize was never called.
      expect(auth.isSignedIn, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.familyId, '');
      expect(auth.isPartner, isFalse);
      expect(auth.authStateChanges, isA<Stream>());
    });

    test('mutating actions throw a clear SyncUnavailableException', () {
      expect(
        auth.signInWithEmail('parent@example.com'),
        throwsA(isA<SyncUnavailableException>()),
      );
      expect(
        auth.joinFamily('ABC123'),
        throwsA(isA<SyncUnavailableException>()),
      );
      expect(auth.createFamily(), throwsA(isA<SyncUnavailableException>()));
      expect(auth.leaveFamily(), throwsA(isA<SyncUnavailableException>()));
    });
  });
}
