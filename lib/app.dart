import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/profile_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/sync_service.dart';

class PlayStepsApp extends StatelessWidget {
  const PlayStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlaySteps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileProvider>().loadProfiles();
      _syncIfSignedIn();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncIfSignedIn();
  }

  void _syncIfSignedIn() {
    final auth = context.read<AuthProvider>();
    if (!auth.isSignedIn) return;
    auth.setSyncStatus(SyncStatus.syncing);
    SyncService.instance.syncAll().then((_) {
      if (mounted) auth.setSyncStatus(SyncStatus.done);
    }).catchError((e) {
      if (mounted) auth.setSyncStatus(SyncStatus.error, error: e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        if (profileProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profileProvider.profiles.isEmpty) {
          return const OnboardingScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
