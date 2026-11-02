import 'dart:async';

import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../data/stickers.dart';
import '../data/strokes.dart';
import '../services/progress_store.dart';
import '../services/speaker.dart';
import '../widgets/haptics.dart';
import '../widgets/mascot.dart';
import '../widgets/motion.dart';
import '../widgets/new_sticker_banner.dart';

/// Trace a capital letter with a finger. The guide is drawn wide and pale;
/// wherever the finger passes it fills in with colour, so the child "paints"
/// the letter. Numbered dots show where each stroke starts. Finishing earns a
/// star (not mastery: tracing is a motor skill, the games test the sound) and
/// moves on to the next letter.
class TraceScreen extends StatefulWidget {
  const TraceScreen({
    super.key,
    required this.speaker,
    required this.progress,
    this.startIndex = 0,
    this.nextDelay = const Duration(milliseconds: 2600),
  });

  final Speaker speaker;
  final ProgressStore progress;

  /// Index into [letters] to start from.
  final int startIndex;
  final Duration nextDelay;

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  late int _index = widget.startIndex;
  late TraceProgress _trace;
  final List<List<Offset>> _trail = [];
  bool _done = false;
  int _bursts = 0;
  Sticker? _newSticker;
  Timer? _next;

  LetterEntry get _letter => letters[_index];

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _intro());
  }

  @override
  void dispose() {
    _next?.cancel();
    widget.speaker.stop();
    super.dispose();
  }

  void _load() {
    _trace = TraceProgress(letterStrokes[_letter.letter]!);
    _trail.clear();
    _done = false;
    _newSticker = null;
  }

  void _intro() => widget.speaker.speak(
      'Trace the letter ${_letter.letter}. ${_letter.letter} says ${_letter.sound}.');

  void _go(int delta) {
    _next?.cancel();
    setState(() {
      _index = (_index + delta) % letters.length;
      if (_index < 0) _index += letters.length;
      _load();
    });
    _intro();
  }

  void _touch(Offset local, Size size) {
    if (_done) return;
    final p = Offset(local.dx / size.width, local.dy / size.height);
    _trail.last.add(p);
    final changed = _trace.touch(p);
    setState(() {});
    if (changed && _trace.complete) _finish();
  }

  void _finish() {
    final before = widget.progress.stickersUnlocked;
    widget.progress.addStar();
    final earned = widget.progress.stickersUnlocked > before
        ? stickers[widget.progress.stickersUnlocked - 1]
        : null;
    successHaptic(context);
    widget.speaker.speak('You traced ${_letter.letter}! ${_letter.letter} says '
        '${_letter.sound}.${earned == null ? '' : ' You won a sticker! The ${earned.name}!'}');
    setState(() {
      _done = true;
      _bursts++;
      _newSticker = earned;
    });
    _next = Timer(
      widget.nextDelay +
          (earned == null ? Duration.zero : const Duration(seconds: 2)),
      () {
        if (mounted) _go(1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFF),
      appBar: AppBar(
        title: const Text('Trace'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ListenableBuilder(
                listenable: widget.progress,
                builder: (_, __) => Text('⭐ ${widget.progress.stars}',
                    key: const Key('stars'),
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(builder: (context, box) {
                      final size = box.biggest;
                      return Stack(
                        children: [
                          Semantics(
                            label: 'Trace the letter ${_letter.letter}',
                            child: GestureDetector(
                              key: const Key('trace-pad'),
                              onPanStart: (d) {
                                _trail.add([]);
                                tapHaptic(context);
                                _touch(d.localPosition, size);
                              },
                              onPanUpdate: (d) => _touch(d.localPosition, size),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: CustomPaint(
                                  size: size,
                                  painter: _TracePainter(
                                    trace: _trace,
                                    trail: _trail,
                                    done: _done,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(child: StarBurst(trigger: _bursts)),
                          if (_newSticker != null)
                            Positioned.fill(
                                child: NewStickerBanner(_newSticker!)),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Mascot(
                    size: 64,
                    cheer: _bursts,
                    mood: _done ? MascotMood.happy : MascotMood.idle,
                  ),
                  const Spacer(),
                  _RoundButton(
                    key: const Key('trace-prev'),
                    icon: Icons.arrow_back_rounded,
                    label: 'Previous letter',
                    onTap: () => _go(-1),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_letter.letter}${_letter.letter.toLowerCase()}',
                    key: const Key('trace-letter'),
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 12),
                  _RoundButton(
                    key: const Key('trace-next'),
                    icon: Icons.arrow_forward_rounded,
                    label: 'Next letter',
                    onTap: () => _go(1),
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: const Color(0xFF7E57C2),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      );
}

class _TracePainter extends CustomPainter {
  _TracePainter({required this.trace, required this.trail, required this.done});

  final TraceProgress trace;
  final List<List<Offset>> trail;
  final bool done;

  // Repaint on every touch: the objects are mutated in place.
  @override
  bool shouldRepaint(_TracePainter old) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    Offset at(Offset p) => Offset(p.dx * w, p.dy * size.height);
    final width = w * 0.11;

    final guide = Paint()
      ..color = const Color(0xFFE6DEF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final filled = Paint()
      ..color = done ? const Color(0xFF43A047) : const Color(0xFF7E57C2)
      ..style = PaintingStyle.fill;

    for (final stroke in trace.strokes) {
      final path = Path()..moveTo(at(stroke.first).dx, at(stroke.first).dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(at(p).dx, at(p).dy);
      }
      canvas.drawPath(path, guide);
    }

    // Covered guide points become a painted band.
    for (var s = 0; s < trace.strokes.length; s++) {
      for (var i = 0; i < trace.strokes[s].length; i++) {
        if (trace.isVisited(s, i)) {
          canvas.drawCircle(at(trace.strokes[s][i]), width * 0.5, filled);
        }
      }
    }

    // Faint finger trail, so off-guide scribbles still show something.
    final finger = Paint()
      ..color = const Color(0x557E57C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    for (final line in trail) {
      if (line.length < 2) continue;
      final path = Path()..moveTo(at(line.first).dx, at(line.first).dy);
      for (final p in line.skip(1)) {
        path.lineTo(at(p).dx, at(p).dy);
      }
      canvas.drawPath(path, finger);
    }

    // Numbered start dots for the strokes still to do. Painted last-first so
    // that where strokes share a start (A's apex) "1" is the one on top.
    if (done) return;
    for (var s = trace.strokes.length - 1; s >= 0; s--) {
      if (trace.strokeCoverage(s) >= strokeGoal) continue;
      final c = at(trace.strokes[s].first);
      canvas.drawCircle(
          c, width * 0.42, Paint()..color = const Color(0xFFFF7043));
      final tp = TextPainter(
        text: TextSpan(
          text: '${s + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }
}
