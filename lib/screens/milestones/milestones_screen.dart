import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/milestone.dart';
import '../../providers/profile_provider.dart';
import '../../providers/milestone_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/milestone_item.dart';
import '../../widgets/parental_gate_dialog.dart';
import '../../data/milestones_data.dart';
import '../../services/pdf_export_service.dart';

class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    if (profile == null) return const SizedBox.shrink();

    return Consumer<MilestoneProvider>(
      builder: (context, mp, _) {
        if (mp.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, mp)),
            SliverToBoxAdapter(child: _buildDomainFilter(context, mp)),
            ..._buildMilestoneGroups(context, mp, profile.id!),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MilestoneProvider mp) {
    final total = mp.totalCount;
    final achieved = mp.achievedCount;
    final progress = total == 0 ? 0.0 : achieved / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.shadeGradient(AppTheme.primary),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: AppTheme.glow(AppTheme.primary),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                child: AppTheme.heroBubbles(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Milestone Ledger',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          '$achieved of $total achieved',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        // White-on-gradient so the action stays visible
                        // against the hero fill.
                        TextButton.icon(
                          onPressed: () => _exportPdf(context),
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 15),
                          label: const Text('Export'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            textStyle: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (_, value, __) => SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                          Text(
                            '${(value * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainFilter(BuildContext context, MilestoneProvider mp) {
    final domains = [null, ...MilestoneDomain.values];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: domains.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final domain = domains[i];
          final isSelected = mp.filterDomain == domain;
          final label = domain?.label ?? 'All';
          final color = _domainColor(domain);

          return FilterChip(
            label: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color)),
            selected: isSelected,
            onSelected: (_) => mp.setFilter(domain),
            backgroundColor: color.withValues(alpha: 0.1),
            selectedColor: color,
            checkmarkColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  List<Widget> _buildMilestoneGroups(
      BuildContext context, MilestoneProvider mp, int profileId) {
    final groups = <Widget>[];

    for (final ageGroup in mp.ageGroups) {
      final milestones = MilestonesData.filterByDomain(
        MilestonesData.forAgeGroup(ageGroup),
        mp.filterDomain,
      );
      if (milestones.isEmpty) continue;

      final achievedInGroup =
          milestones.where((m) => mp.isAchieved(m.id)).length;

      groups.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$ageGroup Month${ageGroup == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$achievedInGroup/${milestones.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ));

      groups.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: MilestoneItem(
              milestone: milestones[index],
              profileId: profileId,
            ),
          ),
          childCount: milestones.length,
        ),
      ));
    }

    return groups;
  }

  Color _domainColor(MilestoneDomain? domain) {
    if (domain == null) return AppTheme.primary;
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

  Future<void> _exportPdf(BuildContext context) async {
    final passed = await showDialog<bool>(
      context: context,
      builder: (_) => const ParentalGateDialog(),
    );
    if (passed != true || !context.mounted) return;

    final mp = context.read<MilestoneProvider>();
    final profile = context.read<ProfileProvider>().activeProfile;
    if (profile == null) return;

    await _generateAndSharePdf(context, mp, profile);
  }

  Future<void> _generateAndSharePdf(
      BuildContext context, MilestoneProvider mp, dynamic profile) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Building your milestone report…'),
          backgroundColor: AppTheme.primary,
          duration: Duration(seconds: 2),
        ),
      );
      await PdfExportService.exportMilestones(
        profile: profile,
        achievements: mp.achievements,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
