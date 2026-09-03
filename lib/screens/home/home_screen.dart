import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/milestone_provider.dart';
import '../../providers/badge_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/child_profile_dropdown.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/streak_banner.dart';
import '../../widgets/trial_banner.dart';
import '../../widgets/daily_tip_card.dart';
import '../../widgets/skill_coverage_card.dart';
import '../milestones/milestones_screen.dart';
import '../settings/settings_screen.dart';
import '../history/activity_history_screen.dart';
import '../library/activity_library_screen.dart';
import '../badges/badges_screen.dart';
import '../memories/memories_timeline_screen.dart';
import '../insights/development_snapshot_screen.dart';
import '../insights/pediatrician_prep_screen.dart';
import '../growth/growth_tracker_screen.dart';
import '../leaps/developmental_leaps_screen.dart';
import '../plan/activity_plan_screen.dart';
import '../digest/weekly_digest_screen.dart';
import '../paywall/premium_plus_screen.dart';
import '../../widgets/weekly_recap_card.dart';
import '../../widgets/red_flag_banner.dart';
import '../../utils/clock.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  /// Switches the active bottom-navigation tab. Exposed so descendant widgets
  /// can navigate without reaching into the protected [setState].
  void selectTab(int index) => setState(() => _tab = index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadForActiveProfile());
  }

  void _loadForActiveProfile() {
    final profile = context.read<ProfileProvider>().activeProfile;
    if (profile == null) return;
    context
        .read<ActivityProvider>()
        .loadForProfile(profile.id!, profile.contentAgeBandWeeks);
    context.read<MilestoneProvider>().loadForProfile(profile.id!);
    context.read<BadgeProvider>().loadBadges(profile.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.activeProfile;
        if (profile == null) return const SizedBox.shrink();

        return Scaffold(
          appBar: AppBar(
            title: ChildProfileDropdown(
              profiles: profileProvider.profiles,
              activeProfile: profile,
              onChanged: (p) {
                profileProvider.setActiveProfile(p);
                _loadForActiveProfile();
              },
              canAddMore: profileProvider.canAddMore,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ActivityHistoryScreen()),
                ),
              ),
              Consumer<BadgeProvider>(
                builder: (context, bp, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_events_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BadgesScreen()),
                      ),
                    ),
                    if (bp.unlockedCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${bp.unlockedCount}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _tab,
            children: const [
              _ActivityTab(),
              MilestonesScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.play_circle_outline_rounded),
                selectedIcon: Icon(Icons.play_circle_rounded),
                label: "Today's Play",
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist_rounded),
                label: 'Milestones',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile!;
    final ap = context.watch<ActivityProvider>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildGreeting(
              context, profile.name, profile.ageSummary, ap.currentStreak),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        const SliverToBoxAdapter(child: TrialBanner()),
        const SliverToBoxAdapter(child: StreakBanner()),
        SliverToBoxAdapter(child: _buildLibraryButton(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver:
              SliverToBoxAdapter(child: ActivityCard(profileId: profile.id!)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: DailyTipCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildMilestoneTeaser(context, profile.id!)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: WeeklyRecapCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: SkillCoverageCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildInsightsRow(context, profile.id!)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: RedFlagBanner()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildPremiumPlusRow(context, profile.id!)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildInsightsRow(BuildContext context, int profileId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _InsightButton(
              icon: Icons.camera_alt_outlined,
              label: 'Memories',
              color: AppTheme.fineMotorColor,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        MemoriesTimelineScreen(profileId: profileId)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightButton(
              icon: Icons.track_changes_rounded,
              label: 'On Track?',
              color: AppTheme.cognitiveColor,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DevelopmentSnapshotScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightButton(
              icon: Icons.medical_services_outlined,
              label: 'Doctor Prep',
              color: AppTheme.languageColor,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PediatricianPrepScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          icon: const Icon(Icons.grid_view_rounded, size: 14),
          label: const Text('Browse All Activities',
              style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ActivityLibraryScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(
      BuildContext context, String name, String age, int streak) {
    final hour = Clock.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: Theme.of(context).textTheme.bodyMedium),
                Text(name, style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(age,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (streak >= 3) _StreakBadge(streak: streak),
        ],
      ),
    );
  }

  Widget _buildMilestoneTeaser(BuildContext context, int profileId) {
    return Consumer<MilestoneProvider>(
      builder: (context, mp, _) {
        final achieved = mp.achievedCount;
        final total = mp.totalCount;
        final progress = total == 0 ? 0.0 : achieved / total;

        return GestureDetector(
          onTap: () {
            final homeState =
                context.findAncestorStateOfType<_HomeScreenState>();
            homeState?.selectTab(1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.checklist_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        // Expanded rather than Spacer: a raised text scale
                        // made the heading wide enough to push the count pill
                        // off the card.
                        Expanded(
                          child: Text('Milestones',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: achieved == 0
                                ? AppTheme.primaryLight
                                : AppTheme.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$achieved/$total',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: achieved == 0
                                  ? AppTheme.primary
                                  : AppTheme.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textMuted, size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: AppTheme.primaryLight,
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.primary),
                        ),
                      ),
                    ),
                    if (achieved > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        _motivationText(achieved, total),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _motivationText(int achieved, int total) {
    final pct = (achieved / total * 100).round();
    if (pct < 10) return 'Great start! Keep tracking each milestone.';
    if (pct < 30) return 'Building momentum — $pct% complete!';
    if (pct < 60) return 'Halfway there — you\'re doing amazing!';
    if (pct < 85) return '$pct% tracked — incredible progress!';
    return 'Almost done — nearly all milestones logged!';
  }
}

Widget _buildPremiumPlusRow(BuildContext context, int profileId) {
  final isPremiumPlus = context.watch<ActivityProvider>().isPremiumPlus;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            // Expanded rather than a bare Text plus Spacer: at a larger text
            // scale the heading and the "See all" tap target together ran off
            // the row.
            const Expanded(
              child: Text(
                'Premium Plus',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF5A623),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (!isPremiumPlus) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumPlusScreen()),
                ),
                child: const Text(
                  'Upgrade →',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFF5A623),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          children: [
            _PremiumPlusTile(
              emoji: '📈',
              label: 'Growth Tracker',
              isLocked: !isPremiumPlus,
              onTap: isPremiumPlus
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          GrowthTrackerScreen(profileId: profileId)))
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PremiumPlusScreen())),
            ),
            _PremiumPlusTile(
              emoji: '🧠',
              label: 'Leap Calendar',
              isLocked: !isPremiumPlus,
              onTap: isPremiumPlus
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const DevelopmentalLeapsScreen()))
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PremiumPlusScreen())),
            ),
            _PremiumPlusTile(
              emoji: '📅',
              label: '4-Week Plan',
              isLocked: !isPremiumPlus,
              onTap: isPremiumPlus
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ActivityPlanScreen()))
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PremiumPlusScreen())),
            ),
            _PremiumPlusTile(
              emoji: '📋',
              label: 'Weekly Report',
              isLocked: !isPremiumPlus,
              onTap: isPremiumPlus
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const WeeklyDigestScreen()))
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PremiumPlusScreen())),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PremiumPlusTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isLocked;
  final VoidCallback onTap;

  const _PremiumPlusTile({
    required this.emoji,
    required this.label,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isLocked ? null : const Color(0xFFFFFBF0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLocked
              ? Colors.transparent
              : const Color(0xFFF5A623).withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        isLocked ? AppTheme.textMuted : const Color(0xFF8B6914),
                  ),
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InsightButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF7043).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 20),
          Text(
            '$streak',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const Text('days',
              style: TextStyle(fontSize: 8, color: Colors.white70)),
        ],
      ),
    );
  }
}
