import 'package:flutter/material.dart';

import '../data/stickers.dart';
import '../services/progress_store.dart';
import '../services/speaker.dart';
import '../widgets/motion.dart';

/// The animals a child has earned. Tap one to hear its name and see it hop;
/// locked ones are mystery shapes, so there is always one more to look
/// forward to.
class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({
    super.key,
    required this.speaker,
    required this.progress,
  });

  final Speaker speaker;
  final ProgressStore progress;

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen> {
  final Map<int, int> _bounces = {};

  void _tap(int i, bool unlocked) {
    setState(() => _bounces[i] = (_bounces[i] ?? 0) + 1);
    widget.speaker.speak(
      unlocked ? 'The ${stickers[i].name}!' : 'Keep playing to win this one!',
    );
  }

  @override
  void dispose() {
    widget.speaker.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.progress.stickersUnlocked;
    final toNext = starsPerSticker - widget.progress.stars % starsPerSticker;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('My stickers'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                unlocked == stickers.length
                    ? 'All $unlocked stickers! 🎉'
                    : '$unlocked of ${stickers.length}  ·  ⭐ $toNext more for the next one',
                key: const Key('sticker-count'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.all(12),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (var i = 0; i < stickers.length; i++)
                    Bounce(
                      trigger: _bounces[i] ?? 0,
                      child: Material(
                        color: i < unlocked
                            ? Colors.white
                            : const Color(0xFFEDE7D9),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          key: Key('sticker-$i'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _tap(i, i < unlocked),
                          child: Center(
                            child: i < unlocked
                                ? Text(stickers[i].emoji,
                                    style: const TextStyle(fontSize: 44))
                                : const Text('❔',
                                    style: TextStyle(
                                        fontSize: 32, color: Colors.black26)),
                          ),
                        ),
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
