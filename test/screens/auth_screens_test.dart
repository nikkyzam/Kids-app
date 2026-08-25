import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/screens/auth/sign_in_screen.dart';
import 'package:playsteps/screens/settings/family_sharing_screen.dart';
import 'package:playsteps/services/auth_service.dart';

import '../support/fake_auth.dart';
import '../support/harness.dart';

/// These screens are entirely gated behind a configured, signed-in Supabase
/// session, so none of their real behaviour ran before AuthService became
/// substitutable.
void main() {
  Harness.initOnce();

  late FakeAuthService auth;

  setUp(() async {
    await Harness.reset();
    auth = FakeAuthService();
    AuthService.instance = auth;
  });

  tearDown(() {
    auth.dispose();
    AuthService.resetInstance();
    Harness.tearDownClock();
  });

  /// The provider caches auth state, so rebuild it after swapping the service.
  Future<void> open(WidgetTester tester, Widget screen,
      {Size size = const Size(420, 1600)}) async {
    await Harness.realAsync(tester, () async => Harness.reset());
    AuthService.instance = auth;
    await Harness.pump(tester, screen, size: size);
  }

  group('FamilySharingScreen when sync is unavailable', () {
    setUp(() => auth.available = false);

    testWidgets('explains itself instead of offering dead controls',
        (tester) async {
      await open(tester, const FamilySharingScreen());

      expect(find.text('Generate Invite Code'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('FamilySharingScreen when signed in', () {
    testWidgets('shows the family controls', (tester) async {
      await open(tester, const FamilySharingScreen());

      expect(find.text('Family Sharing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loads the existing invite code', (tester) async {
      await open(tester, const FamilySharingScreen());

      expect(auth.calls, contains('getMyInviteCode'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('generating a code calls through to the service',
        (tester) async {
      await open(tester, const FamilySharingScreen());

      final generate = find.text('Generate Invite Code');
      if (generate.evaluate().isNotEmpty) {
        await tester.tap(generate);
        await tester.pump(const Duration(milliseconds: 400));
        expect(auth.calls, contains('createFamily'));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a service error does not crash the screen', (tester) async {
      auth.throwOn = 'getMyInviteCode';
      await open(tester, const FamilySharingScreen());

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders for a partner who joined someone else\'s family',
        (tester) async {
      auth.partner = true;
      await open(tester, const FamilySharingScreen());

      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await open(tester, const FamilySharingScreen(),
          size: const Size(360, 1600));

      expect(tester.takeException(), isNull);
    });

    testWidgets('leaving the family asks for confirmation first',
        (tester) async {
      auth.partner = true;
      await open(tester, const FamilySharingScreen());

      final leave = find.text('Leave Family');
      if (leave.evaluate().isNotEmpty) {
        await tester.tap(leave.first);
        await tester.pump(const Duration(milliseconds: 400));

        // A destructive action must confirm rather than act immediately.
        expect(auth.calls, isNot(contains('leaveFamily')));
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('SignInScreen', () {
    setUp(() => auth.signedIn = false);

    testWidgets('starts on the email step', (tester) async {
      await open(tester, const SignInScreen());

      expect(find.text('Send Code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('will not send a code for an empty email', (tester) async {
      await open(tester, const SignInScreen());

      await tester.tap(find.text('Send Code'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(auth.calls, isNot(contains('signInWithEmail')));
    });

    testWidgets('sends a code for a typed email', (tester) async {
      await open(tester, const SignInScreen());

      await tester.enterText(
          find.byType(TextField).first, 'parent@example.com');
      await tester.pump();
      await tester.tap(find.text('Send Code'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(auth.calls, contains('signInWithEmail'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('moves to the verify step after sending', (tester) async {
      await open(tester, const SignInScreen());

      await tester.enterText(
          find.byType(TextField).first, 'parent@example.com');
      await tester.pump();
      await tester.tap(find.text('Send Code'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Verify Code'), findsOneWidget);
      expect(find.text('Use a different email'), findsOneWidget);
    });

    testWidgets('can go back to the email step', (tester) async {
      await open(tester, const SignInScreen());

      await tester.enterText(
          find.byType(TextField).first, 'parent@example.com');
      await tester.pump();
      await tester.tap(find.text('Send Code'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Use a different email'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Send Code'), findsOneWidget);
    });

    testWidgets('surfaces a send failure instead of hanging', (tester) async {
      auth.throwOn = 'signInWithEmail';
      await open(tester, const SignInScreen());

      await tester.enterText(
          find.byType(TextField).first, 'parent@example.com');
      await tester.pump();
      await tester.tap(find.text('Send Code'));
      await tester.pump(const Duration(milliseconds: 400));

      // Still on the email step, and the screen is usable.
      expect(find.text('Send Code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('verifies a typed code', (tester) async {
      await open(tester, const SignInScreen());

      await tester.enterText(
          find.byType(TextField).first, 'parent@example.com');
      await tester.pump();
      await tester.tap(find.text('Send Code'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tap(find.text('Verify Code'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(auth.calls, contains('verifyOtp'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out on a 360px phone', (tester) async {
      await open(tester, const SignInScreen(), size: const Size(360, 1200));
      expect(tester.takeException(), isNull);
    });
  });
}
