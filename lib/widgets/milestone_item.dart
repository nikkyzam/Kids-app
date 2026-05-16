import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/milestone.dart';
import '../providers/milestone_provider.dart';
import '../theme/app_theme.dart';

class MilestoneItem extends StatelessWidget {
  final Milestone milestone;
  final int profileId;

  const MilestoneItem({
    super.key,
    required this.milestone,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MilestoneProvider>(
      builder: (context, mp, _) {
        final isAchieved = mp.isAchieved(milestone.id);
        final achievement = mp.getAchievement(milestone.id);
        final domainColor = _domainColor(milestone.domain);

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => mp.toggleMilestone(profileId, milestone.id),
            onLongPress: isAchieved ? () => _editNotes(context, mp, achievement) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _buildDomainIndicator(domainColor, isAchieved),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: isAchieved ? TextDecoration.none : null,
                            fontWeight: isAchieved ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (isAchieved && achievement != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.success),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(achievement.achievedDate),
                                style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600),
                              ),
                              if (achievement.notes?.isNotEmpty == true) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.note_alt_outlined, size: 12, color: AppTheme.textMuted),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isAchieved ? AppTheme.success : Colors.transparent,
                      border: Border.all(color: isAchieved ? AppTheme.success : AppTheme.textMuted.withOpacity(0.4), width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isAchieved
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDomainIndicator(Color color, bool isAchieved) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: isAchieved ? color : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Future<void> _editNotes(BuildContext context, MilestoneProvider mp, achievement) async {
    final controller = TextEditingController(text: achievement?.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add a Memory'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Write a special note or memory about this milestone…',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result != null && context.mounted) {
      await mp.updateNotes(profileId, milestone.id, result);
    }
  }

  Color _domainColor(MilestoneDomain domain) {
    switch (domain) {
      case MilestoneDomain.grossMotor: return AppTheme.grossMotorColor;
      case MilestoneDomain.fineMotor: return AppTheme.fineMotorColor;
      case MilestoneDomain.language: return AppTheme.languageColor;
      case MilestoneDomain.cognitive: return AppTheme.cognitiveColor;
      case MilestoneDomain.socialEmotional: return AppTheme.socialEmotionalColor;
    }
  }
}
