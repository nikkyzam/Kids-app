import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/activity_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/activity.dart';
import '../../models/activity_completion.dart';
import '../../models/child_profile.dart';
import '../../theme/app_theme.dart';
import '../../utils/clock.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Every day'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_EveryDayTab(), _CompletedTab()],
        ),
      ),
    );
  }
}

/// Every day back to the child's first, whether or not the parent opened the
/// app that day. Selection is deterministic, so a day that was missed can
/// still be looked up — which is the whole point: a parent who was in hospital
/// for a week should be able to see what they missed, not just be told they
/// broke a streak.
class _EveryDayTab extends StatelessWidget {
  const _EveryDayTab();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    if (profile == null) return const SizedBox.shrink();

    return Consumer<ActivityProvider>(
      builder: (context, ap, _) {
        final today = Clock.today();
        final dob = DateTime(profile.dateOfBirth.year,
            profile.dateOfBirth.month, profile.dateOfBirth.day);
        // At least today, even for a profile whose date of birth is somehow in
        // the future.
        final dayCount = today.difference(dob).inDays + 1;
        final days = dayCount < 1 ? 1 : dayCount;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: days,
          itemBuilder: (context, index) {
            // Counted back from today by calendar components so a
            // daylight-saving transition cannot repeat or skip a date.
            final day = DateTime(today.year, today.month, today.day - index);
            return _DayTile(
              day: day,
              profile: profile,
              activity: ap.activityForDay(profile, day),
              completed: ap.completedOnDay(day),
            );
          },
        );
      },
    );
  }
}

class _CompletedTab extends StatelessWidget {
  const _CompletedTab();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Consumer<ActivityProvider>(
        builder: (context, ap, _) {
          final completions = ap.recentCompletions;

          if (completions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No activities completed yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Complete today\'s challenge to start your history!',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          // Group by month
          final grouped = <String, List<_CompletionEntry>>{};
          for (final completion in completions) {
            final activity = ap.activityForCompletion(completion);
            final monthKey = DateFormat('MMMM yyyy')
                .format(DateTime.parse(completion.dateKey));
            grouped.putIfAbsent(monthKey, () => []).add(
                _CompletionEntry(completion: completion, activity: activity));
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
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.2),
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

class _DayTile extends StatelessWidget {
  final DateTime day;
  final ChildProfile profile;
  final PlayActivity? activity;
  final bool completed;

  const _DayTile({
    required this.day,
    required this.profile,
    required this.activity,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final act = activity;
    final isToday = DateUtils.isSameDay(day, Clock.today());
    final color =
        act == null ? AppTheme.primary : skillColorFor(act.skillCategory);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: act == null ? null : () => _showDetail(context, act),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    completed
                        ? Icons.check_rounded
                        : Icons.play_circle_outline_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday
                            ? 'Today'
                            : DateFormat('EEE, MMM d').format(day),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        act?.title ?? 'No activity for this age yet',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (completed)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, PlayActivity act) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(DateFormat('EEEE, d MMMM y').format(day),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.6)),
            const SizedBox(height: 6),
            Text(act.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${act.skillTargeted} · ${act.durationMins} min',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            const _DetailHeading('Materials'),
            Text(act.materials.map((m) => '• $m').join('\n'),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.6)),
            const SizedBox(height: 16),
            const _DetailHeading('Steps'),
            Text(
              act.instructions
                  .asMap()
                  .entries
                  .map((e) => '${e.key + 1}. ${e.value}')
                  .join('\n'),
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeading extends StatelessWidget {
  final String text;
  const _DetailHeading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 1.2)),
      );
}

Color skillColorFor(SkillCategory category) {
  switch (category) {
    case SkillCategory.grossMotor:
      return AppTheme.grossMotorColor;
    case SkillCategory.fineMotor:
      return AppTheme.fineMotorColor;
    case SkillCategory.language:
      return AppTheme.languageColor;
    case SkillCategory.cognitive:
      return AppTheme.cognitiveColor;
    case SkillCategory.socialEmotional:
      return AppTheme.socialEmotionalColor;
    case SkillCategory.sensory:
      return AppTheme.sensoryColor;
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

  Color get skillColor => entry.activity == null
      ? AppTheme.primary
      : skillColorFor(entry.activity!.skillCategory);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d')
        .format(DateTime.parse(entry.completion.dateKey));
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
                  color: skillColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_rounded, color: skillColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity?.title ?? 'Activity',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // The date and the skill pill are natural-width, so a
                        // long skill label overflowed the row on narrower
                        // phones and at larger text scales.
                        Flexible(
                          child: Text(
                            dateStr,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (activity != null) ...[
                          const Text(' · ',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 13)),
                          Flexible(
                              child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: skillColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(activity.skillCategory.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: skillColor,
                                    fontWeight: FontWeight.w600)),
                          )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (activity != null)
                Text('${activity.durationMins}m',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
