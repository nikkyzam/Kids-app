import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/red_flags_data.dart';
import '../providers/milestone_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';

/// Shows a dismissable warning banner when the child has passed the CDC red-flag
/// age for one or more unachieved critical milestones.
class RedFlagBanner extends StatelessWidget {
  const RedFlagBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileProvider, MilestoneProvider>(
      builder: (context, pp, mp, _) {
        final profile = pp.activeProfile;
        if (profile == null || mp.isLoading) return const SizedBox.shrink();

        final achievedIds = mp.achievements.map((a) => a.milestoneId).toSet();

        final flags =
            RedFlagsData.activeFor(profile.contentAgeInMonths, achievedIds);
        if (flags.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB74D), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${flags.length} milestone${flags.length == 1 ? '' : 's'} worth mentioning to your doctor',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                flags.first.concern,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
              ),
              if (flags.length > 1)
                Text(
                  '+ ${flags.length - 1} more — tap to see all',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
            ],
          ),
        );
      },
    );
  }
}
