import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/services/purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PurchaseService product configuration', () {
    test('product ids are distinct and non-empty', () {
      expect(PurchaseService.premiumProductId, isNotEmpty);
      expect(PurchaseService.premiumPlusProductId, isNotEmpty);
      expect(
        PurchaseService.premiumProductId,
        isNot(equals(PurchaseService.premiumPlusProductId)),
      );
    });

    test('covers every entitlement the app sells', () {
      // A new Entitlement without a product id would silently be unpurchasable.
      expect(Entitlement.values, hasLength(2));
    });
  });

  group('PurchaseService with no store available', () {
    // No store plugin is registered under flutter_test, so the service stays
    // unavailable — the same state as web and a misconfigured store console.
    final store = PurchaseService.instance;

    test('reports itself unavailable', () {
      expect(store.isAvailable, isFalse);
    });

    test('exposes no products or prices', () {
      expect(store.products, isEmpty);
      expect(store.priceFor(Entitlement.premium), isNull);
      expect(store.priceFor(Entitlement.premiumPlus), isNull);
    });

    test('buy throws instead of silently unlocking', () {
      expect(
        () => store.buy(Entitlement.premium),
        throwsA(isA<PurchaseUnavailableException>()),
      );
    });

    test('restore throws instead of reporting a false success', () {
      expect(
        () => store.restore(),
        throwsA(isA<PurchaseUnavailableException>()),
      );
    });
  });

  group('Entitlements are only granted by the store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a failed purchase leaves the user un-entitled', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);

      // Mirrors what the paywall does when the store is unreachable.
      await expectLater(
        PurchaseService.instance.buy(Entitlement.premium),
        throwsA(isA<PurchaseUnavailableException>()),
      );

      expect(provider.isPremium, isFalse);
      expect(prefs.getBool('is_premium'), isNull);
    });

    test('grantEntitlement is idempotent', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);

      var notifications = 0;
      provider.addListener(() => notifications++);

      // The store re-delivers restored purchases on every launch; that must not
      // produce repeated writes or listener churn.
      await provider.grantEntitlement(Entitlement.premium);
      await provider.grantEntitlement(Entitlement.premium);

      expect(provider.isPremium, isTrue);
      expect(notifications, 1);
    });
  });
}
