import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';

class SkillCoverageCard extends StatelessWidget {
  const SkillCoverageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, ap, _) {
        final coverage = ap.skillCoverage;
        if (coverage.isEmpty) return const SizedBox.shrink();

        final total = coverage.values.fold(0, (sum, v) => sum + v);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text('Skills Practised', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('$total sessions', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...SkillCategory.values.map((cat) {
                    final count = coverage[cat] ?? 0;
                    final ratio = total == 0 ? 0.0 : count / total;
                    return _SkillBar(category: cat, count: count, ratio: ratio);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkillBar extends StatelessWidget {
  final SkillCategory category;
  final int count;
  final double ratio;

  const _SkillBar({required this.category, required this.count, required this.ratio});

  Color get color {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              category.label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
