import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:image_picker/image_picker.dart';

import '../data/database_helper.dart';
import '../models/activity.dart';
import '../models/activity_skip.dart';
import '../models/photo_memory.dart';
import '../providers/activity_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/milestone_provider.dart';
import '../theme/app_theme.dart';
import 'badge_unlocked_dialog.dart';
import 'confetti_overlay.dart';
import 'streak_milestone_dialog.dart';
import '../screens/paywall/paywall_screen.dart';
import '../services/purchase_service.dart';
import '../utils/clock.dart';

class ActivityCard extends StatefulWidget {
  final int profileId;

  const ActivityCard({super.key, required this.profileId});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  final _confettiKey = GlobalKey<ConfettiOverlayState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, _) {
        if (activityProvider.isLoading) {
          return const _CardShimmer();
        }

        final activity = activityProvider.todayActivity;

        if (activity == null) {
          return _buildNoActivityCard(context);
        }

        if (activityProvider.todayRequiresPremium) {
          return _buildLockedCard(context, activity);
        }

        return Stack(
          children: [
            _buildActivityCard(context, activityProvider, activity),
            ConfettiOverlay(key: _confettiKey),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(
      BuildContext context, ActivityProvider ap, PlayActivity activity) {
    final isCompleted = ap.isCompleted;
    final categoryColor = _skillColor(activity.skillCategory);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, activity, categoryColor, isCompleted),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkillChip(activity, categoryColor),
                const SizedBox(height: 16),
                _buildSection(
                    context,
                    'Materials',
                    Icons.inventory_2_outlined,
                    categoryColor,
                    activity.materials.map((m) => '• $m').join('\n')),
                const SizedBox(height: 14),
                _buildSection(
                    context,
                    'Steps',
                    Icons.format_list_numbered_rounded,
                    categoryColor,
                    activity.instructions
                        .asMap()
                        .entries
                        .map((e) => '${e.key + 1}. ${e.value}')
                        .join('\n')),
                const SizedBox(height: 20),
                _buildCompleteButton(context, ap, isCompleted, categoryColor),
                if (!isCompleted) ...[
                  const SizedBox(height: 4),
                  _buildDismissButton(context, ap),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, PlayActivity activity,
      Color categoryColor, bool isCompleted) {
    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.successLight
            : categoryColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppTheme.success : categoryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCompleted ? 'Completed!' : "Today's Challenge",
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(activity.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                        '${activity.durationMins} min${activity.durationMins == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 32),
        ],
      ),
    );
  }

  Widget _buildSkillChip(PlayActivity activity, Color categoryColor) {
    return Row(
      children: [
        // skillTargeted is free text and can be long; without Flexible the
        // chip sized to its content and overflowed the card on narrower
        // phones and at larger text scales.
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              activity.skillTargeted,
              style: TextStyle(
                  fontSize: 12,
                  color: categoryColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon,
      Color color, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Text(content,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
      ],
    );
  }

  Widget _buildCompleteButton(BuildContext context, ActivityProvider ap,
      bool isCompleted, Color categoryColor) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isCompleted
            ? OutlinedButton.icon(
                key: const ValueKey('undo'),
                onPressed: () => ap.toggleCompletion(widget.profileId),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Mark Incomplete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.success,
                  side: const BorderSide(color: AppTheme.success),
                ),
              )
            : FilledButton.icon(
                key: const ValueKey('complete'),
                onPressed: () async {
                  await ap.toggleCompletion(widget.profileId);
                  _confettiKey.currentState?.play();
                  if (!context.mounted) return;
                  StreakMilestoneDialog.showIfMilestone(
                      context, ap.currentStreak);
                  final mp = context.read<MilestoneProvider>();
                  final bp = context.read<BadgeProvider>();
                  final newBadges = await bp.checkAndUnlock(
                    profileId: widget.profileId,
                    ap: ap,
                    mp: mp,
                  );
                  for (final badge in newBadges) {
                    if (context.mounted) {
                      await BadgeUnlockedDialog.show(context, badge);
                    }
                  }
                  if (context.mounted) {
                    _offerPhotoMemory(context, ap, widget.profileId);
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Complete Challenge'),
                style: FilledButton.styleFrom(backgroundColor: categoryColor),
              ),
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context, ActivityProvider ap) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _dismissActivity(context, ap),
        style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
        child: const Text('Not for us today',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _dismissActivity(
      BuildContext context, ActivityProvider ap) async {
    final reason = await showModalBottomSheet<_DismissChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const _DismissReasonSheet(),
    );
    if (reason == null || !context.mounted) return;

    final swapped =
        await ap.dismissTodayActivity(widget.profileId, reason.reason);
    if (!context.mounted || !swapped) return;

    final replacement = ap.todayActivity;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(replacement == null
            ? "We'll skip that one from now on."
            : 'Try this instead: ${replacement.title}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLockedCard(BuildContext context, PlayActivity activity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_rounded,
                  color: AppTheme.secondary, size: 28),
            ),
            const SizedBox(height: 12),
            Text("Today's activity is Premium",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Unlock the full activity library through 36 months with a '
              'one-time purchase.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              // Read the price from the store rather than hard-coding it, so
              // this card cannot advertise a different amount than the
              // purchase sheet charges in the user's currency.
              final price =
                  PurchaseService.instance.priceFor(Entitlement.premium);
              return FilledButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen())),
                style:
                    FilledButton.styleFrom(backgroundColor: AppTheme.secondary),
                child: Text(price == null
                    ? 'Unlock Premium'
                    : 'Unlock Premium — $price'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActivityCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.celebration_rounded,
                color: AppTheme.secondary, size: 48),
            const SizedBox(height: 12),
            Text('Great milestone!',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'No activity found for this age range. Check back as your child grows!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _offerPhotoMemory(
      BuildContext context, ActivityProvider ap, int profileId) async {
    if (ap.todayActivity == null || !ap.isCompleted) return;
    final dateKey = Clock.now().toIso8601String().split('T').first;

    await Future.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;

    final add = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Capture the moment?'),
        content: const Text(
            "Add a photo of today's activity to your memories timeline."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Maybe later')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add Photo')),
        ],
      ),
    );
    if (add != true || !mounted) return;

    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null || !mounted) return;

    await DatabaseHelper.instance.savePhoto(PhotoMemory(
      profileId: profileId,
      referenceType: 'activity',
      referenceId: dateKey,
      imagePath: picked.path,
      capturedAt: Clock.now().toIso8601String(),
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo memory saved!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Color _skillColor(SkillCategory category) {
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
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Container(
                height: 14,
                width: double.infinity,
                color: Colors.grey.shade100),
            const SizedBox(height: 8),
            Container(height: 14, width: 200, color: Colors.grey.shade100),
          ],
        ),
      ),
    );
  }
}

/// The parent's answer to "not for us" — a reason, or none at all. Wrapped in
/// a small class so the sheet can distinguish "closed without choosing"
/// (null) from "skipped without saying why".
class _DismissChoice {
  final SkipReason? reason;
  const _DismissChoice(this.reason);
}

class _DismissReasonSheet extends StatelessWidget {
  const _DismissReasonSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No problem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              "We'll find another one. Telling us why helps us pick better — "
              'it stays on this device.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ),
          for (final reason in SkipReason.values)
            ListTile(
              title: Text(reason.label),
              onTap: () => Navigator.pop(context, _DismissChoice(reason)),
            ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Just show me another',
                style: TextStyle(color: AppTheme.textMuted)),
            onTap: () => Navigator.pop(context, const _DismissChoice(null)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
