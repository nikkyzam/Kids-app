import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/milestone_context_data.dart';
import '../models/milestone.dart';
import '../providers/milestone_provider.dart';
import '../services/photo_memory_service.dart';
import '../theme/app_theme.dart';

class MilestoneItem extends StatefulWidget {
  final Milestone milestone;
  final int profileId;

  const MilestoneItem({
    super.key,
    required this.milestone,
    required this.profileId,
  });

  @override
  State<MilestoneItem> createState() => _MilestoneItemState();
}

class _MilestoneItemState extends State<MilestoneItem> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MilestoneProvider>(
      builder: (context, mp, _) {
        final isAchieved = mp.isAchieved(widget.milestone.id);
        final achievement = mp.getAchievement(widget.milestone.id);
        final domainColor = _domainColor(widget.milestone.domain);

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                onTap: () async {
                  final wasAchieved = mp.isAchieved(widget.milestone.id);
                  await mp.toggleMilestone(
                      widget.profileId, widget.milestone.id);
                  if (!wasAchieved && context.mounted) {
                    _confetti.play();
                    _promptAddPhoto();
                  }
                },
                onLongPress: isAchieved
                    ? () => _editNotes(context, mp, achievement)
                    : null,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      _buildDomainIndicator(domainColor, isAchieved),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.milestone.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: isAchieved
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                            if (isAchieved && achievement != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 12, color: AppTheme.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy')
                                        .format(achievement.achievedDate),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (achievement.notes?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.note_alt_outlined,
                                        size: 12, color: AppTheme.textMuted),
                                  ],
                                ],
                              ),
                            ],
                            if (!isAchieved)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                    'Long-press to add a note after checking',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMuted)),
                              ),
                          ],
                        ),
                      ),
                      if (MilestoneContext.forMilestone(widget.milestone) !=
                          null)
                        IconButton(
                          // Its own control rather than part of the row: the
                          // row toggles the milestone, and a parent reading up
                          // on what to look for must not tick it by accident.
                          icon: const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppTheme.textMuted),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'What to look for',
                          onPressed: () => _showContext(context, domainColor),
                        ),
                      const SizedBox(width: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isAchieved
                              ? AppTheme.success
                              : Colors.transparent,
                          border: Border.all(
                            color: isAchieved
                                ? AppTheme.success
                                : AppTheme.textMuted.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: isAchieved
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
              gravity: 0.4,
              emissionFrequency: 0.05,
              colors: const [
                AppTheme.primary,
                AppTheme.secondary,
                AppTheme.success,
                Color(0xFFFF7043),
                Color(0xFF9C6FDE),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDomainIndicator(Color color, bool isAchieved) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: isAchieved ? color : color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showContext(BuildContext context, Color domainColor) {
    final ctx = MilestoneContext.forMilestone(widget.milestone);
    if (ctx == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.milestone.domain.label.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: domainColor,
                    letterSpacing: 1.1),
              ),
              const SizedBox(height: 6),
              Text(widget.milestone.description,
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 20),
              _ContextBlock(
                icon: Icons.visibility_outlined,
                color: domainColor,
                title: 'What to look for',
                body: ctx.whatToLookFor,
              ),
              const SizedBox(height: 16),
              _ContextBlock(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppTheme.textMuted,
                title: 'When to talk to your pediatrician',
                body: ctx.whenToTalk,
              ),
              const SizedBox(height: 20),
              // Said plainly and every time, because the previous line is the
              // one most likely to be read as a diagnosis.
              Text(
                'PlaySteps is a place to keep notes, not a medical opinion. '
                'Children reach these at very different times, and your '
                'pediatrician is the person who can actually tell you '
                'anything about your child.',
                style: Theme.of(sheetContext)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Takes no context parameter on purpose: every gap here is awaited, and a
  /// `State.mounted` check is only meaningful against `State.context`.
  Future<void> _promptAddPhoto() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final add = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add a Photo Memory?'),
        content: const Text(
            'Capture this milestone with a photo — it will be saved in your memories timeline.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add Photo')),
        ],
      ),
    );
    if (add != true || !mounted) return;

    final saved = await PhotoMemoryService.capture(
      context,
      profileId: widget.profileId,
      referenceType: 'milestone',
      referenceId: widget.milestone.id,
    );

    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo memory saved!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editNotes(
      BuildContext context, MilestoneProvider mp, achievement) async {
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
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save Memory')),
        ],
      ),
    );
    controller.dispose();
    if (result != null && context.mounted) {
      await mp.updateNotes(widget.profileId, widget.milestone.id, result);
    }
  }

  Color _domainColor(MilestoneDomain domain) {
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
}

class _ContextBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _ContextBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(body,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55)),
      ],
    );
  }
}
