import 'package:flutter/material.dart';

import '../data/tips_data.dart';
import '../theme/app_theme.dart';

class DailyTipCard extends StatefulWidget {
  const DailyTipCard({super.key});

  @override
  State<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends State<DailyTipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tip = TipsData.forToday();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: const Color(0xFF1A1D2E),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lightbulb_rounded, size: 12, color: AppTheme.secondary),
                          SizedBox(width: 4),
                          Text('Daily Insight', style: TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedCrossFade(
                  firstChild: Text(
                    tip.length > 90 ? '${tip.substring(0, 90)}…' : tip,
                    style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
                  ),
                  secondChild: Text(
                    tip,
                    style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
                  ),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                if (!_expanded)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Tap to read more', style: TextStyle(fontSize: 11, color: Colors.white38)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
