import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/backup_service.dart';
import '../../services/data_reset_service.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parental_gate_dialog.dart';
import '../auth/sign_in_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../paywall/paywall_screen.dart';
import '../badges/badges_screen.dart';
import '../paywall/premium_plus_screen.dart';
import 'family_sharing_screen.dart';

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
    if (mounted) {
      setState(() {
        _notifEnabled = enabled;
        _notifTime = time;
      });
    }
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
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppTheme.primary, size: 36),
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

  /// Appends the store's localised price when it is known, so the row never
  /// advertises a price that disagrees with the purchase sheet.
  String _priceLabel(String label, Entitlement entitlement) {
    final price = PurchaseService.instance.priceFor(entitlement);
    return price == null ? label : '$label — $price';
  }

  Future<void> _challengeGate() async {
    final passed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ParentalGateDialog(),
    );
    if (passed == true && mounted) setState(() => _gateUnlocked = true);
  }

  Future<void> _restoreDismissedActivities(
      ActivityProvider activityProvider, ProfileProvider profiles) async {
    final profile = profiles.activeProfile;
    if (profile == null) return;
    await activityProvider.restoreAllActivities(profile.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Those activities are back in rotation.')),
    );
  }

  Future<void> _confirmDeleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAllDataDialog(),
    );
    if (confirmed != true || !mounted) return;

    final photosDeleted = await DataResetService.deleteEverything();
    if (!mounted) return;

    if (!photosDeleted) {
      // Said out loud rather than swallowed: a parent who asked for everything
      // to go deserves to know that some image files did not.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your records are deleted. Some photo files could '
              'not be removed from this device.'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 5),
        ),
      );
    }

    // Straight back to onboarding: with no profiles left there is nothing for
    // any other screen to show, and leaving the parent on a settings list
    // built from data that no longer exists would look like a crash.
    await context.read<ProfileProvider>().loadProfiles();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  Widget _buildSettings() {
    return Consumer2<ProfileProvider, ActivityProvider>(
      builder: (context, profileProvider, activityProvider, _) {
        return ListView(
          children: [
            const _SectionHeader(title: 'Children'),
            ...profileProvider.profiles.map((p) => _ProfileTile(
                  profile: p,
                  isActive: p.id == profileProvider.activeProfile?.id,
                  onDelete: profileProvider.profiles.length > 1
                      ? () => _confirmDeleteProfile(p)
                      : null,
                )),
            if (profileProvider.canAddMore)
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded,
                    color: AppTheme.primary),
                title: const Text('Add Child Profile'),
                subtitle: Text(
                    '${3 - profileProvider.profiles.length} slot${3 - profileProvider.profiles.length == 1 ? '' : 's'} remaining'),
                onTap: _addProfile,
              ),
            const Divider(height: 1),
            const _SectionHeader(title: 'Premium'),
            if (activityProvider.isOnTrialOnly)
              ListTile(
                leading: const Icon(Icons.lock_open_rounded,
                    color: AppTheme.success),
                title: Text(
                    'Free trial — ${activityProvider.trialDaysRemaining} '
                    'day${activityProvider.trialDaysRemaining == 1 ? '' : 's'} left'),
                subtitle: const Text(
                    'Everything is unlocked. Nothing you record is lost when '
                    'it ends.'),
              ),
            if (activityProvider.hasPurchasedPremium)
              const ListTile(
                leading: Icon(Icons.star_rounded, color: AppTheme.secondary),
                title: Text('PlaySteps Premium'),
                subtitle: Text('Full activity library unlocked'),
              )
            else
              ListTile(
                leading: const Icon(Icons.star_outline_rounded,
                    color: AppTheme.secondary),
                title: Text(_priceLabel('Unlock Premium', Entitlement.premium)),
                subtitle: const Text(
                    'Full activity library, ages 4 weeks – 36 months'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen())),
              ),
            if (activityProvider.hasPurchasedPremiumPlus)
              const ListTile(
                leading: Icon(Icons.star_rounded, color: Color(0xFFF5A623)),
                title: Text('Premium Plus — Active'),
                subtitle: Text(
                    'Growth tracker, leap calendar, smart plan & weekly report'),
              )
            else
              ListTile(
                leading: const Icon(Icons.star_outline_rounded,
                    color: Color(0xFFF5A623)),
                title:
                    Text(_priceLabel('Premium Plus', Entitlement.premiumPlus)),
                subtitle: const Text(
                    'Growth charts, leap calendar, smart plan, weekly report'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PremiumPlusScreen())),
              ),
            ListTile(
              leading:
                  const Icon(Icons.restore_rounded, color: AppTheme.textMuted),
              title: const Text('Restore Purchases'),
              onTap: () async {
                // Restored entitlements arrive on the store's purchase stream,
                // so the result is not known synchronously here.
                try {
                  await activityProvider.restorePurchases();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checking for previous purchases…'),
                      ),
                    );
                  }
                } on PurchaseUnavailableException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            const _SectionHeader(title: 'Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined,
                  color: AppTheme.primary),
              title: const Text('Daily Reminder'),
              subtitle: Text(_notifEnabled
                  ? 'Remind me at ${_notifTime.format(context)}'
                  : 'Tap to enable daily play reminders'),
              value: _notifEnabled,
              onChanged: _toggleNotification,
              activeThumbColor: AppTheme.primary,
            ),
            if (_notifEnabled)
              ListTile(
                leading: const Icon(Icons.schedule_rounded,
                    color: AppTheme.textMuted),
                title: const Text('Reminder Time'),
                trailing: Text(
                  _notifTime.format(context),
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
                onTap: _pickNotifTime,
              ),
            // Account & Sync is only shown when a cloud backend is configured;
            // otherwise PlaySteps runs fully offline and there is nothing to sync.
            if (AuthService.instance.isAvailable) ...[
              const Divider(height: 1),
              const _SectionHeader(title: 'Account & Sync'),
              _buildAccountSection(context),
            ],
            if (activityProvider.skips.isNotEmpty) ...[
              const Divider(height: 1),
              const _SectionHeader(title: 'Activities'),
              ListTile(
                leading: const Icon(Icons.playlist_add_check_rounded,
                    color: AppTheme.primary),
                title: Text('${activityProvider.skips.length} set aside'),
                subtitle: const Text(
                    'Activities you marked "not for us" stay out of the '
                    'rotation'),
                trailing: TextButton(
                  onPressed: () => _restoreDismissedActivities(
                      activityProvider, profileProvider),
                  child: const Text('Bring back'),
                ),
              ),
            ],
            const Divider(height: 1),
            const _SectionHeader(title: 'Data'),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined,
                  color: AppTheme.secondary),
              title: const Text('Achievements'),
              subtitle: const Text('View your earned badges'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.upload_rounded, color: AppTheme.primary),
              title: const Text('Export Backup'),
              subtitle: const Text('Save all data as a JSON file'),
              onTap: () => BackupService.exportBackup(context),
            ),
            ListTile(
              leading:
                  const Icon(Icons.download_rounded, color: AppTheme.primary),
              title: const Text('Restore Backup'),
              subtitle: const Text('Import data from a backup file'),
              onTap: () async {
                final ok = await BackupService.importBackup(context);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Backup restored! Restart the app to see changes.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded,
                  color: AppTheme.error),
              title: const Text('Delete All Data',
                  style: TextStyle(color: AppTheme.error)),
              subtitle: const Text(
                  'Erase every child, photo and record from this device'),
              onTap: _confirmDeleteAllData,
            ),
            const Divider(height: 1),
            const _SectionHeader(title: 'About'),
            const ListTile(
              leading:
                  Icon(Icons.privacy_tip_outlined, color: AppTheme.textMuted),
              title: Text('Privacy'),
              subtitle: Text('All data stored locally. No accounts, no cloud.'),
            ),
            const ListTile(
              leading:
                  Icon(Icons.info_outline_rounded, color: AppTheme.textMuted),
              title: Text('Version'),
              subtitle: Text('PlaySteps 1.0.0'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isSignedIn) {
          return ListTile(
            leading: const Icon(Icons.cloud_outlined, color: AppTheme.primary),
            title: const Text('Sign in to sync'),
            subtitle: const Text('Back up data and share with a co-caregiver'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_done_outlined,
                  color: AppTheme.primary),
              title: Text(auth.currentUser?.email ?? 'Signed in'),
              subtitle: Text(_syncLabel(auth.syncStatus)),
              trailing: auth.syncStatus == SyncStatus.syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FamilySharingScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: AppTheme.primary),
              title: const Text('Sync Now'),
              onTap: () async {
                auth.setSyncStatus(SyncStatus.syncing);
                try {
                  await SyncService.instance.syncAll();
                  if (context.mounted) {
                    auth.setSyncStatus(SyncStatus.done);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sync complete.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    auth.setSyncStatus(SyncStatus.error, error: e.toString());
                  }
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
              title: const Text('Sign Out'),
              onTap: () async {
                await AuthService.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Signed out. Data stays on this device.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _syncLabel(SyncStatus status) => switch (status) {
        SyncStatus.idle => 'Tap to manage family sharing',
        SyncStatus.syncing => 'Syncing…',
        SyncStatus.done => 'Up to date',
        SyncStatus.error => 'Sync error — tap to retry',
      };

  Future<void> _toggleNotification(bool value) async {
    final profile = context.read<ProfileProvider>().activeProfile;
    if (value) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Permission denied — enable notifications in device settings.')),
        );
        return;
      }
      await NotificationService.instance
          .scheduleDailyAt(_notifTime, profile?.name ?? 'your child');
    } else {
      await NotificationService.instance.cancel();
    }
    if (mounted) setState(() => _notifEnabled = value);
  }

  Future<void> _pickNotifTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _notifTime);
    if (picked == null || !mounted) return;
    setState(() => _notifTime = picked);
    final profile = context.read<ProfileProvider>().activeProfile;
    await NotificationService.instance
        .scheduleDailyAt(picked, profile?.name ?? 'your child');
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
        content: const Text(
            'All activities and milestones for this profile will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
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
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.2)),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final dynamic profile;
  final bool isActive;
  final VoidCallback? onDelete;

  const _ProfileTile(
      {required this.profile, required this.isActive, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive ? AppTheme.primary : AppTheme.primaryLight,
        child: Text(
          profile.name[0].toUpperCase(),
          style: TextStyle(
              color: isActive ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(profile.name),
      subtitle: Text(profile.ageSummary),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.error, size: 20),
              onPressed: onDelete,
            )
          : null,
    );
  }
}

/// The typed confirmation for "Delete All Data".
///
/// A widget of its own so it owns its text controller: disposing a controller
/// from the caller as soon as `showDialog` returns tears it out from under a
/// field that is still on screen for the closing animation.
class _DeleteAllDataDialog extends StatefulWidget {
  const _DeleteAllDataDialog();

  @override
  State<_DeleteAllDataDialog> createState() => _DeleteAllDataDialogState();
}

class _DeleteAllDataDialogState extends State<_DeleteAllDataDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete all data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This erases every child profile, completed activity, milestone, '
            'growth record, badge and photo on this device. It cannot be '
            'undone, and a backup taken beforehand is the only way back.',
          ),
          const SizedBox(height: 16),
          const Text('Type DELETE to confirm.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'DELETE'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep my data')),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, __) => FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            // Typed confirmation rather than a second "are you sure": this is
            // the one action in the app that cannot be undone. Case-insensitive
            // and trimmed, because the keyboard should not be another obstacle.
            onPressed: value.text.trim().toUpperCase() == 'DELETE'
                ? () => Navigator.pop(context, true)
                : null,
            child: const Text('Delete everything'),
          ),
        ),
      ],
    );
  }
}
