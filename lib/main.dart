import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'providers/profile_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/milestone_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/auth_provider.dart';
import 'data/database_helper.dart';
import 'data/database_platform_stub.dart'
    if (dart.library.html) 'data/database_platform_web.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/receipt_verifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Cloud sync is optional. Only spin up Supabase when real credentials have
  // been provided — the app is offline-first and must boot without a network
  // or a configured backend.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // On web, point sqflite at the IndexedDB-backed factory before first use.
  await configureDatabaseFactory();

  final prefs = await SharedPreferences.getInstance();
  try {
    await DatabaseHelper.instance.database;
  } catch (e) {
    // Don't white-screen if the local database can't initialize (e.g. the
    // SQLite WASM worker is unavailable in a web demo). The UI still renders;
    // data access degrades gracefully.
    if (!kIsWeb) rethrow;
    debugPrint('Local database unavailable: $e');
  }
  await NotificationService.instance.init();

  final activityProvider = ActivityProvider(prefs);

  // Starts the free-trial clock on the very first launch. Done here rather
  // than lazily on the first paywall so the fortnight begins when the parent
  // begins, not when they first hit a lock.
  await activityProvider.startTrialClock();

  // Route store-confirmed entitlements into the provider. Wired before init()
  // so purchases that completed while the app was closed are picked up by the
  // first purchaseStream event.
  PurchaseService.instance.onEntitlement = activityProvider.grantEntitlement;
  PurchaseService.instance.onEntitlementRevoked =
      activityProvider.revokeEntitlement;
  // Only present when a backend is configured. Without one the local check
  // decides, exactly as before, and nothing is ever revoked.
  PurchaseService.instance.verifier = HttpReceiptVerifier();
  PurchaseService.instance.onError =
      (message) => debugPrint('Purchase error: $message');
  await PurchaseService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
        ChangeNotifierProvider.value(value: activityProvider),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const PlayStepsApp(),
    ),
  );
}
