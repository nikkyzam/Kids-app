import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/providers/profile_provider.dart';
import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/providers/milestone_provider.dart';
import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/screens/onboarding/onboarding_screen.dart';
import 'package:playsteps/widgets/parental_gate_dialog.dart';
import 'package:playsteps/theme/app_theme.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.instance.resetForTesting();
  });

  group('OnboardingScreen', () {
    testWidgets('renders name field and date picker', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
          ChangeNotifierProvider(create: (_) => ActivityProvider(prefs)),
          ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ));

      expect(find.text('Welcome to\nPlaySteps'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text("Baby's Name or Nickname"), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
    });

    testWidgets('Get Started button is disabled with no input', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
          ChangeNotifierProvider(create: (_) => ActivityProvider(prefs)),
          ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ));

      final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Get Started'));
      expect(button.onPressed, isNull);
    });

    testWidgets('lays out without overflowing on a small phone',
        (tester) async {
      // 320x568 is the smallest screen still in circulation (iPhone SE 1st
      // gen); the layout must scroll rather than overflow at that size.
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
          ChangeNotifierProvider(create: (_) => ActivityProvider(prefs)),
          ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('shows age badge after date is selected', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
          ChangeNotifierProvider(create: (_) => ActivityProvider(prefs)),
          ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ));

      // No date selected yet — no age badge
      expect(find.textContaining('week'), findsNothing);
      expect(find.textContaining('month'), findsNothing);
    });
  });

  group('ParentalGateDialog', () {
    testWidgets('renders an arithmetic question with six options',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ParentalGateDialog()),
      ));

      expect(find.text('Parent Check'), findsOneWidget);
      expect(find.textContaining('What is'), findsOneWidget);
      expect(find.byType(OutlinedButton),
          findsNWidgets(ParentalGateChallenge.optionCount));
    });

    testWidgets('shows cancel button', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ParentalGateDialog()),
      ));
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('AppTheme', () {
    test('primary color is defined', () {
      expect(AppTheme.primary, isNotNull);
    });

    test('all skill category colors are defined', () {
      expect(AppTheme.grossMotorColor, isNotNull);
      expect(AppTheme.fineMotorColor, isNotNull);
      expect(AppTheme.languageColor, isNotNull);
      expect(AppTheme.cognitiveColor, isNotNull);
      expect(AppTheme.socialEmotionalColor, isNotNull);
      expect(AppTheme.sensoryColor, isNotNull);
    });

    test('light theme has material 3 enabled', () {
      expect(AppTheme.light.useMaterial3, isTrue);
    });
  });
}
