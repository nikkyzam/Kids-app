import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/activities_data.dart';
import '../../models/activity.dart';
import '../../providers/activity_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/clock.dart';

class ActivityPlanScreen extends StatefulWidget {
  const ActivityPlanScreen({super.key});

  @override
  State<ActivityPlanScreen> createState() => _ActivityPlanScreenState();
}

class _ActivityPlanScreenState extends State<ActivityPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PlayActivity> _plan = [];
  List<SkillCategory> _weakestSkills = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePlan();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generatePlan() {
    final ap = context.read<ActivityProvider>();
    final profile = context.read<ProfileProvider>().activeProfile;
    if (profile == null) return;

    final ageInWeeks = profile.contentAgeInWeeks;
    final coverage = ap.skillCoverage;

    const allCategories = SkillCategory.values;
    final sorted = [...allCategories]..sort((a, b) {
        final aCount = coverage[a] ?? 0;
        final bCount = coverage[b] ?? 0;
        return aCount.compareTo(bCount);
      });

    final weakest = sorted.take(3).toList();

    final ageActivities = ActivitiesData.all
        .where((a) =>
            a.ageBandMinWeeks <= ageInWeeks && ageInWeeks < a.ageBandMaxWeeks)
        .toList();

    if (ageActivities.isEmpty) {
      setState(() {
        _weakestSkills = weakest;
        _plan = [];
      });
      return;
    }

    final weakActivities =
        ageActivities.where((a) => weakest.contains(a.skillCategory)).toList();
    final otherActivities =
        ageActivities.where((a) => !weakest.contains(a.skillCategory)).toList();

    final fallbackWeak =
        weakActivities.isEmpty ? ageActivities : weakActivities;
    final fallbackOther =
        otherActivities.isEmpty ? ageActivities : otherActivities;

    PlayActivity pick(List<PlayActivity> pool, int index) {
      if (pool.isEmpty) return ageActivities[index % ageActivities.length];
      return pool[(index * 31 + 7) % pool.length];
    }

    final entries = <PlayActivity>[];
    for (int day = 0; day < 28; day++) {
      final dayOfWeek = day % 7;
      if (dayOfWeek < 4) {
        final weakIndex = dayOfWeek % weakest.length;
        final categoryActivities = fallbackWeak
            .where((a) => a.skillCategory == weakest[weakIndex])
            .toList();
        final pool =
            categoryActivities.isEmpty ? fallbackWeak : categoryActivities;
        entries.add(pick(pool, day));
      } else if (dayOfWeek < 6) {
        entries.add(pick(fallbackOther, day));
      } else {
        final mostPopular = fallbackWeak[(7 * 31 + 7) % fallbackWeak.length];
        entries.add(mostPopular);
      }
    }

    setState(() {
      _weakestSkills = weakest;
      _plan = entries;
    });
  }

  Color _skillColor(SkillCategory category) {
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

  static const List<String> _dayLetters = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    final ap = context.watch<ActivityProvider>();

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('4-Week Plan')),
        body: const Center(child: Text('No child profile found.')),
      );
    }

    final today = Clock.now();
    final planEnd = today.add(const Duration(days: 27));
    final dateRangeLabel =
        '${DateFormat('MMM d').format(today)} – ${DateFormat('MMM d').format(planEnd)}';

    final weakSkillLabels = _weakestSkills.map((s) => s.label).join(', ');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('4-Week Plan'),
        bottom: _plan.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                labelStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(text: 'Week 1'),
                  Tab(text: 'Week 2'),
                  Tab(text: 'Week 3'),
                  Tab(text: 'Week 4'),
                ],
              ),
      ),
      body: _plan.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _HeaderCard(
                  childName: profile.name,
                  weakSkillLabels: weakSkillLabels,
                  dateRangeLabel: dateRangeLabel,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(4, (weekIndex) {
                      final weekStart = weekIndex * 7;
                      final weekDays = _plan.sublist(
                          weekStart, (weekStart + 7).clamp(0, _plan.length));
                      return _WeekTab(
                        weekIndex: weekIndex,
                        activities: weekDays,
                        activityProvider: ap,
                        skillColor: _skillColor,
                        dayLetters: _dayLetters,
                        childName: profile.name,
                        weakSkillLabels: weakSkillLabels,
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.childName,
    required this.weakSkillLabels,
    required this.dateRangeLabel,
  });

  final String childName;
  final String weakSkillLabels;
  final String dateRangeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Personalised Plan for $childName',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Focused on: $weakSkillLabels',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateRangeLabel,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekTab extends StatelessWidget {
  const _WeekTab({
    required this.weekIndex,
    required this.activities,
    required this.activityProvider,
    required this.skillColor,
    required this.dayLetters,
    required this.childName,
    required this.weakSkillLabels,
  });

  final int weekIndex;
  final List<PlayActivity> activities;
  final ActivityProvider activityProvider;
  final Color Function(SkillCategory) skillColor;
  final List<String> dayLetters;
  final String childName;
  final String weakSkillLabels;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        ...List.generate(activities.length, (i) {
          final dayOffset = weekIndex * 7 + i;
          final isToday = dayOffset == 0;
          final activity = activities[i];
          final color = skillColor(activity.skillCategory);

          final isCompleted = isToday && activityProvider.isCompleted;

          return _DayTile(
            dayLetter: dayLetters[i % 7],
            activity: activity,
            skillColor: color,
            isToday: isToday,
            isCompleted: isCompleted,
          );
        }),
        const SizedBox(height: 12),
        _WhyThisPlanCard(
          childName: childName,
          weakSkillLabels: weakSkillLabels,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.dayLetter,
    required this.activity,
    required this.skillColor,
    required this.isToday,
    required this.isCompleted,
  });

  final String dayLetter;
  final PlayActivity activity;
  final Color skillColor;
  final bool isToday;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color:
            isToday ? AppTheme.primary.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTheme.primary.withValues(alpha: 0.3)
              : const Color(0xFFEEF0F7),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _DayCircle(
          letter: dayLetter,
          color: isToday ? AppTheme.primary : skillColor,
        ),
        title: Text(
          activity.title,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isToday ? AppTheme.primary : AppTheme.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _SkillChip(
                label: activity.skillCategory.label,
                color: skillColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${activity.durationMins} min',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        trailing: isToday && isCompleted
            ? const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 22,
              )
            : null,
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _WhyThisPlanCard extends StatelessWidget {
  const _WhyThisPlanCard({
    required this.childName,
    required this.weakSkillLabels,
  });

  final String childName;
  final String weakSkillLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: AppTheme.secondary),
              SizedBox(width: 6),
              Text(
                'Why this plan?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Based on $childName's activity history, these skill areas have "
            'the least practice: $weakSkillLabels. This plan weights toward '
            'those areas to build balanced development.',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
