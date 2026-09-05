import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:playsteps/providers/activity_provider.dart';
import 'package:playsteps/services/entitlement_ledger.dart';
import 'package:playsteps/services/purchase_service.dart';
import 'package:playsteps/services/receipt_verifier.dart';
import 'package:playsteps/utils/clock.dart';

/// A verifier whose answers the test dictates, and which records what it was
/// asked.
class FakeVerifier implements ReceiptVerifier {
  final ReceiptVerdict verdict;
  @override
  final bool isConfigured;

  final List<PurchaseReceipt> asked = [];

  FakeVerifier(this.verdict, {this.isConfigured = true});

  @override
  Future<ReceiptVerdict> verify(PurchaseReceipt receipt) async {
    asked.add(receipt);
    return verdict;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const receipt = PurchaseReceipt(
    platform: 'android',
    productId: PurchaseService.premiumProductId,
    token: 'token-123',
    isSubscription: false,
  );

  final now = DateTime(2026, 5, 20, 10);

  setUp(() => Clock.freeze(now));
  tearDown(Clock.reset);

  Future<EntitlementLedger> ledgerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return EntitlementLedger(await SharedPreferences.getInstance());
  }

  group('a verdict has three outcomes, not two', () {
    test('an unreachable server is not a rejection', () {
      // The whole design rests on this: collapsing "could not ask" into "no"
      // revokes a real purchase every time the backend has a bad day.
      const unavailable = ReceiptVerdict.unavailable('offline');

      expect(unavailable.isInvalid, isFalse);
      expect(unavailable.isValid, isFalse);
      expect(unavailable.isUnavailable, isTrue);
    });
  });

  group('HttpReceiptVerifier', () {
    HttpReceiptVerifier verifierReturning(
      int status,
      Object body, {
      void Function(http.Request)? onRequest,
    }) =>
        HttpReceiptVerifier(
          endpoint: Uri.parse('https://example.test/functions/v1/verify'),
          anonKey: 'anon',
          client: MockClient((request) async {
            onRequest?.call(request);
            return http.Response(
                body is String ? body : jsonEncode(body), status,
                headers: {'content-type': 'application/json'});
          }),
        );

    test('accepts a receipt the server confirms', () async {
      final verdict =
          await verifierReturning(200, {'valid': true}).verify(receipt);

      expect(verdict.isValid, isTrue);
      expect(verdict.expiresAt, isNull);
    });

    test('carries a subscription expiry back', () async {
      final expiry = DateTime(2027, 1, 1);
      final verdict = await verifierReturning(200, {
        'valid': true,
        'expiresAt': expiry.millisecondsSinceEpoch,
      }).verify(receipt);

      expect(verdict.isValid, isTrue);
      expect(verdict.expiresAt, expiry);
    });

    test('rejects what the server rejects, with its reason', () async {
      final verdict = await verifierReturning(
              200, {'valid': false, 'reason': 'unknown purchase token'})
          .verify(receipt);

      expect(verdict.isInvalid, isTrue);
      expect(verdict.reason, 'unknown purchase token');
    });

    test('treats the function\'s own 503 as unreachable', () async {
      // The function answers 503 when it could not reach the store. That is
      // not evidence against the parent.
      final verdict = await verifierReturning(
              503, {'valid': false, 'reason': 'verification unavailable'})
          .verify(receipt);

      expect(verdict.isUnavailable, isTrue);
      expect(verdict.isInvalid, isFalse);
    });

    test('treats a network failure as unreachable', () async {
      final verifier = HttpReceiptVerifier(
        endpoint: Uri.parse('https://example.test/verify'),
        anonKey: 'anon',
        client: MockClient((_) async => throw const SocketExceptionStub()),
      );

      expect((await verifier.verify(receipt)).isUnavailable, isTrue);
    });

    test('treats a nonsense body as unreachable rather than a rejection',
        () async {
      final verdict = await verifierReturning(200, 'not json').verify(receipt);

      expect(verdict.isUnavailable, isTrue);
    });

    test('sends the receipt and authenticates', () async {
      http.Request? seen;
      await verifierReturning(200, {'valid': true},
          onRequest: (request) => seen = request).verify(receipt);

      final body = jsonDecode(seen!.body) as Map<String, dynamic>;
      expect(body['platform'], 'android');
      expect(body['productId'], PurchaseService.premiumProductId);
      expect(body['token'], 'token-123');
      expect(body['subscription'], isFalse);
      expect(seen!.headers['Authorization'], 'Bearer anon');
    });

    test('is switched off when no backend is configured', () async {
      final verifier = HttpReceiptVerifier(
          endpoint: null,
          anonKey: '',
          client: MockClient(
            (_) async => throw StateError('must not be called'),
          ));

      expect(verifier.isConfigured, isFalse);
      expect((await verifier.verify(receipt)).isUnavailable, isTrue);
    });
  });

