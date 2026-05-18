import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Auth state helpers
  // ---------------------------------------------------------------------------

  bool get isSignedIn => _client.auth.currentUser != null;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Family helpers
  // ---------------------------------------------------------------------------

  /// Returns the family owner's user_id if this user is a partner,
  /// otherwise returns this user's own user_id.
  String get familyId {
    final metadata = currentUser?.userMetadata;
    if (metadata != null && metadata.containsKey('family_owner')) {
      return metadata['family_owner'] as String;
    }
    return currentUser?.id ?? '';
  }

  /// True when the signed-in user joined someone else's family.
  bool get isPartner {
    final metadata = currentUser?.userMetadata;
    return metadata != null && metadata.containsKey('family_owner');
  }

  // ---------------------------------------------------------------------------
  // Sign-in / sign-out
  // ---------------------------------------------------------------------------

  /// Sends a magic-link / OTP to the given email address.
  Future<void> signInWithEmail(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: null,
    );
  }

  /// Verifies the 6-digit OTP received by email.
  Future<AuthResponse> verifyOtp(String email, String token) async {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Family management
  // ---------------------------------------------------------------------------

  /// Creates (or updates) a row in the `families` table for the current user
  /// and returns a freshly generated 6-character invite code.
  Future<String> createFamily() async {
    final userId = currentUser!.id;
    final code = _generateCode();

    await _client.from('families').upsert({
      'owner_id': userId,
      'invite_code': code,
    });

    return code;
  }

  /// Returns the invite code for the current user's family, or null if none.
  Future<String?> getMyInviteCode() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('families')
        .select('invite_code')
        .eq('owner_id', userId)
        .maybeSingle();

    return response?['invite_code'] as String?;
  }

  /// Looks up the family by invite code and stores the owner's id in the
  /// current user's metadata. Returns true on success.
  Future<bool> joinFamily(String code) async {
    final response = await _client
        .from('families')
        .select('owner_id')
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();

    if (response == null) return false;

    final ownerId = response['owner_id'] as String;

    await _client.auth.updateUser(
      UserAttributes(data: {'family_owner': ownerId}),
    );

    return true;
  }

  /// Removes the `family_owner` key from the current user's metadata.
  Future<void> leaveFamily() async {
    await _client.auth.updateUser(
      UserAttributes(data: {'family_owner': null}),
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateCode() {
    final seed = DateTime.now().millisecondsSinceEpoch;
    final rng = Random(seed);
    return List.generate(6, (_) => _codeChars[rng.nextInt(_codeChars.length)])
        .join();
  }
}
