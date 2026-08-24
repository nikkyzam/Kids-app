import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/milestones_data.dart';
import '../../data/red_flags_data.dart';
import '../../models/milestone.dart';
import '../../providers/milestone_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Status enum
// ---------------------------------------------------------------------------

enum _SnapshotStatus { onTrack, someGaps, checkWithDoctor }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DevelopmentSnapshotScreen extends StatefulWidget {
  const DevelopmentSnapshotScreen({super.key});

  @override
  State<DevelopmentSnapshotScreen> createState() =>
      _DevelopmentSnapshotScreenState();
}

class _DevelopmentSnapshotScreenState extends State<DevelopmentSnapshotScreen> {
  // Tracks which red flags the user has acknowledged locally.
  final Set<String> _notedRedFlags = {};

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Development Snapshot')),
        body: const Center(child: Text('No child profile found.')),
      );
    }

    return Consumer<MilestoneProvider>(
      builder: (context, mp, _) {
        if (mp.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Development Snapshot')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final ageInMonths = profile.ageInMonths;
        final childName = profile.name;

        // ── Compute overall status ─────────────────────────────────────────
        final relevantGroups =
            MilestonesData.ageGroups.where((g) => g <= ageInMonths).toList();

        int totalExpected = 0;
        int totalAchieved = 0;
        for (final g in relevantGroups) {
          final ms = MilestonesData.forAgeGroup(g);
          totalExpected += ms.length;
          totalAchieved += ms.where((m) => mp.isAchieved(m.id)).length;
        }

        final ratio = totalExpected == 0 ? 1.0 : totalAchieved / totalExpected;

        // Build achieved ids for red-flag lookup
        final achievedIds = mp.achievements.map((a) => a.milestoneId).toSet();
        final redFlags = RedFlagsData.activeFor(ageInMonths, achievedIds);
        final hasRedFlags = redFlags.isNotEmpty;

        _SnapshotStatus status;
        if (ratio < 0.5 || hasRedFlags) {
          status = _SnapshotStatus.checkWithDoctor;
        } else if (ratio < 0.75) {
          status = _SnapshotStatus.someGaps;
        } else {
          status = _SnapshotStatus.onTrack;
        }

        // ── Next age group (looking ahead) ────────────────────────────────
        final nextGroup = MilestonesData.ageGroups
            .cast<int?>()
            .firstWhere((g) => g! > ageInMonths, orElse: () => null);

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: CustomScrollView(
            slivers: [
              // ── AppBar ─────────────────────────────────────────────────
              const SliverAppBar(
                title: Text('Development Snapshot'),
                pinned: true,
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.textDark,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),

              // ── 1. Hero status card ────────────────────────────────────
              SliverToBoxAdapter(
                child: _StatusHeroCard(
                  status: status,
                  childName: childName,
                  achievedCount: totalAchieved,
                  expectedCount: totalExpected,
                ),
              ),

              // ── 2. Red flag section ────────────────────────────────────
              if (hasRedFlags) ...[
                const SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Worth Mentioning to Your Doctor',
                    icon: Icons.health_and_safety_outlined,
                    iconColor: AppTheme.error,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _RedFlagSection(
                    redFlags: redFlags,
                    childName: childName,
                    notedIds: _notedRedFlags,
                    onToggleNoted: (id) {
                      setState(() {
                        if (_notedRedFlags.contains(id)) {
                          _notedRedFlags.remove(id);
                        } else {
                          _notedRedFlags.add(id);
                        }
                      });
                    },
                  ),
                ),
              ],

              // ── 3. Age group progress cards ────────────────────────────
              const SliverToBoxAdapter(
                child: _SectionHeader(
                  title: "Progress by Age Group",
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppTheme.primary,
                ),
              ),

              if (relevantGroups.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'No age groups to show yet — check back soon!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),

              for (final group in relevantGroups)
                SliverToBoxAdapter(
                  child: _AgeGroupCard(
                    ageGroup: group,
                    milestoneProvider: mp,
                  ),
                ),

              // ── 4. Looking ahead ───────────────────────────────────────
              if (nextGroup != null) ...[
                const SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Looking Ahead',
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppTheme.textMuted,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _LookingAheadCard(ageGroup: nextGroup),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Status hero card
// ---------------------------------------------------------------------------

class _StatusHeroCard extends StatelessWidget {
  const _StatusHeroCard({
    required this.status,
    required this.childName,
    required this.achievedCount,
    required this.expectedCount,
  });

  final _SnapshotStatus status;
  final String childName;
  final int achievedCount;
  final int expectedCount;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: config.bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(config.emoji, style: const TextStyle(fontSize: 42)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: config.textColor,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$childName's snapshot",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: config.textColor.withValues(alpha: 0.7),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              config.description,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: config.textColor.withValues(alpha: 0.85),
                height: 1.4,
                fontFamily: 'Nunito',
              ),
            ),
            if (expectedCount > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: achievedCount / expectedCount,
                  minHeight: 8,
                  backgroundColor: config.textColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$achievedCount of $expectedCount milestones achieved',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: config.textColor.withValues(alpha: 0.7),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(_SnapshotStatus s) {
    switch (s) {
      case _SnapshotStatus.onTrack:
        return _StatusConfig(
          emoji: '✅',
          label: 'On Track',
          description:
              'Great news — $childName is hitting most milestones for their age. '
              'Keep up the wonderful work!',
          bgColor: const Color(0xFFE8F8EF),
          textColor: const Color(0xFF2E7D52),
        );
      case _SnapshotStatus.someGaps:
        return _StatusConfig(
          emoji: '⚠️',
          label: 'Some Gaps',
          description:
              '$childName is progressing well in many areas, though there are a few '
              'milestones still to watch. Stay consistent with play and exploration.',
          bgColor: const Color(0xFFFFF8E1),
          textColor: const Color(0xFF8A6200),
        );
      case _SnapshotStatus.checkWithDoctor:
        return _StatusConfig(
          emoji: '🩺',
          label: 'Check With Doctor',
          description:
              'Some milestones for $childName\'s age haven\'t been reached yet. '
              'It\'s a good idea to mention this at your next well-baby visit.',
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.emoji,
    required this.label,
    required this.description,
    required this.bgColor,
    required this.textColor,
  });
  final String emoji;
  final String label;
  final String description;
  final Color bgColor;
  final Color textColor;
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
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

// ---------------------------------------------------------------------------
// Red flag section
// ---------------------------------------------------------------------------

class _RedFlagSection extends StatelessWidget {
  const _RedFlagSection({
    required this.redFlags,
    required this.childName,
    required this.notedIds,
    required this.onToggleNoted,
  });

  final List<RedFlag> redFlags;
  final String childName;
  final Set<String> notedIds;
  final ValueChanged<String> onToggleNoted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'These are CDC-recommended milestones that babies at '
                "$childName's age are usually showing. "
                'Bring them up at your next visit.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                  height: 1.45,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ...redFlags.map((rf) => _RedFlagItem(
                  redFlag: rf,
                  isNoted: notedIds.contains(rf.milestoneId),
                  onToggle: () => onToggleNoted(rf.milestoneId),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RedFlagItem extends StatelessWidget {
  const _RedFlagItem({
    required this.redFlag,
    required this.isNoted,
    required this.onToggle,
  });

  final RedFlag redFlag;
  final bool isNoted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final domainColor = _domainColor(redFlag.domain);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: domainColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  redFlag.concern,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isNoted ? AppTheme.textMuted : AppTheme.textDark,
                    decoration: isNoted ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.textMuted,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  redFlag.domain.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: domainColor,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isNoted
                    ? AppTheme.success.withValues(alpha: 0.12)
                    : AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isNoted ? 'Noted ✓' : 'Noted',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isNoted ? AppTheme.success : AppTheme.error,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Age group progress card
// ---------------------------------------------------------------------------

class _AgeGroupCard extends StatelessWidget {
  const _AgeGroupCard({
    required this.ageGroup,
    required this.milestoneProvider,
  });

  final int ageGroup;
  final MilestoneProvider milestoneProvider;

  @override
  Widget build(BuildContext context) {
    final milestones = MilestonesData.forAgeGroup(ageGroup);
    final achieved =
        milestones.where((m) => milestoneProvider.isAchieved(m.id)).length;
    final total = milestones.length;
    final ratio = total == 0 ? 1.0 : achieved / total;

    final trafficColor = _trafficColor(ratio);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: trafficColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$ageGroup Month${ageGroup == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: trafficColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$achieved/$total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: trafficColor,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: trafficColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(trafficColor),
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Milestone list
            ...milestones.map(
              (m) => _MilestoneRow(
                milestone: m,
                isAchieved: milestoneProvider.isAchieved(m.id),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _trafficColor(double ratio) {
    if (ratio >= 1.0) return AppTheme.success;
    if (ratio >= 0.75) return const Color(0xFF8BC34A); // light green / amber
    if (ratio >= 0.5) return AppTheme.secondary; // orange-amber
    return AppTheme.error;
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.isAchieved,
  });

  final Milestone milestone;
  final bool isAchieved;

  @override
  Widget build(BuildContext context) {
    final domainColor = _domainColor(milestone.domain);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Domain color dot
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: domainColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              milestone.description,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isAchieved ? AppTheme.textMuted : AppTheme.textDark,
                decoration: isAchieved ? TextDecoration.lineThrough : null,
                decorationColor: AppTheme.textMuted,
                height: 1.4,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            isAchieved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: isAchieved
                ? AppTheme.success
                : AppTheme.error.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Looking ahead card
// ---------------------------------------------------------------------------

class _LookingAheadCard extends StatelessWidget {
  const _LookingAheadCard({required this.ageGroup});

  final int ageGroup;

  @override
  Widget build(BuildContext context) {
    final milestones = MilestonesData.forAgeGroup(ageGroup);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Opacity(
        opacity: 0.72,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$ageGroup Month${ageGroup == 1 ? '' : 's'} — Coming Up',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  'These milestones typically emerge around $ageGroup months.',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Milestone previews
              ...milestones.map(
                (m) => _LookAheadMilestoneRow(milestone: m),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _LookAheadMilestoneRow extends StatelessWidget {
  const _LookAheadMilestoneRow({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final domainColor = _domainColor(milestone.domain);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: domainColor.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              milestone.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
                height: 1.4,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper: domain → color
// ---------------------------------------------------------------------------

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
