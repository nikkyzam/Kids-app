import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/milestones_data.dart';
import '../../data/red_flags_data.dart';
import '../../models/child_profile.dart';
import '../../models/milestone.dart';
import '../../providers/milestone_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

class PediatricianPrepScreen extends StatelessWidget {
  const PediatricianPrepScreen({super.key});

  static const List<int> _visitAges = [1, 2, 4, 6, 9, 12, 15, 18, 24, 30, 36];

  int? _lastVisitAge(int ageInMonths) {
    int? last;
    for (final age in _visitAges) {
      if (age <= ageInMonths) last = age;
    }
    return last;
  }

  int? _nextVisitAge(int ageInMonths) {
    for (final age in _visitAges) {
      if (age > ageInMonths) return age;
    }
    return null;
  }

  Color _domainColor(MilestoneDomain domain) {
    switch (domain) {
      case MilestoneDomain.grossMotor:
        return AppTheme.grossMotorColor;
      case MilestoneDomain.fineMotor:
        return AppTheme.fineMotorColor;
      case MilestoneDomain.language:
        return AppTheme.languageColor;
      case MilestoneDomain.cognitive:
        return AppTheme.cognitiveColor;
      case MilestoneDomain.socialEmotional:
        return AppTheme.socialEmotionalColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor Visit Prep')),
        body: const Center(child: Text('No profile found.')),
      );
    }

