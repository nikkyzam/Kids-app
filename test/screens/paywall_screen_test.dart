import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/screens/paywall/paywall_screen.dart';
import 'package:playsteps/services/purchase_service.dart';

Widget _wrap(ActivityProvider provider) {
  return ChangeNotifierProvider<ActivityProvider>.value(
    value: provider,
    child: const MaterialApp(home: PaywallScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ActivityProvider> makeProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return ActivityProvider(prefs);
  }

  group('PaywallScreen when the store is unavailable', () {
    // No store plugin is registered under flutter_test, which is the same state
    // the app is in on web or with unconfigured store products.

    testWidgets(
        'disables the purchase button rather than offering a free unlock',
        (tester) async {
      await tester.pumpWidget(_wrap(await makeProvider()));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull,
          reason: 'an unavailable store must not be purchasable');
      expect(find.text('Store unavailable'), findsOneWidget);
    });

    testWidgets('does not advertise a hard-coded price', (tester) async {
      await tester.pumpWidget(_wrap(await makeProvider()));
      await tester.pump();

      // Prices come from the store at runtime; showing one the store did not
      // supply risks charging a different amount than advertised.
      expect(find.textContaining(r'$4.99'), findsNothing);
    });

    testWidgets('tapping restore never grants premium', (tester) async {
      final provider = await makeProvider();
      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      // The button sits below the fold in the default test viewport, so scroll
      // it into view — otherwise the tap silently misses and proves nothing.
      await tester.ensureVisible(find.text('Restore Purchase'));
      await tester.pump();
      await tester.tap(find.text('Restore Purchase'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(provider.isPremium, isFalse);
    });
  });

  group('PaywallScreen once entitled', () {
    testWidgets('shows the unlocked confirmation', (tester) async {
      final provider = await makeProvider();
      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      // Simulates the store confirming a purchase on its stream.
      await provider.grantEntitlement(Entitlement.premium);
      await tester.pump();
      await tester.pump();

      expect(provider.isPremium, isTrue);
    });
  });
}
