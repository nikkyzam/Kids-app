import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/activity_provider.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';

class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, ap, _) {
        final today = Clock.now();
        // Build Mon–Sun of current week
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

        final completedThisWeek =
            days.where((d) => ap.completedOnDay(d)).length;
        final bestSkill = _bestSkillThisWeek(ap, days);

        // Only show if at least one day of the week has passed since Monday
        final daysSinceMonday = today.weekday - 1; // 0 on Monday
        if (daysSinceMonday == 0 && completedThisWeek == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_view_week_rounded,
                          size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text('This Week',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: completedThisWeek == 7
                              ? AppTheme.successLight
                              : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$completedThisWeek/7 days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: completedThisWeek == 7
                                ? AppTheme.success
                                : AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: days.map((day) {
                      final isToday = _isSameDay(day, today);
                      final done = ap.completedOnDay(day);
                      final isFuture = day.isAfter(today) && !isToday;
                      return _DayDot(
                        label: DateFormat('E').format(day).substring(0, 1),
                        dayNum: day.day.toString(),
                        done: done,
                        isToday: isToday,
                        isFuture: isFuture,
                      );
                    }).toList(),
                  ),
                  if (bestSkill != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 6),
                        // Skill labels are long enough to overflow this row on
                        // a 360px phone.
                        Flexible(
                          child: Text(
                            'Focus: ${bestSkill.label}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (completedThisWeek == 7) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🏆 Perfect week! Every day completed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SkillCategory? _bestSkillThisWeek(ActivityProvider ap, List<DateTime> days) {
    final counts = <SkillCategory, int>{};
    for (final day in days) {
      if (!ap.completedOnDay(day)) continue;
      final completion = ap.allCompletions.where((c) {
        final d = DateTime.parse(c.dateKey);
        return _isSameDay(d, day);
      }).firstOrNull;
      if (completion == null) continue;
      final activity = ap.activityForCompletion(completion);
      if (activity != null) {
        counts[activity.skillCategory] =
            (counts[activity.skillCategory] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayDot extends StatelessWidget {
  final String label;
  final String dayNum;
  final bool done;
  final bool isToday;
  final bool isFuture;

  const _DayDot({
    required this.label,
    required this.dayNum,
    required this.done,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isToday ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppTheme.success
                : isToday
                    ? AppTheme.primaryLight
                    : Colors.transparent,
            border: Border.all(
              color: done
                  ? AppTheme.success
                  : isToday
                      ? AppTheme.primary
                      : isFuture
                          ? AppTheme.textMuted.withValues(alpha: 0.15)
                          : AppTheme.textMuted.withValues(alpha: 0.3),
              width: isToday ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? AppTheme.primary
                          : isFuture
                              ? AppTheme.textMuted.withValues(alpha: 0.4)
                              : AppTheme.textMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
