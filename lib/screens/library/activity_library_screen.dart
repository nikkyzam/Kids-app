import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity.dart';
import '../../providers/activity_provider.dart';
import '../../providers/profile_provider.dart';
import '../../data/activities_data.dart';
import '../../theme/app_theme.dart';
import '../paywall/paywall_screen.dart';

class ActivityLibraryScreen extends StatefulWidget {
  const ActivityLibraryScreen({super.key});

  @override
  State<ActivityLibraryScreen> createState() => _ActivityLibraryScreenState();
}

class _ActivityLibraryScreenState extends State<ActivityLibraryScreen> {
  SkillCategory? _filter;
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile!;
    final ap = context.watch<ActivityProvider>();
    final allForAge =
        ActivitiesData.forAgeBandWeeks(profile.contentAgeBandWeeks);
    final todayId = ap.todayActivity?.id;

    final filtered = _filter == null
        ? allForAge
        : allForAge.where((a) => a.skillCategory == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Library'),
            Text(
              '${allForAge.length} activities for ${profile.adjustedDisplayAge}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ActivityLibraryTile(
                      activity: filtered[i],
                      isToday: filtered[i].id == todayId,
                      isExpanded: _expandedId == filtered[i].id,
                      requiresPremium: ap.activityRequiresPremium(filtered[i]),
                      onTap: () => setState(() {
                        _expandedId = _expandedId == filtered[i].id
                            ? null
                            : filtered[i].id;
                      }),
                      onUnlock: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PaywallScreen()),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final categories = [null, ...SkillCategory.values];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = _filter == cat;
          final color = cat == null ? AppTheme.primary : _categoryColor(cat);
          final label = cat?.label ?? 'All';
          return FilterChip(
            label: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : color)),
            selected: isSelected,
            onSelected: (_) => setState(() => _filter = cat),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text('No ${_filter?.label ?? ''} activities for this age',
              style: const TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Color _categoryColor(SkillCategory cat) {
    switch (cat) {
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
}

class _ActivityLibraryTile extends StatelessWidget {
  final PlayActivity activity;
  final bool isToday;
  final bool isExpanded;
  final bool requiresPremium;
  final VoidCallback onTap;
  final VoidCallback onUnlock;

  const _ActivityLibraryTile({
    required this.activity,
    required this.isToday,
    required this.isExpanded,
    required this.requiresPremium,
    required this.onTap,
    required this.onUnlock,
  });

  Color get _color {
    switch (activity.skillCategory) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: requiresPremium ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (isExpanded && !requiresPremium) _buildExpanded(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: requiresPremium
                  ? AppTheme.textMuted.withValues(alpha: 0.08)
                  : _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              requiresPremium
                  ? Icons.lock_rounded
                  : _skillIcon(activity.skillCategory),
              color: requiresPremium ? AppTheme.textMuted : _color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: requiresPremium
                              ? AppTheme.textMuted
                              : AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Today',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    // The duration is short but not free: at a larger text
                    // scale it and the category pill together overran the row.
                    Flexible(
                      child: Text('${activity.durationMins} min',
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted)),
                    ),
                    const SizedBox(width: 10),
                    // Longer category labels pushed this pill past the card
                    // edge next to the "Unlock" button.
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(activity.skillCategory.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9,
                                color: _color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (requiresPremium)
            TextButton(
              onPressed: onUnlock,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Unlock',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            )
          else
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16),
          _sectionLabel('Materials', Icons.inventory_2_outlined),
          const SizedBox(height: 4),
          ...activity.materials.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $m',
                    style: const TextStyle(fontSize: 13, height: 1.5)),
              )),
          const SizedBox(height: 10),
          _sectionLabel('Steps', Icons.format_list_numbered_rounded),
          const SizedBox(height: 4),
          ...activity.instructions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${e.key + 1}. ${e.value}',
                    style: const TextStyle(fontSize: 13, height: 1.5)),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 14, color: _color),
                const SizedBox(width: 5),
                // skillTargeted is free text; a long one overflowed this chip
                // off the right edge of the card.
                Flexible(
                  child: Text(activity.skillTargeted,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: _color,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 5),
        Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.8)),
      ],
    );
  }

  IconData _skillIcon(SkillCategory cat) {
    switch (cat) {
      case SkillCategory.grossMotor:
        return Icons.directions_run_rounded;
      case SkillCategory.fineMotor:
        return Icons.back_hand_rounded;
      case SkillCategory.language:
        return Icons.record_voice_over_rounded;
      case SkillCategory.cognitive:
        return Icons.psychology_rounded;
      case SkillCategory.socialEmotional:
        return Icons.favorite_rounded;
      case SkillCategory.sensory:
        return Icons.sentiment_very_satisfied_rounded;
    }
  }
}
