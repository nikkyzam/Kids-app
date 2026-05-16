import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/profile_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/milestone_provider.dart';
import 'data/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ActivityProvider(prefs)),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()),
      ],
      child: const PlayStepsApp(),
    ),
  );
}
