import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/services/trial_service.dart';
import 'package:playsteps/utils/clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final launchDay = DateTime(2026, 5, 1, 9);

  tearDown(Clock.reset);

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('starting the clock', () {
    test('stamps the first launch', () async {
      Clock.freeze(launchDay);
      final prefs = await prefsWith({});

      final started = await TrialService.recordFirstLaunch(prefs);

      expect(started, launchDay);
      expect(TrialService.startedAt(prefs), launchDay);
    });

    test('never restarts an already-running trial', () async {
      Clock.freeze(launchDay);
      final prefs = await prefsWith({});
      await TrialService.recordFirstLaunch(prefs);

      // Every launch calls this; a parent must not get a fresh fortnight for
      // reopening the app.
      Clock.freeze(launchDay.add(const Duration(days: 10)));
      final second = await TrialService.recordFirstLaunch(prefs);

      expect(second, launchDay);
      expect(TrialService.daysRemaining(prefs), 4);
    });

    test('a corrupt stamp is replaced rather than crashing the launch',
        () async {
      Clock.freeze(launchDay);
      final prefs =
          await prefsWith({TrialService.firstLaunchKey: 'not-a-date'});

      expect(TrialService.startedAt(prefs), isNull);
      expect(await TrialService.recordFirstLaunch(prefs), launchDay);
    });
  });

  group('the fortnight', () {
    Future<SharedPreferences> startedOn(DateTime day) async {
      Clock.freeze(day);
      final prefs = await prefsWith({});
      await TrialService.recordFirstLaunch(prefs);
      return prefs;
    }

    test('is active on the day it starts', () async {
      final prefs = await startedOn(launchDay);

      expect(TrialService.isActive(prefs), isTrue);
      expect(TrialService.daysRemaining(prefs), 14);
      expect(TrialService.hasLapsed(prefs), isFalse);
    });

    test('counts down without reaching zero while it is still running',
        () async {
      final prefs = await startedOn(launchDay);

      Clock.freeze(launchDay.add(const Duration(days: 13, hours: 23)));

      // Rounded up on purpose: "0 days left" while the trial is in fact still
      // unlocking everything would be a lie.
      expect(TrialService.isActive(prefs), isTrue);
      expect(TrialService.daysRemaining(prefs), 1);
    });

    test('lapses exactly a fortnight in', () async {
      final prefs = await startedOn(launchDay);

      Clock.freeze(launchDay.add(TrialService.length));

      expect(TrialService.isActive(prefs), isFalse);
      expect(TrialService.hasLapsed(prefs), isTrue);
      expect(TrialService.daysRemaining(prefs), 0);
    });

    test('has not lapsed when it never started', () async {
      final prefs = await prefsWith({});
      Clock.freeze(launchDay);

      // The paywall words these two states differently, so they must not
      // collapse into each other.
      expect(TrialService.isActive(prefs), isFalse);
      expect(TrialService.hasLapsed(prefs), isFalse);
    });
  });

  group('what the trial unlocks', () {
    test('opens everything while it runs', () async {
      Clock.freeze(launchDay);
      final prefs = await prefsWith({});
      final provider = ActivityProvider(prefs);
      await provider.startTrialClock();

      expect(provider.isPremium, isTrue);
      expect(provider.isPremiumPlus, isTrue);
      // But nothing has been bought, so the paywall must still be reachable.
      expect(provider.hasPurchasedPremium, isFalse);
      expect(provider.hasPurchasedPremiumPlus, isFalse);
      expect(provider.isOnTrialOnly, isTrue);
    });

    test('falls back to the age-based free tier when it ends', () async {
      Clock.freeze(launchDay);
      final prefs = await prefsWith({});
      final provider = ActivityProvider(prefs);
      await provider.startTrialClock();

      Clock.freeze(launchDay.add(const Duration(days: 15)));

      expect(provider.isPremium, isFalse);
      expect(provider.isPremiumPlus, isFalse);
      expect(provider.hasTrialLapsed, isTrue);
    });

    test('stays quiet for a parent who has paid', () async {
      Clock.freeze(launchDay);
      final prefs = await prefsWith({'is_premium': true});
      final provider = ActivityProvider(prefs);
      await provider.startTrialClock();

      // The trial is technically running, but there is nothing to tell someone
      // who already owns the app.
      expect(provider.isTrialActive, isTrue);
      expect(provider.isOnTrialOnly, isFalse);
      expect(provider.hasPurchasedPremium, isTrue);
    });

    test('a lapsed trial leaves a purchase untouched', () async {
      Clock.freeze(launchDay);
      final prefs = await prefsWith({'is_premium': true});
      final provider = ActivityProvider(prefs);
      await provider.startTrialClock();

      Clock.freeze(launchDay.add(const Duration(days: 30)));

      expect(provider.isPremium, isTrue);
      expect(provider.isOnTrialOnly, isFalse);
    });
  });
}
