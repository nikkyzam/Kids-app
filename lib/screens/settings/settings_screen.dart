import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/profile_provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/notification_service.dart';
import '../../services/backup_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parental_gate_dialog.dart';
import '../onboarding/onboarding_screen.dart';
import '../paywall/paywall_screen.dart';
import '../badges/badges_screen.dart';
import '../paywall/premium_plus_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _gateUnlocked = false;
  bool _notifEnabled = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadNotifState();
  }

  Future<void> _loadNotifState() async {
    final enabled = await NotificationService.instance.isEnabled();
    final time = await NotificationService.instance.scheduledTime();
    if (mounted) setState(() { _notifEnabled = enabled; _notifTime = time; });
  }

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
                subtitle: Text('Full activity library unlocked'),
              )
            else
              ListTile(
                leading: const Icon(Icons.star_outline_rounded, color: AppTheme.secondary),
                title: const Text('Unlock Premium — \$4.99'),
                subtitle: const Text('Full activity library, ages 4 weeks – 36 months'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
              ),
            if (activityProvider.isPremiumPlus)
              const ListTile(
                leading: Icon(Icons.star_rounded, color: Color(0xFFF5A623)),
                title: Text('Premium Plus — Active'),
                subtitle: Text('Growth tracker, leap calendar, smart plan & weekly report'),
              )
            else
              ListTile(
                leading: const Icon(Icons.star_outline_rounded, color: Color(0xFFF5A623)),
                title: const Text('Premium Plus — \$7.99/year'),
                subtitle: const Text('Growth charts, leap calendar, smart plan, weekly report'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumPlusScreen())),
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
            _SectionHeader(title: 'Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
              title: const Text('Daily Reminder'),
              subtitle: Text(_notifEnabled
                  ? 'Remind me at ${_notifTime.format(context)}'
                  : 'Tap to enable daily play reminders'),
              value: _notifEnabled,
              onChanged: _toggleNotification,
              activeColor: AppTheme.primary,
            ),
            if (_notifEnabled)
              ListTile(
                leading: const Icon(Icons.schedule_rounded, color: AppTheme.textMuted),
                title: const Text('Reminder Time'),
                trailing: Text(
                  _notifTime.format(context),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
                onTap: _pickNotifTime,
              ),
            const Divider(height: 1),
            _SectionHeader(title: 'Data'),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined, color: AppTheme.secondary),
              title: const Text('Achievements'),
              subtitle: const Text('View your earned badges'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.upload_rounded, color: AppTheme.primary),
              title: const Text('Export Backup'),
              subtitle: const Text('Save all data as a JSON file'),
              onTap: () => BackupService.exportBackup(context),
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: AppTheme.primary),
              title: const Text('Restore Backup'),
              subtitle: const Text('Import data from a backup file'),
              onTap: () async {
                final ok = await BackupService.importBackup(context);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup restored! Restart the app to see changes.'),
                      backgroundColor: AppTheme.success,
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

  Future<void> _toggleNotification(bool value) async {
    final profile = context.read<ProfileProvider>().activeProfile;
    if (value) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied — enable notifications in device settings.')),
        );
        return;
      }
      await NotificationService.instance.scheduleDailyAt(_notifTime, profile?.name ?? 'your child');
    } else {
      await NotificationService.instance.cancel();
    }
    if (mounted) setState(() => _notifEnabled = value);
  }

  Future<void> _pickNotifTime() async {
    final picked = await showTimePicker(context: context, initialTime: _notifTime);
    if (picked == null || !mounted) return;
    setState(() => _notifTime = picked);
    final profile = context.read<ProfileProvider>().activeProfile;
    await NotificationService.instance.scheduleDailyAt(picked, profile?.name ?? 'your child');
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
