import 'package:flutter/material.dart';
import '../models/badge_definition.dart';
import '../theme/app_theme.dart';

class BadgeUnlockedDialog extends StatelessWidget {
  final BadgeDefinition badge;
  const BadgeUnlockedDialog({super.key, required this.badge});

  static Future<void> show(BuildContext context, BadgeDefinition badge) {
    return showDialog(
      context: context,
      builder: (_) => BadgeUnlockedDialog(badge: badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            const Text(
              'BADGE UNLOCKED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: badge.color,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: badge.color,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}
