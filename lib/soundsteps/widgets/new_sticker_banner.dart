import 'package:flutter/material.dart';

import '../data/stickers.dart';
import 'motion.dart';

/// "New sticker!" — the sticker zooms in over the picture for the rest of the
/// celebration. Taps go through to nothing; the next round clears it.
class NewStickerBanner extends StatelessWidget {
  const NewStickerBanner(this.sticker, {super.key});

  final Sticker sticker;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        key: const Key('new-sticker'),
        color: const Color(0xCCFFFFFF),
        alignment: Alignment.center,
        child: FittedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'New sticker!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: motionEnabled(context) ? 0.2 : 1, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child:
                    Text(sticker.emoji, style: const TextStyle(fontSize: 120)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
