import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({super.key});

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen> {
  String? _myCode;
  bool _loading = false;
  late final TextEditingController _codeController;
  String? _joinError;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _loadCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadCode() async {
    final code = await AuthService.instance.getMyInviteCode();
    if (mounted && code != null) {
      setState(() => _myCode = code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Sharing')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Stack(
            children: [
              _buildBody(context, authProvider),
              if (_loading)
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider authProvider) {
    if (!authProvider.isSyncAvailable) {
      return _buildSyncUnavailable(context);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (authProvider.isPartner)
          _buildPartnerSection(context)
        else ...[
          _buildInviteCodeCard(context),
          const SizedBox(height: 12),
          _buildJoinFamilyCard(context),
        ],
        const SizedBox(height: 24),
        _buildSyncSection(context, authProvider),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sync unavailable (no Supabase credentials configured)
  // ---------------------------------------------------------------------------

  Widget _buildSyncUnavailable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    color: AppTheme.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Cloud sync unavailable',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This build has no cloud backend configured, so family sharing '
                'and cross-device sync are turned off. All of your data stays '
                'safely on this device.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Partner Mode
  // ---------------------------------------------------------------------------

  Widget _buildPartnerSection(BuildContext context) {
    return _AppCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.people_rounded, color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Partner Mode',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            "You're connected to a family",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You can view and add to all profiles synced to this account.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => _leaveFamily(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Leave Family'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Owner — Invite Code Card
  // ---------------------------------------------------------------------------

  Widget _buildInviteCodeCard(BuildContext context) {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Your Invite Code', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (_myCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _myCode!,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 6,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.primary),
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _myCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this code with your partner — they enter it in their PlaySteps app.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            Text(
              'Generate a code to invite your partner to your family.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _createFamily,
              child: const Text('Generate Invite Code'),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Owner — Join a Family Card
  // ---------------------------------------------------------------------------

  Widget _buildJoinFamilyCard(BuildContext context) {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Have an invite code?', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: 'Enter 6-character code',
              counterText: '',
            ),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
            onChanged: (_) {
              if (_joinError != null) setState(() => _joinError = null);
            },
          ),
          if (_joinError != null) ...[
            const SizedBox(height: 8),
            Text(
              _joinError!,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _joinFamily,
            child: const Text('Join Family'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sync Status Section
  // ---------------------------------------------------------------------------

  Widget _buildSyncSection(BuildContext context, AuthProvider authProvider) {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Sync Status', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              _SyncStatusChip(status: authProvider.syncStatus),
            ],
          ),
          if (authProvider.syncStatus == SyncStatus.error &&
              authProvider.lastSyncError != null) ...[
            const SizedBox(height: 8),
            Text(
              authProvider.lastSyncError!,
              style: const TextStyle(color: AppTheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : () => _syncNow(context),
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _createFamily() async {
    setState(() => _loading = true);
    try {
      final code = await AuthService.instance.createFamily();
      if (mounted) setState(() => _myCode = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _joinError = 'Please enter a valid 6-character code.');
      return;
    }

    setState(() {
      _loading = true;
      _joinError = null;
    });

    try {
      final success = await AuthService.instance.joinFamily(code);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected! Syncing data...')),
        );
        await SyncService.instance.syncAll();
      } else {
        setState(() => _joinError = 'Invalid code. Please check and try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _joinError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leaveFamily(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Family?'),
        content: const Text(
          "You'll lose access to the shared family data. You can rejoin later with an invite code.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AuthService.instance.leaveFamily();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left family.')),
      );
    }
  }

  Future<void> _syncNow(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    authProvider.setSyncStatus(SyncStatus.syncing);
    try {
      await SyncService.instance.syncAll();
      if (mounted) authProvider.setSyncStatus(SyncStatus.done);
    } catch (e) {
      if (mounted) authProvider.setSyncStatus(SyncStatus.error, error: e.toString());
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable card widget
// ---------------------------------------------------------------------------

class _AppCard extends StatelessWidget {
  final Widget child;

  const _AppCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F7)),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Sync status chip
// ---------------------------------------------------------------------------

class _SyncStatusChip extends StatelessWidget {
  final SyncStatus status;

  const _SyncStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      SyncStatus.idle => ('Idle', AppTheme.textMuted, const Color(0xFFF0F1F6)),
      SyncStatus.syncing => ('Syncing…', AppTheme.primary, AppTheme.primaryLight),
      SyncStatus.done => ('Up to date', AppTheme.success, AppTheme.successLight),
      SyncStatus.error => ('Error', AppTheme.error, const Color(0xFFFDECEC)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SyncStatus.syncing)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                switch (status) {
                  SyncStatus.done => Icons.check_circle_rounded,
                  SyncStatus.error => Icons.error_rounded,
                  _ => Icons.circle,
                },
                size: 10,
                color: color,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
