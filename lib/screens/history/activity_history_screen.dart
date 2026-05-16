import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/activity_provider.dart';
import '../../models/activity.dart';
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No activities completed yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Complete today\'s challenge to start your history!',
                      style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          // Group by month
          final grouped = <String, List<_CompletionEntry>>{};
          for (final completion in completions) {
            final activity = ap.activityForCompletion(completion);
            final monthKey = DateFormat('MMMM yyyy').format(DateTime.parse(completion.dateKey));
            grouped.putIfAbsent(monthKey, () => []).add(_CompletionEntry(completion: completion, activity: activity));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (context, monthIndex) {
              final month = grouped.keys.elementAt(monthIndex);
              final entries = grouped[month]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      month.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.2),
                    ),
                  ),
                  ...entries.map((entry) => _HistoryTile(entry: entry)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CompletionEntry {
  final completion;
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: skillColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_rounded, color: skillColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity?.title ?? 'Activity', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
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
                            child: Text(activity.skillCategory.label,
                                style: TextStyle(fontSize: 10, color: skillColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (activity != null)
                Text('${activity.durationMins}m',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
