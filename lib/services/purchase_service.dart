import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

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

  /// Called when a purchase fails or is cancelled, so the UI can stop spinning.
  void Function(String message)? onError;

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
            final entitlement = purchase.productID == premiumProductId
                ? Entitlement.premium
                : Entitlement.premiumPlus;
            onEntitlement?.call(entitlement);
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

  /// Validates a purchase before granting the entitlement.
  ///
  /// This performs local checks only. Local validation is defeatable on a
  /// rooted or jailbroken device: to harden it, post
  /// `purchase.verificationData.serverVerificationData` to a backend that calls
  /// Apple's `verifyReceipt` / Google's `purchases.products.get`, and grant the
  /// entitlement only on that server's response.
  Future<bool> _isValid(PurchaseDetails purchase) async {
    if (!_productIds.contains(purchase.productID)) return false;
    return purchase.verificationData.serverVerificationData.isNotEmpty;
  }
}