    return Consumer<MilestoneProvider>(
      builder: (context, mp, _) {
        final ageInMonths = profile.ageInMonths;
        final nextAge = _nextVisitAge(ageInMonths);
        final lastAge = _lastVisitAge(ageInMonths);
        final checkAge = nextAge ?? lastAge;

        // Collect achieved IDs for red flag lookup
        final achievedIds = MilestonesData.all
            .where((m) => mp.isAchieved(m.id))
            .map((m) => m.id)
            .toSet();

        // Build milestone-gap questions (cap at 5 to leave room for always-on questions)
        final gapMilestones = MilestonesData.all
            .where(
                (m) => m.ageGroupMonths <= ageInMonths && !mp.isAchieved(m.id))
            .toList();

        final alwaysQuestions = [
          "Is ${profile.name}'s weight and height on track for their age?",
          "What should I expect developmentally over the next few months?",
          "Are there any screenings or vaccines due at this visit?",
        ];

        final gapQuestions = gapMilestones
            .take((8 - alwaysQuestions.length).clamp(0, 8))
            .map((m) =>
                "Should I be concerned that ${profile.name} hasn't ${_lcFirst(m.description)} yet?")
            .toList();

        final allQuestions = [...gapQuestions, ...alwaysQuestions];

        // Domains covered at the check age
        final domainsAtCheckAge = checkAge == null
            ? <MilestoneDomain>{}
            : MilestonesData.all
                .where((m) => m.ageGroupMonths == checkAge)
                .map((m) => m.domain)
                .toSet();

        // Red flags
        final redFlags = RedFlagsData.activeFor(ageInMonths, achievedIds);

        // Progress counts for current age window
        final expectedMilestones = MilestonesData.all
            .where((m) => m.ageGroupMonths <= ageInMonths)
            .toList();
        final expectedCount = expectedMilestones.length;
        final achievedExpectedCount =
            expectedMilestones.where((m) => mp.isAchieved(m.id)).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Doctor Visit Prep'),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _VisitInfoCard(
                profile: profile,
                nextAge: nextAge,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                icon: Icons.medical_services_outlined,
                title: 'What your doctor will check',
              ),
              _DomainsCard(
                domains: domainsAtCheckAge,
                checkAge: checkAge,
                domainColor: _domainColor,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                icon: Icons.help_outline_rounded,
                title: 'Questions to ask',
              ),
              _QuestionsCard(
                questions: allQuestions,
                childName: profile.name,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                icon: Icons.warning_amber_rounded,
                title: 'Things to mention',
              ),
              _RedFlagsCard(redFlags: redFlags),
              const SizedBox(height: 16),
              _SectionHeader(
                icon: Icons.bar_chart_rounded,
                title: 'Milestone summary',
              ),
              _MilestoneSummaryCard(
                name: profile.name,
                achievedCount: achievedExpectedCount,
                totalCount: expectedCount,
                ageInMonths: ageInMonths,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Lowercases the first letter of a string.
  String _lcFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}

// ─── Visit Info Card ──────────────────────────────────────────────────────────

class _VisitInfoCard extends StatelessWidget {
  const _VisitInfoCard({
    required this.profile,
    required this.nextAge,
  });

  final ChildProfile profile;
  final int? nextAge;

  @override
  Widget build(BuildContext context) {
    final visitText = nextAge != null
        ? 'Next well-baby visit: around $nextAge months'
        : "You're past the scheduled visits—annual checkups from here!";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF3B6FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visitText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.displayAge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Domains Card ─────────────────────────────────────────────────────────────

class _DomainsCard extends StatelessWidget {
  const _DomainsCard({
    required this.domains,
    required this.checkAge,
    required this.domainColor,
  });

  final Set<MilestoneDomain> domains;
  final int? checkAge;
  final Color Function(MilestoneDomain) domainColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: domains.isEmpty
            ? Text(
                'No visit data available.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (checkAge != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'At the $checkAge-month visit, expect a check on:',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: domains.map((domain) {
                      final color = domainColor(domain);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withOpacity(0.4), width: 1),
                        ),
                        child: Text(
                          domain.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Questions Card ───────────────────────────────────────────────────────────

class _QuestionsCard extends StatelessWidget {
  const _QuestionsCard({
    required this.questions,
    required this.childName,
  });

  final List<String> questions;
  final String childName;

  void _copyAll(BuildContext context) {
    final text = questions
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Questions copied to clipboard'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tap the button to copy all questions before your visit.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: AppTheme.primary,
                  ),
                  onPressed: () => _copyAll(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copy all',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textDark,
                          fontFamily: 'Nunito',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Red Flags Card ───────────────────────────────────────────────────────────

class _RedFlagsCard extends StatelessWidget {
  const _RedFlagsCard({required this.redFlags});

  final List<RedFlag> redFlags;

  @override
  Widget build(BuildContext context) {
    if (redFlags.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.success, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nothing flagged — great progress!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Bring these up with your doctor:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            ...redFlags.map((flag) => _RedFlagTile(flag: flag)),
          ],
        ),
      ),
    );
  }
}

class _RedFlagTile extends StatelessWidget {
  const _RedFlagTile({required this.flag});

  final RedFlag flag;

  Color _domainColor(MilestoneDomain domain) {
    switch (domain) {
      case MilestoneDomain.grossMotor:
        return AppTheme.grossMotorColor;
      case MilestoneDomain.fineMotor:
        return AppTheme.fineMotorColor;
      case MilestoneDomain.language:
        return AppTheme.languageColor;
      case MilestoneDomain.cognitive:
        return AppTheme.cognitiveColor;
      case MilestoneDomain.socialEmotional:
        return AppTheme.socialEmotionalColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flag.concern,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontFamily: 'Nunito',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  flag.domain.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _domainColor(flag.domain),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Summary Card ───────────────────────────────────────────────────

class _MilestoneSummaryCard extends StatelessWidget {
  const _MilestoneSummaryCard({
    required this.name,
    required this.achievedCount,
    required this.totalCount,
    required this.ageInMonths,
  });

  final String name;
  final int achievedCount;
  final int totalCount;
  final int ageInMonths;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : achievedCount / totalCount;

    final progressColor = progress >= 0.8
        ? AppTheme.success
        : progress >= 0.5
            ? AppTheme.secondary
            : AppTheme.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$name has achieved $achievedCount of $totalCount expected milestones',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFEEF0F7),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Based on milestones up to $ageInMonths months',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