  group('EntitlementLedger', () {
    test('records a confirmed receipt as verified now', () async {
      final ledger = await ledgerWith({});

      await ledger.record(
          Entitlement.premium, receipt, const ReceiptVerdict.valid());

      expect(ledger.receiptFor(Entitlement.premium), receipt);
      expect(ledger.lastVerifiedAt(Entitlement.premium), now);
      expect(ledger.isDueForCheck(Entitlement.premium), isFalse);
    });

    test('leaves an unverified grant first in line', () async {
      final ledger = await ledgerWith({});

      await ledger.record(Entitlement.premium, receipt,
          const ReceiptVerdict.unavailable('offline'));

      // Granted offline: the receipt is kept so it can be checked, but it is
      // not trusted for a week on the strength of an outage.
      expect(ledger.receiptFor(Entitlement.premium), receipt);
      expect(ledger.lastVerifiedAt(Entitlement.premium), isNull);
      expect(ledger.isDueForCheck(Entitlement.premium), isTrue);
    });

    test('comes due again after a week', () async {
      final ledger = await ledgerWith({});
      await ledger.record(
          Entitlement.premium, receipt, const ReceiptVerdict.valid());

      Clock.freeze(now.add(const Duration(days: 6)));
      expect(ledger.isDueForCheck(Entitlement.premium), isFalse);

      Clock.freeze(now.add(EntitlementLedger.reverifyAfter));
      expect(ledger.isDueForCheck(Entitlement.premium), isTrue);
    });

    test('comes due the moment a subscription expiry passes', () async {
      final ledger = await ledgerWith({});
      await ledger.record(
        Entitlement.premiumPlus,
        receipt,
        ReceiptVerdict.valid(expiresAt: now.add(const Duration(days: 2))),
      );

      expect(ledger.isDueForCheck(Entitlement.premiumPlus), isFalse);

      Clock.freeze(now.add(const Duration(days: 3)));
      expect(ledger.isDueForCheck(Entitlement.premiumPlus), isTrue);
    });

    test('re-checks when the device clock has moved backwards', () async {
      final ledger = await ledgerWith({});
      await ledger.record(
          Entitlement.premium, receipt, const ReceiptVerdict.valid());

      Clock.freeze(now.subtract(const Duration(days: 30)));

      // A verification stamped in the future would otherwise be trusted
      // indefinitely.
      expect(ledger.isDueForCheck(Entitlement.premium), isTrue);
    });

    test('never calls an entitlement with no receipt due', () async {
      // What an entitlement granted before verification existed looks like.
      // There is nothing to check, and absence of evidence is not grounds to
      // take away what someone bought.
      final ledger = await ledgerWith({'is_premium': true});

      expect(ledger.receiptFor(Entitlement.premium), isNull);
      expect(ledger.isDueForCheck(Entitlement.premium), isFalse);
    });

    test('survives a corrupt record', () async {
      final ledger = await ledgerWith({'receipt_premium': '{not json'});

      expect(ledger.receiptFor(Entitlement.premium), isNull);
      expect(ledger.isDueForCheck(Entitlement.premium), isFalse);
    });

    test('clearing removes every trace', () async {
      final ledger = await ledgerWith({});
      await ledger.record(Entitlement.premium, receipt,
          ReceiptVerdict.valid(expiresAt: now.add(const Duration(days: 1))));

      await ledger.clear(Entitlement.premium);

      expect(ledger.receiptFor(Entitlement.premium), isNull);
      expect(ledger.lastVerifiedAt(Entitlement.premium), isNull);
      expect(ledger.expiresAt(Entitlement.premium), isNull);
    });
  });

