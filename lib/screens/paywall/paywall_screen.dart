import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/activity_provider.dart';
import '../../services/purchase_service.dart';
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
    // Watches the *purchase*, not the effective unlock: during the free trial
    // everything is unlocked, and dismissing on that would make the paywall
    // impossible to open for the fortnight a parent is deciding.
    final ap = context.watch<ActivityProvider>();
    if (ap.hasPurchasedPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Premium! All features unlocked.'),
            backgroundColor: AppTheme.success,
          ),
        );
      });
    }

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
          const SizedBox(height: 20),
          _buildTrialStatus(),
          const SizedBox(height: 12),
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
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text('Unlock PlaySteps Premium',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Everything you need to support your child\'s first three years.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  /// Where the parent stands: mid-trial, lapsed, or neither. Stated plainly
  /// rather than left to be discovered by hitting a lock.
  Widget _buildTrialStatus() {
    final ap = context.watch<ActivityProvider>();

    if (ap.isOnTrialOnly) {
      final days = ap.trialDaysRemaining;
      return _StatusBanner(
        icon: Icons.lock_open_rounded,
        color: AppTheme.success,
        text: 'Your free trial has $days day${days == 1 ? '' : 's'} left — '
            'everything is unlocked until then.',
      );
    }
    if (ap.hasTrialLapsed) {
      return const _StatusBanner(
        icon: Icons.schedule_rounded,
        color: AppTheme.secondary,
        text: 'Your free trial has ended. Everything you recorded is still '
            'here, and the first four weeks of activities stay free.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFeatureList() {
    final features = [
      // Describes the library as it actually is. The daily activity is drawn
      // from the handful matching the child's current age band, so promising a
      // new challenge every day was not something the content could deliver.
      const _Feature(
          Icons.play_circle_rounded,
          AppTheme.primary,
          'Full Activity Library',
          'Every age-matched activity from 4 weeks to 36 months'),
      const _Feature(Icons.checklist_rounded, AppTheme.success,
          'Full Milestone Ledger', 'Track all domains from birth to 3 years'),
      const _Feature(Icons.picture_as_pdf_rounded, AppTheme.secondary,
          'Pediatrician Export', 'One-tap PDF share for doctor visits'),
      const _Feature(
          Icons.sort_rounded,
          AppTheme.cognitiveColor,
          'Advanced Domain Filter',
          'Focus on the skills that matter most right now'),
      // "Zero cloud, always" stopped being true when family sharing shipped.
      // Private-by-default is the accurate claim: nothing leaves the device
      // unless the parent turns sharing on.
      const _Feature(
          Icons.card_giftcard_rounded,
          AppTheme.languageColor,
          'Every Future Activity Pack',
          'New activities and content updates are included — no second '
              'purchase, ever'),
      const _Feature(
          Icons.lock_outline_rounded,
          AppTheme.grossMotorColor,
          'Private by Default',
          'No ads, no tracking. Accounts and cloud sync only if you turn on '
              'family sharing.'),
    ];

    return Column(
      children: features.map((f) => _FeatureTile(feature: f)).toList(),
    );
  }

  Widget _buildPurchaseButton() {
    final store = PurchaseService.instance;
    // Show the store's own localised price so the button never contradicts
    // what the purchase sheet charges.
    final price = store.priceFor(Entitlement.premium);
    final label = price == null ? 'Unlock Premium' : 'Unlock Premium — $price';

    return Column(
      children: [
        FilledButton(
          onPressed: (_isPurchasing || !store.isAvailable) ? null : _purchase,
          child: _isPurchasing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(store.isAvailable ? label : 'Store unavailable'),
        ),
        const SizedBox(height: 6),
        Text(
          'One-time purchase. No subscription.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w600),
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
      // Hands off to StoreKit / Play Billing. The entitlement is granted later
      // via the purchase stream, so this only opens the platform sheet.
      await PurchaseService.instance.buy(Entitlement.premium);
    } on PurchaseUnavailableException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      await context.read<ActivityProvider>().restorePurchases();
      if (mounted) _showMessage('Checking for previous purchases…');
    } on PurchaseUnavailableException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
              color: feature.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(feature.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-line status strip on the paywall.
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
