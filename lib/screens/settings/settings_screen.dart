import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/profile_provider.dart';
import '../../providers/activity_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parental_gate_dialog.dart';
import '../onboarding/onboarding_screen.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _gateUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _gateUnlocked ? _buildSettings() : _buildLockedView(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Parent Zone', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Complete a quick challenge to access settings and protect from little fingers.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _challengeGate,
              child: const Text('Unlock Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _challengeGate() async {
    final passed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ParentalGateDialog(),
    );
    if (passed == true && mounted) setState(() => _gateUnlocked = true);
  }

  Widget _buildSettings() {
    return Consumer2<ProfileProvider, ActivityProvider>(
      builder: (context, profileProvider, activityProvider, _) {
        return ListView(
          children: [
            _SectionHeader(title: 'Children'),
            ...profileProvider.profiles.map((p) => _ProfileTile(
              profile: p,
              isActive: p.id == profileProvider.activeProfile?.id,
              onDelete: profileProvider.profiles.length > 1
                  ? () => _confirmDeleteProfile(p)
                  : null,
            )),
            if (profileProvider.canAddMore)
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
                title: const Text('Add Child Profile'),
                subtitle: Text('${3 - profileProvider.profiles.length} slot${3 - profileProvider.profiles.length == 1 ? '' : 's'} remaining'),
                onTap: _addProfile,
              ),
            const Divider(height: 1),
            _SectionHeader(title: 'Premium'),
            if (activityProvider.isPremium)
              const ListTile(
                leading: Icon(Icons.star_rounded, color: AppTheme.secondary),
                title: Text('PlaySteps Premium'),
                subtitle: Text('All features unlocked'),
              )
            else
              ListTile(
                leading: const Icon(Icons.star_outline_rounded, color: AppTheme.secondary),
                title: const Text('Upgrade to Premium'),
                subtitle: const Text('Unlock all daily activities & export'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
              ),
            ListTile(
              leading: const Icon(Icons.restore_rounded, color: AppTheme.textMuted),
              title: const Text('Restore Purchases'),
              onTap: () async {
                await activityProvider.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(activityProvider.isPremium ? 'Premium restored!' : 'No purchases found.'),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1),
            _SectionHeader(title: 'About'),
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: AppTheme.textMuted),
              title: Text('Privacy'),
              subtitle: Text('All data stored locally. No accounts, no cloud.'),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded, color: AppTheme.textMuted),
              title: Text('Version'),
              subtitle: Text('PlaySteps 1.0.0'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProfile() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _confirmDeleteProfile(profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${profile.name}?'),
        content: const Text('All activities and milestones for this profile will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ProfileProvider>().deleteProfile(profile);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.2)),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final dynamic profile;
  final bool isActive;
  final VoidCallback? onDelete;

  const _ProfileTile({required this.profile, required this.isActive, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive ? AppTheme.primary : AppTheme.primaryLight,
        child: Text(
          profile.name[0].toUpperCase(),
          style: TextStyle(color: isActive ? Colors.white : AppTheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(profile.name),
      subtitle: Text(profile.displayAge),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
              onPressed: onDelete,
            )
          : null,
    );
  }
}
