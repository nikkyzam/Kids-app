import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/activity_provider.dart';
import '../../providers/milestone_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

class WeeklyDigestScreen extends StatelessWidget {
  const WeeklyDigestScreen({super.key});

  DateTime get _weekStart {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  String get _weekRangeLabel {
    final fmt = DateFormat('MMM d');
    return '${fmt.format(_weekStart)} – ${fmt.format(_weekEnd)}';
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    final mp = context.watch<MilestoneProvider>();
    final pp = context.watch<ProfileProvider>();

    final childName = pp.activeProfile?.name ?? 'Your Child';

    final completedDays = _weekDays.where((d) => ap.completedOnDay(d)).toList();
    final completedCount = completedDays.length;

    final weeklyMilestones = mp.achievements.where((a) {
      return !a.achievedDate.isBefore(_weekStart) &&
          !a.achievedDate.isAfter(_weekEnd
              .add(const Duration(hours: 23, minutes: 59, seconds: 59)));
    }).toList();

    final topSkill = _topSkillThisWeek(ap);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: Column(
        children: [
          _buildWeekHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildPreviewCard(
                context,
                childName: childName,
                completedDays: completedDays,
                completedCount: completedCount,
                streak: ap.currentStreak,
                milestones: weeklyMilestones,
                topSkill: topSkill,
              ),
            ),
          ),
          _buildShareButton(context, ap, mp, pp),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    return Container(
      color: AppTheme.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            _weekRangeLabel,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context, {
    required String childName,
    required List<DateTime> completedDays,
    required int completedCount,
    required int streak,
    required List milestones,
    required String? topSkill,
  }) {
    final now = DateTime.now();
    final dateLabel = DateFormat('MMMM d, y').format(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.child_care_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PlaySteps',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '$childName · $_weekRangeLabel',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              'Activities',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: _weekDays.map((day) {
                final done = completedDays.contains(day);
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 1),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? AppTheme.success : Colors.transparent,
                          border: Border.all(
                            color: done
                                ? AppTheme.success
                                : AppTheme.textMuted.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '$completedCount / 7 days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '$streak-day streak',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              'Milestones This Week',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            if (milestones.isEmpty)
              Text(
                'No new milestones this week — keep going!',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...milestones.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.secondary, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          a.milestoneId,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (topSkill != null) ...[
              const Divider(height: 28),
              Text(
                'Skill Highlights',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppTheme.secondary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Most practiced: $topSkill',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 28),
            Text(
              'Generated by PlaySteps · $dateLabel',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context,
    ActivityProvider ap,
    MilestoneProvider mp,
    ProfileProvider pp,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: FilledButton.icon(
        onPressed: () => _generateAndSharePdf(context, ap, mp, pp),
        icon: const Icon(Icons.share_rounded),
        label: const Text('Share Weekly Report'),
      ),
    );
  }

  String? _topSkillThisWeek(ActivityProvider ap) {
    final weekKeys =
        _weekDays.map((d) => DateFormat('yyyy-MM-dd').format(d)).toSet();
    final weekCompletions =
        ap.allCompletions.where((c) => weekKeys.contains(c.dateKey)).toList();
    if (weekCompletions.isEmpty) return null;

    final skillCounts = <String, int>{};
    for (final c in weekCompletions) {
      final activity = ap.activityForCompletion(c);
      if (activity != null) {
        final label = activity.skillCategory.label;
        skillCounts[label] = (skillCounts[label] ?? 0) + 1;
      }
    }
    if (skillCounts.isEmpty) return null;

    return skillCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Future<void> _generateAndSharePdf(
    BuildContext context,
    ActivityProvider ap,
    MilestoneProvider mp,
    ProfileProvider pp,
  ) async {
    final childName = pp.activeProfile?.name ?? 'Your Child';
    final completedDays = _weekDays.where((d) => ap.completedOnDay(d)).toList();
    final completedCount = completedDays.length;
    final streak = ap.currentStreak;

    final weeklyMilestones = mp.achievements.where((a) {
      return !a.achievedDate.isBefore(_weekStart) &&
          !a.achievedDate.isAfter(_weekEnd
              .add(const Duration(hours: 23, minutes: 59, seconds: 59)));
    }).toList();

    final topSkill = _topSkillThisWeek(ap);
    final generatedDate = DateFormat('MMMM d, y').format(DateTime.now());
    final dayFmt = DateFormat('EEEE, MMM d');

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PlaySteps — Weekly Report',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '$childName · $_weekRangeLabel',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Activities',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Activities completed: $completedCount / 7',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 6),
              if (completedDays.isNotEmpty)
                ...completedDays.map(
                  (d) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text('  ✓ ${dayFmt.format(d)}',
                        style: const pw.TextStyle(fontSize: 13)),
                  ),
                )
              else
                pw.Text('  No activities completed this week.',
                    style: const pw.TextStyle(fontSize: 13)),
              pw.SizedBox(height: 20),
              pw.Text(
                'Streak',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Current streak: $streak days',
                  style: const pw.TextStyle(fontSize: 14)),
              if (topSkill != null) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Skill Highlights',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Most practiced skill: $topSkill',
                    style: const pw.TextStyle(fontSize: 14)),
              ],
              pw.SizedBox(height: 20),
              pw.Text(
                'Milestones Achieved This Week',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 8),
              if (weeklyMilestones.isEmpty)
                pw.Text('None this week',
                    style: const pw.TextStyle(fontSize: 14))
              else
                ...weeklyMilestones.map(
                  (a) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text('  • ${a.milestoneId}',
                        style: const pw.TextStyle(fontSize: 13)),
                  ),
                ),
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'Generated by PlaySteps on $generatedDate',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    final startStr = DateFormat('MMM-d').format(_weekStart);
    final endStr = DateFormat('MMM-d').format(_weekEnd);

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'playsteps_week_${startStr}_${endStr}.pdf',
    );
  }
}
