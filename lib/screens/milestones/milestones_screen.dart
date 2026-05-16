import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Milestone Ledger', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '${mp.achievedCount} of ${mp.totalCount} achieved',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Export'),
            onPressed: () => _exportPdf(context),
          ),
        ],
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
            label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color)),
            selected: isSelected,
            onSelected: (_) => mp.setFilter(domain),
            backgroundColor: color.withOpacity(0.1),
            selectedColor: color,
            checkmarkColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  List<Widget> _buildMilestoneGroups(BuildContext context, MilestoneProvider mp, int profileId) {
    final groups = <Widget>[];

    for (final ageGroup in mp.ageGroups) {
      final milestones = MilestonesData.filterByDomain(
        MilestonesData.forAgeGroup(ageGroup),
        mp.filterDomain,
      );
      if (milestones.isEmpty) continue;

      final achievedInGroup = milestones.where((m) => mp.isAchieved(m.id)).length;

      groups.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$ageGroup Month${ageGroup == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
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
      case MilestoneDomain.grossMotor: return AppTheme.grossMotorColor;
      case MilestoneDomain.fineMotor: return AppTheme.fineMotorColor;
      case MilestoneDomain.language: return AppTheme.languageColor;
      case MilestoneDomain.cognitive: return AppTheme.cognitiveColor;
      case MilestoneDomain.socialEmotional: return AppTheme.socialEmotionalColor;
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
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
