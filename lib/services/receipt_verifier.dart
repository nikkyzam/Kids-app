import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';

/// A purchase as the store handed it to us, in the form the verifier needs.
///
/// Persisted so a purchase can be re-checked on a later launch without asking
/// the store again — the token is what the server needs, and it is not a
/// secret beyond this device.
@immutable
class PurchaseReceipt {
  /// 'android' or 'ios'.
  final String platform;
  final String productId;
  final String token;
  final bool isSubscription;

  const PurchaseReceipt({
    required this.platform,
    required this.productId,
    required this.token,
    required this.isSubscription,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'productId': productId,
        'token': token,
        'subscription': isSubscription,
      };

  static PurchaseReceipt? fromJson(Map<String, dynamic> json) {
    final platform = json['platform'];
    final productId = json['productId'];
    final token = json['token'];
    if (platform is! String || productId is! String || token is! String) {
      return null;
    }
    return PurchaseReceipt(
      platform: platform,
      productId: productId,
      token: token,
      isSubscription: json['subscription'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PurchaseReceipt &&
      other.platform == platform &&
      other.productId == productId &&
      other.token == token &&
      other.isSubscription == isSubscription;

  @override
  int get hashCode => Object.hash(platform, productId, token, isSubscription);
}

/// What the server said about a receipt.
///
/// Three outcomes, not two. [unavailable] is the one that matters: a rejection
/// is final and costs a parent their purchase, so it must never be inferred
/// from a timeout, a 503, or a verifier that was never configured.
enum ReceiptVerdictKind { valid, invalid, unavailable }

@immutable
class ReceiptVerdict {
  final ReceiptVerdictKind kind;
  final String? reason;

  /// When a subscription lapses, if the store said. Null for a one-time
  /// purchase, which never does.
  final DateTime? expiresAt;

  const ReceiptVerdict._(this.kind, {this.reason, this.expiresAt});

  const ReceiptVerdict.valid({DateTime? expiresAt})
      : this._(ReceiptVerdictKind.valid, expiresAt: expiresAt);

  const ReceiptVerdict.invalid(String reason)
      : this._(ReceiptVerdictKind.invalid, reason: reason);

  const ReceiptVerdict.unavailable([String? reason])
      : this._(ReceiptVerdictKind.unavailable, reason: reason);

  bool get isValid => kind == ReceiptVerdictKind.valid;
  bool get isInvalid => kind == ReceiptVerdictKind.invalid;
  bool get isUnavailable => kind == ReceiptVerdictKind.unavailable;
}

/// Asks a server whether a purchase is real.
abstract class ReceiptVerifier {
  /// Whether verification is configured at all. When false the app runs
  /// exactly as it did before this existed: the local check decides, and
  /// nothing is ever revoked.
  bool get isConfigured;

  Future<ReceiptVerdict> verify(PurchaseReceipt receipt);
}

/// A verifier that is switched off, for builds with no backend configured.
class NullReceiptVerifier implements ReceiptVerifier {
  const NullReceiptVerifier();

  @override
  bool get isConfigured => false;

  @override
  Future<ReceiptVerdict> verify(PurchaseReceipt receipt) async =>
      const ReceiptVerdict.unavailable('no verifier configured');
}

/// Posts receipts to the `verify-purchase` edge function.
class HttpReceiptVerifier implements ReceiptVerifier {
  final http.Client _client;
  final Uri? _endpoint;
  final String _anonKey;
  final Duration timeout;

  HttpReceiptVerifier({
    http.Client? client,
    Uri? endpoint,
    String? anonKey,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? _defaultEndpoint(),
        _anonKey = anonKey ?? SupabaseConfig.anonKey;

  /// The function lives in the same project as sync, so it needs no
  /// configuration of its own beyond what is already there.
  static Uri? _defaultEndpoint() {
    if (!SupabaseConfig.isConfigured) return null;
    return Uri.parse('${SupabaseConfig.url}/functions/v1/verify-purchase');
  }

  @override
  bool get isConfigured => _endpoint != null;

  @override
  Future<ReceiptVerdict> verify(PurchaseReceipt receipt) async {
    final endpoint = _endpoint;
    if (endpoint == null) {
      return const ReceiptVerdict.unavailable('no verifier configured');
    }

    http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_anonKey',
              'apikey': _anonKey,
            },
            body: jsonEncode(receipt.toJson()),
          )
          .timeout(timeout);
    } on Object catch (e) {
      // Offline, DNS failure, TLS failure, timeout — none of these are
      // evidence that a purchase is fake.
      return ReceiptVerdict.unavailable('$e');
    }

    // Only a 200 carries a verdict. The function answers 503 when it could not
    // reach the store, and that must not cost anyone their purchase.
    if (response.statusCode != 200) {
      return ReceiptVerdict.unavailable('http ${response.statusCode}');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      return const ReceiptVerdict.unavailable('malformed response');
    }

    if (body['valid'] == true) {
      final expiry = body['expiresAt'];
      return ReceiptVerdict.valid(
        expiresAt: expiry is num
            ? DateTime.fromMillisecondsSinceEpoch(expiry.toInt())
            : null,
      );
    }
    return ReceiptVerdict.invalid(
        body['reason'] as String? ?? 'rejected by the store');
  }
}
