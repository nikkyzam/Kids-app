import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/activity_provider.dart';
import '../../models/activity.dart';
import '../../models/activity_completion.dart';
import '../../theme/app_theme.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity History')),
      body: Consumer<ActivityProvider>(
        builder: (context, ap, _) {
          final completions = ap.recentCompletions;

          if (completions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text('No activities yet', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Complete today\'s challenge to start building your history!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildSummaryBar(context, ap),
              Expanded(child: _buildList(context, ap, completions)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, ActivityProvider ap) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryStat(label: 'Total', value: ap.totalCompletions.toString(), icon: Icons.check_circle_rounded, color: AppTheme.success),
          _VerticalDivider(),
          _SummaryStat(label: 'Current Streak', value: '${ap.currentStreak}d', icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF7043)),
          _VerticalDivider(),
          _SummaryStat(label: 'Best Streak', value: '${ap.longestStreak}d', icon: Icons.emoji_events_rounded, color: AppTheme.secondary),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ActivityProvider ap, List<ActivityCompletion> completions) {
    // Group by month
    final grouped = <String, List<_CompletionEntry>>{};
    for (final completion in completions) {
      final activity = ap.activityForCompletion(completion);
      final monthKey = DateFormat('MMMM yyyy').format(DateTime.parse(completion.dateKey));
      grouped.putIfAbsent(monthKey, () => []).add(_CompletionEntry(completion: completion, activity: activity));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: grouped.length,
      itemBuilder: (context, monthIndex) {
        final month = grouped.keys.elementAt(monthIndex);
        final entries = grouped[month]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    month.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            ...entries.map((entry) => _HistoryTile(entry: entry)),
          ],
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.primary.withOpacity(0.15));
  }
}

class _CompletionEntry {
  final ActivityCompletion completion;
  final PlayActivity? activity;
  const _CompletionEntry({required this.completion, required this.activity});
}

class _HistoryTile extends StatelessWidget {
  final _CompletionEntry entry;
  const _HistoryTile({required this.entry});

  Color get skillColor {
    if (entry.activity == null) return AppTheme.primary;
    switch (entry.activity!.skillCategory) {
      case SkillCategory.grossMotor: return AppTheme.grossMotorColor;
      case SkillCategory.fineMotor: return AppTheme.fineMotorColor;
      case SkillCategory.language: return AppTheme.languageColor;
      case SkillCategory.cognitive: return AppTheme.cognitiveColor;
      case SkillCategory.socialEmotional: return AppTheme.socialEmotionalColor;
      case SkillCategory.sensory: return AppTheme.sensoryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(DateTime.parse(entry.completion.dateKey));
    final activity = entry.activity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: skillColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_rounded, color: skillColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity?.title ?? 'Activity',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(dateStr, style: Theme.of(context).textTheme.bodyMedium),
                        if (activity != null) ...[
                          const Text(' · ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: skillColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activity.skillCategory.label,
                              style: TextStyle(fontSize: 10, color: skillColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (activity != null)
                Text(
                  '${activity.durationMins}m',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
