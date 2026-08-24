import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/developmental_leaps_data.dart';
import '../../models/developmental_leap.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

const _stormyColor = Color(0xFFFF7043);
const _stormyBg = Color(0xFFFBE9E7);
const _leapBg = Color(0xFFE8F8EF);
const _nextBg = Color(0xFFEEF3FE);
const _celebrateBg = Color(0xFFFFF8E1);

enum _LeapStatus { past, activeStormy, activeLeap, next, future }

_LeapStatus _statusFor(DevelopmentalLeap leap, int ageInWeeks) {
  if (ageInWeeks > leap.leapWeek + 2) return _LeapStatus.past;
  if (ageInWeeks >= leap.stormyStartWeek && ageInWeeks < leap.leapWeek) {
    return _LeapStatus.activeStormy;
  }
  if (ageInWeeks >= leap.leapWeek && ageInWeeks <= leap.leapWeek + 2) {
    return _LeapStatus.activeLeap;
  }
  return _LeapStatus.future;
}

class DevelopmentalLeapsScreen extends StatelessWidget {
  const DevelopmentalLeapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Developmental Leaps')),
        body: const Center(child: Text('No child profile found.')),
      );
    }

    final ageInWeeks = profile.ageInWeeks;
    final current = DevelopmentalLeapsData.currentLeap(ageInWeeks);
    final next = DevelopmentalLeapsData.nextLeap(ageInWeeks);
    const allLeaps = DevelopmentalLeapsData.all;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Developmental Leaps'),
            pinned: true,
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textDark,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          SliverToBoxAdapter(
            child: _HeroStatusCard(
              ageInWeeks: ageInWeeks,
              childName: profile.name,
              currentLeap: current,
              nextLeap: next,
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.linear_scale_rounded,
                      size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'All 10 Leaps',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final leap = allLeaps[index];
                _LeapStatus status = _statusFor(leap, ageInWeeks);
                if (status == _LeapStatus.future &&
                    next != null &&
                    leap.number == next.number) {
                  status = _LeapStatus.next;
                }
                final isLast = index == allLeaps.length - 1;
                return _TimelineLeapRow(
                  leap: leap,
                  status: status,
                  isLast: isLast,
                );
              },
              childCount: allLeaps.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({
    required this.ageInWeeks,
    required this.childName,
    required this.currentLeap,
    required this.nextLeap,
  });

  final int ageInWeeks;
  final String childName;
  final DevelopmentalLeap? currentLeap;
  final DevelopmentalLeap? nextLeap;

  @override
  Widget build(BuildContext context) {
    if (ageInWeeks > 77) {
      return _buildCelebrateCard(context);
    }
    if (currentLeap != null) {
      final isStormy = ageInWeeks >= currentLeap!.stormyStartWeek &&
          ageInWeeks < currentLeap!.leapWeek;
      if (isStormy) {
        return _buildStormyCard(context, currentLeap!);
      }
      return _buildLeapActiveCard(context, currentLeap!);
    }
    if (nextLeap != null) {
      return _buildNextLeapCard(context, nextLeap!);
    }
    return _buildCelebrateCard(context);
  }

  Widget _buildStormyCard(BuildContext context, DevelopmentalLeap leap) {
    final daysUntilPeak = (leap.leapWeek - ageInWeeks) * 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _stormyBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _stormyColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stormy Period — Leap ${leap.number} in progress!',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _stormyColor,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leap.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _stormyColor.withValues(alpha: 0.75),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _stormyColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                daysUntilPeak == 0
                    ? 'Leap peak is this week!'
                    : 'Leap peak in ~$daysUntilPeak day${daysUntilPeak == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _stormyColor,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              leap.whatToExpect,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _stormyColor.withValues(alpha: 0.85),
                height: 1.45,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeapActiveCard(BuildContext context, DevelopmentalLeap leap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _leapBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('\u{1F31F}', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leap ${leap.number} Happening Now!',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D52),
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leap.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A8A65),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              leap.whatsDeveloping,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D52),
                height: 1.45,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextLeapCard(BuildContext context, DevelopmentalLeap leap) {
    final weeksUntil = leap.stormyStartWeek - ageInWeeks;
    final daysUntil = weeksUntil * 7;
    final countdownText = weeksUntil == 0
        ? 'Starting this week!'
        : weeksUntil == 1
            ? 'In ~1 week ($daysUntil days)'
            : 'In ~$weeksUntil weeks ($daysUntil days)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _nextBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('\u{1F4C5}', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next: Leap ${leap.number} — ${leap.name}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$childName · $ageInWeeks week${ageInWeeks == 1 ? '' : 's'} old',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A6BC4),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Stormy period: $countdownText',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrateCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _celebrateBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('\u{1F389}', style: TextStyle(fontSize: 42)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All 10 developmental leaps complete!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A6200),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$childName has made it through every leap. What a journey!',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA07800),
                      height: 1.4,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineLeapRow extends StatelessWidget {
  const _TimelineLeapRow({
    required this.leap,
    required this.status,
    required this.isLast,
  });

  final DevelopmentalLeap leap;
  final _LeapStatus status;
  final bool isLast;

  Color get _dotColor {
    switch (status) {
      case _LeapStatus.past:
        return AppTheme.textMuted;
      case _LeapStatus.activeStormy:
        return _stormyColor;
      case _LeapStatus.activeLeap:
        return AppTheme.success;
      case _LeapStatus.next:
        return AppTheme.primary;
      case _LeapStatus.future:
        return AppTheme.primary.withValues(alpha: 0.3);
    }
  }

  bool get _isHighlighted =>
      status == _LeapStatus.activeStormy ||
      status == _LeapStatus.activeLeap ||
      status == _LeapStatus.next;

  bool get _isCurrent =>
      status == _LeapStatus.activeStormy || status == _LeapStatus.activeLeap;

  @override
  Widget build(BuildContext context) {
    final dotSize = _isHighlighted ? 14.0 : 10.0;
    final cardOpacity = status == _LeapStatus.past ? 0.6 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: _dotColor,
                      shape: BoxShape.circle,
                      boxShadow: _isHighlighted
                          ? [
                              BoxShadow(
                                color: _dotColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: _dotColor.withValues(alpha: 0.25),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Opacity(
                opacity: cardOpacity,
                child: _LeapExpansionCard(
                  leap: leap,
                  status: status,
                  isCurrent: _isCurrent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeapExpansionCard extends StatelessWidget {
  const _LeapExpansionCard({
    required this.leap,
    required this.status,
    required this.isCurrent,
  });

  final DevelopmentalLeap leap;
  final _LeapStatus status;
  final bool isCurrent;

  Color get _accentColor {
    switch (status) {
      case _LeapStatus.past:
        return AppTheme.textMuted;
      case _LeapStatus.activeStormy:
        return _stormyColor;
      case _LeapStatus.activeLeap:
        return AppTheme.success;
      case _LeapStatus.next:
        return AppTheme.primary;
      case _LeapStatus.future:
        return AppTheme.primaryLight;
    }
  }

  String get _statusLabel {
    switch (status) {
      case _LeapStatus.past:
        return 'Past ✓';
      case _LeapStatus.activeStormy:
        return 'Active ⚡';
      case _LeapStatus.activeLeap:
        return 'Happening Now ✓';
      case _LeapStatus.next:
        return 'Coming up';
      case _LeapStatus.future:
        return 'Upcoming';
    }
  }

  Color get _statusTextColor {
    switch (status) {
      case _LeapStatus.past:
        return AppTheme.textMuted;
      case _LeapStatus.activeStormy:
        return _stormyColor;
      case _LeapStatus.activeLeap:
        return AppTheme.success;
      case _LeapStatus.next:
        return AppTheme.primary;
      case _LeapStatus.future:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? _accentColor.withValues(alpha: 0.5)
        : const Color(0xFFEEF0F7);

    final accentEdge = isCurrent || status == _LeapStatus.next
        ? _accentColor
        : Colors.transparent;

    // Flutter forbids a borderRadius on a Border whose sides differ in colour
    // and throws during paint, so the accent edge cannot be a BorderSide here.
    // The card keeps a uniform rounded border and draws the accent as a clipped
    // strip inside it.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      // A Stack rather than a Row: the accent strip stretches to whatever
      // height the tile ends up (it grows when expanded) without imposing a
      // height constraint on the tile itself.
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            // ExpansionTile paints its ink splash on the nearest Material
            // ancestor. Without one here the surrounding decorated Container
            // hides the ripple, so tapping a leap gives no feedback.
            child: Material(
              type: MaterialType.transparency,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Leap ${leap.number}: ${leap.name}',
                          // Long leap names wrapped to a third line and
                          // overflowed the tile's height on narrow screens.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: status == _LeapStatus.future
                                ? AppTheme.textMuted
                                : AppTheme.textDark,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '~${leap.leapWeek} wks',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusTextColor,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                  children: [
                    _buildDivider(),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Fussy period',
                      value: '~week ${leap.stormyStartWeek}–${leap.leapWeek}',
                      color: _stormyColor,
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      context,
                      label: "What's developing",
                      content: leap.whatsDeveloping,
                      icon: Icons.psychology_outlined,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      context,
                      label: 'What to expect',
                      content: leap.whatToExpect,
                      icon: Icons.visibility_outlined,
                      color: _stormyColor,
                    ),
                    const SizedBox(height: 14),
                    _buildBulletSection(
                      context,
                      label: 'Parent tips',
                      items: leap.tips,
                      icon: Icons.lightbulb_outline_rounded,
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 14),
                    _buildBulletSection(
                      context,
                      label: 'Suggested activities',
                      items: leap.activitySuggestions,
                      icon: Icons.toys_outlined,
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: accentEdge),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: Color(0xFFEEF0F7),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Nunito',
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.textDark,
            height: 1.5,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildBulletSection(
    BuildContext context, {
    required String label,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textDark,
                      height: 1.45,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
