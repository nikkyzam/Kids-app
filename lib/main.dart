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
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Cloud sync is optional. Only spin up Supabase when real credentials have
  // been provided — the app is offline-first and must boot without a network
  // or a configured backend.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  await DatabaseHelper.instance.database;
  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ActivityProvider(prefs)),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const PlayStepsApp(),
    ),
  );
}
