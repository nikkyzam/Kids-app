import 'package:flutter/material.dart';

import 'mascot.dart';
import 'parent_gate.dart';

/// Covers the whole app when the parent's break reminder is due. Pip falls
/// asleep and says so; only a grown-up (past the gate) can carry on. It is
/// deliberately calm: no countdown, no alarm.
class BreakOverlay extends StatelessWidget {
  const BreakOverlay({super.key, required this.onKeepPlaying});

  /// Called after a grown-up passes the gate.
  final VoidCallback onKeepPlaying;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('break-overlay'),
      color: const Color(0xFF2E2A5A),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(size: 160, mood: MascotMood.sleepy),
                const SizedBox(height: 24),
                const Text(
                  'Time for a break!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pip is having a little nap. Great playing today!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 40),
                TextButton.icon(
                  key: const Key('keep-playing'),
                  onPressed: () async {
                    if (await showParentGate(context)) onKeepPlaying();
                  },
                  icon: const Icon(Icons.lock_outline, color: Colors.white54),
                  label: const Text(
                    'Grown-ups: keep playing',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
