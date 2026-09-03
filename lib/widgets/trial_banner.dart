import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import '../screens/paywall/paywall_screen.dart';
import '../theme/app_theme.dart';

/// A slim strip saying the trial is running and how long is left.
///
/// Deliberately quiet and always present for the fortnight rather than loud
/// and only at the end: a parent should know from the start that they are
/// trying something, and should not be ambushed on day thirteen. It disappears
/// entirely once the trial ends or the app is bought — there is nothing to say
/// then, and the paywall is a tap away in Settings either way.
class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    if (!ap.isOnTrialOnly) return const SizedBox.shrink();

    final days = ap.trialDaysRemaining;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.lock_open_rounded,
                    size: 15, color: AppTheme.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    days == 1
                        ? 'Last day of your free trial'
                        : '$days days left in your free trial',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppTheme.success),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
