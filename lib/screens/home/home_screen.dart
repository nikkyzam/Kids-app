import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/milestone_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/child_profile_dropdown.dart';
import '../../widgets/activity_card.dart';
import '../milestones/milestones_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForActiveProfile());
  }

  void _loadForActiveProfile() {
    final profile = context.read<ProfileProvider>().activeProfile;
    if (profile == null) return;
    context.read<ActivityProvider>().loadForProfile(profile.id!, profile.ageBandWeeks);
    context.read<MilestoneProvider>().loadForProfile(profile.id!);
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
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _openSettings(),
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
                label: 'Today\'s Play',
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

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildGreeting(context, profile.name, profile.displayAge)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: ActivityCard(profileId: profile.id!)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(child: _buildMilestoneTeaser(context, profile.id!)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, String name, String age) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: Theme.of(context).textTheme.bodyMedium),
          Text(name, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(age, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
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
            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
            homeState?.setState(() => homeState._tab = 1);
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
                        const Icon(Icons.checklist_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Milestones', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('$achieved/$total', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.primaryLight,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
