import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/clock.dart';
import 'purchase_service.dart';
import 'receipt_verifier.dart';

/// What the app knows about each entitlement it has granted: the receipt that
/// bought it, and when a server last confirmed it.
///
/// This exists so a purchase granted offline can be checked later. Without it
/// the receipt is gone the moment the store's stream delivers it, and the only
/// options left are to trust the device forever or to demand connectivity at
/// the till.
class EntitlementLedger {
  final SharedPreferences _prefs;

  const EntitlementLedger(this._prefs);

  /// How long a confirmed entitlement is trusted before it is checked again.
  ///
  /// A week, not a day: re-checking is for catching refunds, chargebacks and
  /// lapsed subscriptions, none of which are urgent, and every check is a
  /// network call a parent did not ask for.
  static const Duration reverifyAfter = Duration(days: 7);

  static String _receiptKey(Entitlement e) => 'receipt_${e.name}';
  static String _verifiedKey(Entitlement e) => 'receipt_verified_at_${e.name}';
  static String _expiryKey(Entitlement e) => 'receipt_expires_at_${e.name}';

  PurchaseReceipt? receiptFor(Entitlement entitlement) {
    final raw = _prefs.getString(_receiptKey(entitlement));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return PurchaseReceipt.fromJson(json);
    } on FormatException {
      // A corrupt record must not take the launch down; it simply means this
      // entitlement cannot be re-checked until the store re-delivers it.
      return null;
    }
  }

  DateTime? lastVerifiedAt(Entitlement entitlement) {
    final raw = _prefs.getString(_verifiedKey(entitlement));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  DateTime? expiresAt(Entitlement entitlement) {
    final raw = _prefs.getString(_expiryKey(entitlement));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Records the receipt behind a grant, and what the server made of it.
  Future<void> record(
    Entitlement entitlement,
    PurchaseReceipt receipt,
    ReceiptVerdict verdict,
  ) async {
    await _prefs.setString(
        _receiptKey(entitlement), jsonEncode(receipt.toJson()));

    if (verdict.isValid) {
      await _prefs.setString(
          _verifiedKey(entitlement), Clock.now().toIso8601String());
    } else {
      // An unverified grant keeps no timestamp, so it is first in line to be
      // checked rather than trusted for a week on the strength of an outage.
      await _prefs.remove(_verifiedKey(entitlement));
    }

    final expiry = verdict.expiresAt;
    if (expiry != null) {
      await _prefs.setString(_expiryKey(entitlement), expiry.toIso8601String());
    } else {
      await _prefs.remove(_expiryKey(entitlement));
    }
  }

  Future<void> clear(Entitlement entitlement) async {
    await _prefs.remove(_receiptKey(entitlement));
    await _prefs.remove(_verifiedKey(entitlement));
    await _prefs.remove(_expiryKey(entitlement));
  }

  /// Whether [entitlement] is due a check.
  ///
  /// True when it has never been confirmed, when the last confirmation has
  /// aged out, or when a subscription's known expiry has passed. False when
  /// there is no receipt to check — an entitlement granted before this
  /// existed, or by a build with no verifier, is left alone rather than
  /// revoked for lack of evidence.
  bool isDueForCheck(Entitlement entitlement) {
    if (receiptFor(entitlement) == null) return false;

    final expiry = expiresAt(entitlement);
    if (expiry != null && !Clock.now().isBefore(expiry)) return true;

    final verified = lastVerifiedAt(entitlement);
    if (verified == null) return true;

    // A timestamp in the future means the device clock moved; treat it as due
    // rather than trusting it indefinitely.
    if (verified.isAfter(Clock.now())) return true;

    return Clock.now().difference(verified) >= reverifyAfter;
  }
}
