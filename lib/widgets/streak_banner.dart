import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';

/// The three numbers a parent checks at a glance: the streak, the running
/// total, and whether this week has gaps in it.
///
/// One card divided into three columns rather than three separate pills. The
/// pills each had their own internal layout — one stacked, one wrapped onto a
/// third line, one had no icon at all — so the row read as three unrelated
/// things of three different heights. Sharing a card and a column template
/// makes them scan as one row of stats, which is what they are.
class StreakBanner extends StatelessWidget {
  const StreakBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, ap, _) {
        final streak = ap.currentStreak;
        final total = ap.totalCompletions;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Stat(
                      icon: Icons.local_fire_department_rounded,
                      color: streak > 0
                          ? const Color(0xFFFF7043)
                          : AppTheme.textMuted,
                      value: '$streak',
                      // "day streak" wrapped onto a second line at every text
                      // scale above 1.0. The icon already says which streak.
                      label: streak == 1 ? 'day' : 'days',
                      emphasised: streak >= 3,
                    ),
                  ),
                  const _Divider(),
                  Expanded(
                    child: _Stat(
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.success,
                      value: '$total',
                      label: 'done',
                    ),
                  ),
                  const _Divider(),
                  Expanded(child: _WeekColumn()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A hairline between columns, inset so it does not touch the card's corners.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(width: 1, color: AppTheme.border),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool emphasised;

  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: emphasised ? color : AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The last seven days as dots, newest at the right, sharing the column
/// template so it lines up with the two numeric stats beside it.
class _WeekColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, ap, _) {
        final today = Clock.today();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 21,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(7, (i) {
                    // Calendar components, not `subtract(Duration(days: n))`: a
                    // Duration is exactly 24 hours, so across a daylight-saving
                    // transition a dot lands on the wrong date.
                    final day =
                        DateTime(today.year, today.month, today.day - (6 - i));
                    final isToday = i == 6;
                    final done = ap.completedOnDay(day);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? AppTheme.success
                              : isToday
                                  ? AppTheme.primary.withValues(alpha: 0.25)
                                  : AppTheme.textMuted.withValues(alpha: 0.18),
                          border: isToday && !done
                              ? Border.all(color: AppTheme.primary, width: 1.5)
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'this week',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