  group('re-verification on launch', () {
    late List<Entitlement> revoked;

    setUp(() {
      revoked = [];
      PurchaseService.instance.onEntitlementRevoked = revoked.add;
    });

    tearDown(() {
      PurchaseService.instance.onEntitlementRevoked = null;
      PurchaseService.instance.verifier = const NullReceiptVerifier();
      PurchaseService.instance.ledgerForTesting = null;
    });

    Future<EntitlementLedger> ledgerDueForCheck() async {
      final ledger = await ledgerWith({});
      await ledger.record(Entitlement.premium, receipt,
          const ReceiptVerdict.unavailable('granted offline'));
      PurchaseService.instance.ledgerForTesting = ledger;
      return ledger;
    }

    test('revokes an entitlement the store now rejects', () async {
      final ledger = await ledgerDueForCheck();
      PurchaseService.instance.verifier =
          FakeVerifier(const ReceiptVerdict.invalid('refunded'));

      await PurchaseService.instance.reverifyStoredEntitlements();

      expect(revoked, [Entitlement.premium]);
      expect(ledger.receiptFor(Entitlement.premium), isNull);
    });

    test('keeps an entitlement when the server cannot be reached', () async {
      final ledger = await ledgerDueForCheck();
      PurchaseService.instance.verifier =
          FakeVerifier(const ReceiptVerdict.unavailable('offline'));

      await PurchaseService.instance.reverifyStoredEntitlements();

      expect(revoked, isEmpty);
      expect(ledger.receiptFor(Entitlement.premium), receipt);
    });

    test('stamps a confirmed entitlement so it is not asked about again',
        () async {
      final ledger = await ledgerDueForCheck();
      PurchaseService.instance.verifier =
          FakeVerifier(const ReceiptVerdict.valid());

      await PurchaseService.instance.reverifyStoredEntitlements();

      expect(revoked, isEmpty);
      expect(ledger.lastVerifiedAt(Entitlement.premium), now);
      expect(ledger.isDueForCheck(Entitlement.premium), isFalse);
    });

    test('does nothing at all with no verifier configured', () async {
      final ledger = await ledgerDueForCheck();
      final verifier = FakeVerifier(const ReceiptVerdict.invalid('refunded'),
          isConfigured: false);
      PurchaseService.instance.verifier = verifier;

      await PurchaseService.instance.reverifyStoredEntitlements();

      // A build with no backend behaves exactly as it did before any of this
      // existed.
      expect(verifier.asked, isEmpty);
      expect(revoked, isEmpty);
      expect(ledger.receiptFor(Entitlement.premium), receipt);
    });

    test('leaves an entitlement that is not yet due alone', () async {
      final ledger = await ledgerWith({});
      await ledger.record(
          Entitlement.premium, receipt, const ReceiptVerdict.valid());
      PurchaseService.instance.ledgerForTesting = ledger;
      final verifier = FakeVerifier(const ReceiptVerdict.invalid('refunded'));
      PurchaseService.instance.verifier = verifier;

      await PurchaseService.instance.reverifyStoredEntitlements();

      expect(verifier.asked, isEmpty);
      expect(revoked, isEmpty);
    });
  });

  group('revoking an entitlement', () {
    test('drops the flag without touching anything the parent recorded',
        () async {
      SharedPreferences.setMockInitialValues({
        'is_premium': true,
        'is_premium_plus': true,
        'active_profile_id': 3,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = ActivityProvider(prefs);

      await provider.revokeEntitlement(Entitlement.premium);

      expect(provider.hasPurchasedPremium, isFalse);
      expect(provider.hasPurchasedPremiumPlus, isTrue);
      expect(prefs.getBool('is_premium'), isNull);
      expect(prefs.getInt('active_profile_id'), 3);
    });

    test('is a no-op for an entitlement that was never granted', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ActivityProvider(await SharedPreferences.getInstance());

      await provider.revokeEntitlement(Entitlement.premium);

      expect(provider.hasPurchasedPremium, isFalse);
    });
  });
}

/// Stands in for a `SocketException` without importing `dart:io`, so this file
/// stays runnable everywhere the rest of the suite is.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'SocketException: failed host lookup';
}
