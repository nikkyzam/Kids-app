import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entitlement_ledger.dart';
import 'receipt_verifier.dart';

/// Thrown when a store operation cannot be completed.
class PurchaseUnavailableException implements Exception {
  final String message;
  const PurchaseUnavailableException(this.message);

  @override
  String toString() => message;
}

/// The entitlements PlaySteps sells.
enum Entitlement {
  /// One-time purchase unlocking the full activity library.
  premium,

  /// Yearly subscription adding the Premium Plus feature set.
  premiumPlus,
}

/// Wraps StoreKit / Google Play Billing behind a small API.
///
/// Purchases are delivered asynchronously by the platform — including ones that
/// complete after the app was killed — so entitlements are granted through the
/// [onEntitlement] callback rather than as a return value from [buy].
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// Store product identifiers. These must match the products configured in
  /// App Store Connect and the Google Play Console exactly, or the store
  /// returns them as "not found" and purchasing is disabled.
  static const String premiumProductId = 'playsteps_premium_lifetime';
  static const String premiumPlusProductId = 'playsteps_premium_plus_yearly';

  static const Set<String> _productIds = {
    premiumProductId,
    premiumPlusProductId,
  };

  /// Resolved lazily: touching `InAppPurchase.instance` registers the platform
  /// implementation and opens a billing connection, so it must not happen just
  /// because something referenced this singleton (e.g. to read a price).
  InAppPurchase get _iap => InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = const [];
  bool _available = false;

  /// Whether the store is reachable and the products resolved.
  bool get isAvailable => _available;

  /// Store-localised product listings (price, title, currency).
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Called when the store confirms an entitlement, including restores and
  /// purchases that complete while the app was closed.
  void Function(Entitlement entitlement)? onEntitlement;

  /// Called when a receipt the app previously accepted is rejected by the
  /// store — a refund, a chargeback, a lapsed subscription, or a purchase that
  /// was never real.
  void Function(Entitlement entitlement)? onEntitlementRevoked;

  /// Called when a purchase fails or is cancelled, so the UI can stop spinning.
  void Function(String message)? onError;

  /// Asks a server whether a receipt is genuine. Left as the null verifier
  /// when no backend is configured, in which case the local check decides and
  /// nothing is ever revoked — the behaviour before validation existed.
  ReceiptVerifier verifier = const NullReceiptVerifier();

  EntitlementLedger? _ledger;

  @visibleForTesting
  set ledgerForTesting(EntitlementLedger? ledger) => _ledger = ledger;

  Future<EntitlementLedger> _ledgerInstance() async =>
      _ledger ??= EntitlementLedger(await SharedPreferences.getInstance());

  /// Connects to the store and begins listening for purchase updates.
  ///
  /// Safe to call on every launch. On web (and anywhere the store is missing)
  /// this leaves [isAvailable] false and the paywalls degrade to an explanatory
  /// message rather than throwing.
  Future<void> init() async {
    if (kIsWeb) return; // No store on web; paywall shows an unavailable state.

    try {
      _available = await _iap.isAvailable();
    } on Exception {
      _available = false;
    }
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => onError?.call('Store connection lost: $e'),
    );

    // Before anything else the store might say: re-check what we already
    // granted. A refund or a lapsed subscription arrives no other way.
    unawaited(reverifyStoredEntitlements());

    final response = await _iap.queryProductDetails(_productIds);
    _products = response.productDetails;

    // A product missing here almost always means it is not yet configured (or
    // not yet approved) in the store console.
    if (response.notFoundIDs.isNotEmpty) {
      onError?.call(
        'Products unavailable: ${response.notFoundIDs.join(', ')}',
      );
    }
    if (_products.isEmpty) _available = false;
  }

  /// Releases the purchase stream subscription.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  ProductDetails? _productFor(Entitlement entitlement) {
    final id = entitlement == Entitlement.premium
        ? premiumProductId
        : premiumPlusProductId;
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The store-localised price (e.g. "$4.99", "€4,99"), or null if unresolved.
  ///
  /// Prefer this over a hard-coded price: stores localise currency and Apple
  /// rejects builds whose displayed price disagrees with the product's.
  String? priceFor(Entitlement entitlement) => _productFor(entitlement)?.price;

  /// Starts the platform purchase flow.
  ///
  /// Returns once the sheet has been presented — the entitlement itself arrives
  /// later via [onEntitlement].
  Future<void> buy(Entitlement entitlement) async {
    if (!_available) {
      throw const PurchaseUnavailableException(
        'The store is not available on this device right now.',
      );
    }
    final product = _productFor(entitlement);
    if (product == null) {
      throw const PurchaseUnavailableException(
        'That product is not available for purchase right now.',
      );
    }

    final param = PurchaseParam(productDetails: product);
    if (entitlement == Entitlement.premium) {
      // Lifetime unlock — non-consumable, owned forever once bought.
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      // Subscriptions also go through buyNonConsumable in in_app_purchase.
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  /// Asks the store to replay past purchases.
  ///
  /// Results arrive through [onEntitlement]. Required by App Store review for
  /// any app selling non-consumables.
  Future<void> restore() async {
    if (!_available) {
      throw const PurchaseUnavailableException(
        'The store is not available on this device right now.',
      );
    }
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.error:
          onError?.call(purchase.error?.message ?? 'The purchase failed.');
          break;

        case PurchaseStatus.canceled:
          onError?.call('Purchase cancelled.');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (await _isValid(purchase)) {
            onEntitlement?.call(_entitlementFor(purchase.productID));
          } else {
            onError?.call('That purchase could not be verified.');
          }
          break;
      }

      // The store re-delivers any purchase that is never completed, so this
      // must run for failed purchases too.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Re-checks every entitlement whose receipt is due, revoking any the store
  /// now rejects.
  ///
  /// Only an explicit rejection revokes. An unreachable server, a 503, or a
  /// build with no verifier configured all leave the entitlement exactly as it
  /// was — the parent keeps what they paid for, and the check happens again
  /// next launch.
  Future<void> reverifyStoredEntitlements() async {
    if (!verifier.isConfigured) return;

    final ledger = await _ledgerInstance();
    for (final entitlement in Entitlement.values) {
      if (!ledger.isDueForCheck(entitlement)) continue;
      final receipt = ledger.receiptFor(entitlement);
      if (receipt == null) continue;

      await _applyVerdict(
        ledger,
        entitlement,
        receipt,
        await verifier.verify(receipt),
      );
    }
  }

  @visibleForTesting
  Future<bool> applyVerdictForTesting(
    Entitlement entitlement,
    PurchaseReceipt receipt,
    ReceiptVerdict verdict,
  ) async =>
      _applyVerdict(await _ledgerInstance(), entitlement, receipt, verdict);

  /// The single place a verdict turns into a decision.
  ///
  /// Both callers — the purchase stream and the launch re-check — route
  /// through here, because they had drifted: one revoked on a rejection and
  /// the other only deleted the receipt, which left a refunded purchase
  /// working forever with nothing left to re-check it against. Returns whether
  /// the entitlement should be considered held.
  Future<bool> _applyVerdict(
    EntitlementLedger ledger,
    Entitlement entitlement,
    PurchaseReceipt receipt,
    ReceiptVerdict verdict,
  ) async {
    if (verdict.isInvalid) {
      await ledger.clear(entitlement);
      onEntitlementRevoked?.call(entitlement);
      return false;
    }
    // Valid, or unavailable: record the receipt either way so the next launch
    // has something to ask about. The ledger decides what an unconfirmed
    // verdict does to the re-check schedule.
    await ledger.record(entitlement, receipt, verdict);
    return true;
  }

  static Entitlement _entitlementFor(String productId) =>
      productId == premiumProductId
          ? Entitlement.premium
          : Entitlement.premiumPlus;

  /// The platform name the verifier expects. Web never reaches this — [init]
  /// returns early there — but a default keeps the call total.
  static String get _platformName {
    if (kIsWeb) return 'web';
    return Platform.isIOS || Platform.isMacOS ? 'ios' : 'android';
  }

  @visibleForTesting
  static PurchaseReceipt receiptFrom(PurchaseDetails purchase,
          {String? platform}) =>
      PurchaseReceipt(
        platform: platform ?? _platformName,
        productId: purchase.productID,
        token: purchase.verificationData.serverVerificationData,
        isSubscription:
            _entitlementFor(purchase.productID) == Entitlement.premiumPlus,
      );

  /// Validates a purchase before granting the entitlement.
  ///
  /// The local check is first and cheap: an unknown product or an empty token
  /// is refused without troubling anyone. It is also defeatable on a rooted or
  /// jailbroken device, so where a verifier is configured the store itself is
  /// asked — and a rejection there is final.
  ///
  /// A server that cannot be reached grants anyway. The app promises to work
  /// with no connectivity, and a parent who buys Premium on a plane should get
  /// Premium; the receipt is recorded unverified and re-checked on a later
  /// launch. That leaves a window in which a forged purchase works, which is
  /// the price of the offline promise and is deliberate.
  ///
  /// A rejection here also revokes, not just refuses: the store re-delivers
  /// purchases, so this is the path a refund arrives on for an entitlement the
  /// app is already holding.
  Future<bool> _isValid(PurchaseDetails purchase) async {
    if (!_productIds.contains(purchase.productID)) return false;
    final receipt = receiptFrom(purchase);
    if (receipt.token.isEmpty) return false;

    if (!verifier.isConfigured) return true;

    return _applyVerdict(
      await _ledgerInstance(),
      _entitlementFor(purchase.productID),
      receipt,
      await verifier.verify(receipt),
    );
  }
}
