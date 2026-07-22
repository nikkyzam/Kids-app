import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

enum SyncStatus { idle, syncing, done, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    if (AuthService.instance.isAvailable) {
      _subscription = AuthService.instance.authStateChanges.listen((_) {
        notifyListeners();
      });
    }
  }

  StreamSubscription<AuthState>? _subscription;

  // ---------------------------------------------------------------------------
  // Auth state pass-throughs
  // ---------------------------------------------------------------------------

  /// Whether cloud sync is configured for this build.
  bool get isSyncAvailable => AuthService.instance.isAvailable;

  bool get isSignedIn => AuthService.instance.isSignedIn;

  User? get currentUser => AuthService.instance.currentUser;

  String get familyId => AuthService.instance.familyId;

  bool get isPartner => AuthService.instance.isPartner;

  // ---------------------------------------------------------------------------
  // Sync status
  // ---------------------------------------------------------------------------

  SyncStatus _syncStatus = SyncStatus.idle;
  String? _lastSyncError;

  SyncStatus get syncStatus => _syncStatus;
  String? get lastSyncError => _lastSyncError;

  void setSyncStatus(SyncStatus status, {String? error}) {
    _syncStatus = status;
    _lastSyncError = error;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
