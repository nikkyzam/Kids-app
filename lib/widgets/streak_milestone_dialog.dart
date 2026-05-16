import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import '../theme/app_theme.dart';

class StreakMilestoneDialog extends StatefulWidget {
  final int streak;
  const StreakMilestoneDialog({super.key, required this.streak});

  static bool isMilestone(int streak) =>
      const {7, 14, 21, 30, 60, 100}.contains(streak);

  static Future<void> showIfMilestone(BuildContext context, int streak) async {
    if (!isMilestone(streak)) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StreakMilestoneDialog(streak: streak),
    );
  }

  @override
  State<StreakMilestoneDialog> createState() => _StreakMilestoneDialogState();
}

class _StreakMilestoneDialogState extends State<StreakMilestoneDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _confetti.play();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String get _headline {
    if (widget.streak >= 100) return 'Legendary! 100 Days!';
    if (widget.streak >= 60) return 'Two Months Strong!';
    if (widget.streak >= 30) return 'One Month Streak!';
    if (widget.streak >= 21) return '3-Week Champion!';
    if (widget.streak >= 14) return 'Two Weeks!';
    return 'One Week Streak!';
  }

  String get _subtext {
    if (widget.streak >= 100) return 'You\'ve played with your baby every day for 100 days. That\'s extraordinary.';
    if (widget.streak >= 60) return 'Two months of daily play. Your dedication is building your baby\'s brain.';
    if (widget.streak >= 30) return 'A full month! Science shows consistent play at this age has lasting effects.';
    if (widget.streak >= 21) return 'Three weeks builds a habit. Play is now part of your daily rhythm.';
    if (widget.streak >= 14) return 'Two weeks of daily challenges. Your baby is noticing the difference.';
    return 'Seven days straight! You\'ve built the habit. Keep it going.';
  }

  String get _emoji {
    if (widget.streak >= 100) return '🏆';
    if (widget.streak >= 60) return '💫';
    if (widget.streak >= 30) return '🌟';
    if (widget.streak >= 21) return '🎯';
    if (widget.streak >= 14) return '🔥';
    return '⚡';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1D2E), Color(0xFF252840)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.streak}-Day Streak',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _headline,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtext,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Flame row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      min(widget.streak ~/ 7, 7),
                      (_) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(Icons.local_fire_department_rounded,
                            color: Color(0xFFFF7043), size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Keep It Going!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
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
          numberOfParticles: 50,
          gravity: 0.25,
          emissionFrequency: 0.04,
          colors: const [
            AppTheme.primary, AppTheme.secondary, AppTheme.success,
            Color(0xFFFF7043), Color(0xFF9C6FDE), Colors.white,
          ],
        ),
      ],
    );
  }
}
