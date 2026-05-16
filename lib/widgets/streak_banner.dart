import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';

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
          child: Row(
            children: [
              Expanded(child: _StatPill(
                icon: Icons.local_fire_department_rounded,
                iconColor: streak > 0 ? const Color(0xFFFF7043) : AppTheme.textMuted,
                value: streak.toString(),
                label: 'day streak',
                highlight: streak >= 3,
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatPill(
                icon: Icons.check_circle_rounded,
                iconColor: AppTheme.success,
                value: total.toString(),
                label: 'activities done',
              )),
              const SizedBox(width: 10),
              Expanded(child: _WeekDots()),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool highlight;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? iconColor.withOpacity(0.08) : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(12),
        border: highlight ? Border.all(color: iconColor.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: highlight ? iconColor : AppTheme.textDark)),
                Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, ap, _) {
        final today = DateTime.now();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('this week', style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final day = today.subtract(Duration(days: 6 - i));
                  final isToday = i == 6;
                  final done = ap.completedOnDay(day);
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppTheme.success
                          : isToday
                              ? AppTheme.primary.withOpacity(0.3)
                              : AppTheme.textMuted.withOpacity(0.2),
                      border: isToday && !done ? Border.all(color: AppTheme.primary, width: 1.5) : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
