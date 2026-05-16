import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_provider.dart';
import '../../theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildCloseButton(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildHero(),
          const SizedBox(height: 32),
          _buildFeatureList(),
          const SizedBox(height: 32),
          _buildPurchaseButton(),
          const SizedBox(height: 12),
          _buildRestoreButton(),
          const SizedBox(height: 16),
          _buildLegalText(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF7B6FEF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text('Unlock PlaySteps Premium', style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Everything you need to support your child\'s first three years — all offline.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      _Feature(Icons.play_circle_rounded, AppTheme.primary, 'Unlimited Daily Activities', 'New play challenges every day through 36 months'),
      _Feature(Icons.checklist_rounded, AppTheme.success, 'Full Milestone Ledger', 'Track all domains from birth to 3 years'),
      _Feature(Icons.picture_as_pdf_rounded, AppTheme.secondary, 'Pediatrician Export', 'One-tap PDF share for doctor visits'),
      _Feature(Icons.sort_rounded, AppTheme.cognitiveColor, 'Advanced Domain Filter', 'Focus on the skills that matter most right now'),
      _Feature(Icons.lock_outline_rounded, AppTheme.grossMotorColor, '100% Private', 'Zero cloud. Zero data collection. Always.'),
    ];

    return Column(
      children: features.map((f) => _FeatureTile(feature: f)).toList(),
    );
  }

  Widget _buildPurchaseButton() {
    return Column(
      children: [
        FilledButton(
          onPressed: _isPurchasing ? null : _purchase,
          child: _isPurchasing
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Unlock Premium — \$4.99'),
        ),
        const SizedBox(height: 6),
        Text(
          'One-time purchase. No subscription.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _restore,
      child: const Text('Restore Purchase'),
    );
  }

  Widget _buildLegalText() {
    return Text(
      'Payment will be charged to your account. This is a one-time purchase with lifetime access. No subscriptions.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
    );
  }

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);
    try {
      // In production: initiate StoreKit / Google Play Billing purchase flow
      // For now simulate a short delay then unlock
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        await context.read<ActivityProvider>().unlockPremium();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Premium! All features unlocked.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      await context.read<ActivityProvider>().restorePurchases();
      if (mounted) {
        final isPremium = context.read<ActivityProvider>().isPremium;
        if (isPremium) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPremium ? 'Premium restored!' : 'No previous purchase found.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }
}

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.color, this.title, this.subtitle);
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: Theme.of(context).textTheme.titleMedium),
                Text(feature.subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
