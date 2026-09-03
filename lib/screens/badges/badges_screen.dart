import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/badges_data.dart';
import '../../models/badge_definition.dart';
import '../../providers/badge_provider.dart';
import '../../theme/app_theme.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Consumer<BadgeProvider>(
        builder: (context, bp, _) {
          return Column(
            children: [
              _ProgressHeader(unlocked: bp.unlockedCount, total: bp.totalCount),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: BadgesData.all.length,
                  itemBuilder: (context, i) {
                    final badge = BadgesData.all[i];
                    return _BadgeTile(
                      badge: badge,
                      isUnlocked: bp.isUnlocked(badge.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  const _ProgressHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : unlocked / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked of $total badges earned',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
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

class _BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;
  const _BadgeTile({required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isUnlocked ? badge.color.withValues(alpha: 0.07) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUnlocked
            ? BorderSide(color: badge.color.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: isUnlocked ? 1.0 : 0.2,
              duration: const Duration(milliseconds: 400),
              child: Text(badge.emoji, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 8),
            // Flexible, not fixed: the tile is a fixed-ratio grid cell, so at
            // a larger text scale on a narrow phone the emoji and two labels
            // together are taller than the cell. Letting the labels give up
            // lines keeps the badge legible instead of striping it yellow.
            Flexible(
              child: Text(
                badge.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? badge.color : AppTheme.textMuted,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                badge.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle_rounded,
                    size: 14, color: badge.color),
              ),
          ],
        ),
      ),
    );
  }
}
