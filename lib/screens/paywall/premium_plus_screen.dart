import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_theme.dart';

class PremiumPlusScreen extends StatefulWidget {
  const PremiumPlusScreen({super.key});

  @override
  State<PremiumPlusScreen> createState() => _PremiumPlusScreenState();
}

class _PremiumPlusScreenState extends State<PremiumPlusScreen> {
  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();

    // The purchase, not the effective unlock: during the trial everything is
    // on, and showing the "already active" screen then would leave a parent no
    // way to actually subscribe.
    if (ap.hasPurchasedPremiumPlus) {
      return _buildAlreadyActiveScreen(context);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildFeatureList(context),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSubscribeButton(context, ap),
              ),
              const SizedBox(height: 12),
              Center(child: _buildRestoreButton(context, ap)),
              const SizedBox(height: 16),
              _buildFinePrint(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyActiveScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    size: 64, color: Color(0xFFF5A623)),
                const SizedBox(height: 24),
                Text(
                  'Premium Plus Active',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Premium Plus features are ready to use.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF3B6FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Premium Plus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything your child\'s development deserves',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 20),
          // Store-localised: a hard-coded figure would disagree with what the
          // subscription sheet charges outside the US.
          Text(
            PurchaseService.instance.priceFor(Entitlement.premiumPlus) ??
                'See price in store',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            // Was "less than 67 cents a month", which only held while the
            // price was hard-coded at \$7.99 and would be wrong in any other
            // currency.
            'Billed once a year. Cancel anytime.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      const _PlusFeature(
          Icons.workspace_premium_rounded,
          'Everything in Premium',
          'Full activity library, milestone tracking and pediatrician export'),
      const _PlusFeature(Icons.show_chart_rounded, 'Growth Tracker',
          'Plot weight, height & head circumference over time'),
      const _PlusFeature(
          Icons.psychology_rounded,
          'Developmental Leap Calendar',
          'Know when fussy periods are coming and why'),
      const _PlusFeature(Icons.calendar_month_rounded, 'Smart 4-Week Plan',
          'Personalised activity calendar targeting skill gaps'),
      const _PlusFeature(Icons.summarize_rounded, 'Weekly Family Report',
          'Shareable weekly digest for grandparents & doctors'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: features.map((f) => _FeatureTile(feature: f)).toList(),
      ),
    );
  }

  Widget _buildSubscribeButton(BuildContext context, ActivityProvider ap) {
    final store = PurchaseService.instance;
    // Prefer the store's localised subscription price over a hard-coded one.
    final price = store.priceFor(Entitlement.premiumPlus);

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF5A623),
        foregroundColor: Colors.white,
      ),
      onPressed: store.isAvailable
          ? () async {
              // Entitlement arrives via the purchase stream; this screen swaps
              // to its "already active" state once it lands.
              try {
                await PurchaseService.instance.buy(Entitlement.premiumPlus);
              } on PurchaseUnavailableException catch (e) {
                if (context.mounted) _showMessage(context, e.message);
              }
            }
          : null,
      child: Text(
        store.isAvailable
            ? 'Subscribe — ${price ?? "see price in store"}'
            : 'Store unavailable',
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildRestoreButton(BuildContext context, ActivityProvider ap) {
    return TextButton(
      onPressed: () async {
        // Restored entitlements arrive on the purchase stream, which flips this
        // screen to its "already active" state.
        try {
          await ap.restorePurchases();
          if (context.mounted) {
            _showMessage(context, 'Checking for previous purchases…');
          }
        } on PurchaseUnavailableException catch (e) {
          if (context.mounted) _showMessage(context, e.message);
        }
      },
      child: const Text('Restore subscription'),
    );
  }

  Widget _buildFinePrint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Subscription auto-renews annually. Cancel anytime in device settings. Purchasing confirms acceptance of our Terms of Service.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
      ),
    );
  }
}

class _PlusFeature {
  final IconData icon;
  final String name;
  final String description;
  const _PlusFeature(this.icon, this.name, this.description);
}

class _FeatureTile extends StatelessWidget {
  final _PlusFeature feature;
  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, size: 32, color: AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
