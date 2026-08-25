import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:playsteps/services/auth_service.dart';

/// A stand-in for [AuthService] that reports a configured, signed-in session
/// without touching Supabase, so the screens gated behind one can be tested.
///
/// Every method records that it was called and returns a canned result; none
/// of them reach the network.
class FakeAuthService extends AuthService {
  FakeAuthService({
    this.available = true,
    this.signedIn = true,
    this.partner = false,
    this.family = 'fam-1',
    this.inviteCode = 'ABC123',
    this.joinSucceeds = true,
    this.throwOn,
  });

  bool available;
  bool signedIn;
  bool partner;
  String family;
  String? inviteCode;
  bool joinSucceeds;

  /// Name of a method that should throw, to exercise error handling.
  String? throwOn;

  final List<String> calls = [];

  final _authEvents = StreamController<AuthState>.broadcast();

  void _record(String name) {
    calls.add(name);
    if (throwOn == name) throw Exception('$name failed');
  }

  @override
  bool get isAvailable => available;

  @override
  bool get isSignedIn => available && signedIn;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => _authEvents.stream;

  @override
  String get familyId => family;

  @override
  bool get isPartner => partner;

  @override
  Future<void> signInWithEmail(String email) async =>
      _record('signInWithEmail');

  @override
  Future<AuthResponse> verifyOtp(String email, String token) async {
    _record('verifyOtp');
    return AuthResponse();
  }

  @override
  Future<void> signOut() async {
    _record('signOut');
    signedIn = false;
  }

  @override
  Future<String> createFamily() async {
    _record('createFamily');
    inviteCode = 'NEW456';
    return inviteCode!;
  }

  @override
  Future<String?> getMyInviteCode() async {
    _record('getMyInviteCode');
    return inviteCode;
  }

  @override
  Future<bool> joinFamily(String code) async {
    _record('joinFamily');
    return joinSucceeds;
  }

  @override
  Future<void> leaveFamily() async {
    _record('leaveFamily');
    partner = false;
  }

  void dispose() => _authEvents.close();
}
