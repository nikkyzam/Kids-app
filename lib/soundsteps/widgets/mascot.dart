import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'motion.dart';

/// Pip's expression.
enum MascotMood {
  /// Blinks and bobs now and then.
  idle,

  /// Eyes squeezed shut in a grin, wings up.
  happy,

  /// Looks up, head tilted: "hmm, have another go".
  encourage,
}

/// Pip, the SoundSteps chick. Drawn in code, so there is no art asset to
/// license and it stays crisp at any size.
///
/// Every movement is a one-shot animation: a bob-and-blink every few seconds
/// from a timer, and a jump each time [cheer] changes. Nothing repeats
/// forever, so a test's `pumpAndSettle` still settles, and with the device's
/// reduce-motion setting on Pip simply stands still.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.mood = MascotMood.idle,
    this.cheer = 0,
    this.size = 96,
    this.onTap,
  });

  final MascotMood mood;

  /// Pip jumps each time this changes.
  final int cheer;
  final double size;
  final VoidCallback? onTap;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    _idle = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (mounted && motionEnabled(context) && !_jump.isAnimating) {
        _bob.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (widget.cheer != old.cheer && motionEnabled(context)) {
      _jump.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    _bob.dispose();
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pip the chick',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bob, _jump]),
          builder: (context, _) {
            final bob = sin(_bob.value * pi) * 0.06; // gentle sway
            final jump = sin(_jump.value * pi); // up and back down
            // Blink in the middle of each idle bob.
            final blinking =
                _bob.isAnimating && (_bob.value - 0.5).abs() < 0.12;
            return Transform.translate(
              offset: Offset(0, -jump * widget.size * 0.25),
              child: Transform.rotate(
                angle: widget.mood == MascotMood.encourage ? -0.15 : bob,
                child: SizedBox.square(
                  dimension: widget.size,
                  child: CustomPaint(
                    painter: _PipPainter(
                      mood: widget.mood,
                      blinking: blinking,
                      flap: _jump.isAnimating ? jump : 0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter({required this.mood, required this.blinking, required this.flap});

  final MascotMood mood;
  final bool blinking;

  /// 0..1 wing lift while jumping.
  final double flap;

  static const _body = Color(0xFFFFD54F);
  static const _belly = Color(0xFFFFF3C4);
  static const _orange = Color(0xFFFF8A3D);
  static const _cheek = Color(0x66FF6F91);
  static const _ink = Color(0xFF3E2723);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, w * 0.55);
    final r = w * 0.38;
    final fill = Paint()..style = PaintingStyle.fill;

    // Feet.
    fill.color = _orange;
    for (final dx in [-0.14, 0.14]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx + dx * w, c.dy + r * 0.98),
            width: w * 0.16,
            height: w * 0.07),
        fill,
      );
    }

    // Wings, lifted while cheering.
    final happy = mood == MascotMood.happy;
    final lift = happy ? 0.5 + 0.5 * flap : 0.0;
    fill.color = const Color(0xFFFFC107);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(c.dx + side * r * 0.92, c.dy + r * 0.1);
      canvas.rotate(side * (0.3 + lift * 0.9) * -1);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: r * 0.45, height: r * 0.8),
          fill);
      canvas.restore();
    }

    // Body and belly.
    fill.color = _body;
    canvas.drawCircle(c, r, fill);
    fill.color = _belly;
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(0, r * 0.35), width: r * 1.2, height: r * 0.95),
      fill,
    );

    // Tuft.
    final tuft = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.05, 0.0, 0.05]) {
      final base = Offset(c.dx + dx * w, c.dy - r * 0.95);
      canvas.drawLine(base, base.translate(dx * w * 0.8, -w * 0.09), tuft);
    }

    // Eyes.
    final eyeY = c.dy - r * 0.22;
    final look = mood == MascotMood.encourage ? -r * 0.06 : 0.0;
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.33, 0.33]) {
      final e = Offset(c.dx + dx * r, eyeY + look);
      if (happy || blinking) {
        // ^ ^ when happy, a flat line when blinking.
        final path = Path()
          ..moveTo(e.dx - r * 0.12, e.dy + (happy ? r * 0.04 : 0))
          ..quadraticBezierTo(e.dx, e.dy - (happy ? r * 0.12 : 0),
              e.dx + r * 0.12, e.dy + (happy ? r * 0.04 : 0));
        canvas.drawPath(path, ink);
      } else {
        fill.color = _ink;
        canvas.drawCircle(e, r * 0.11, fill);
        fill.color = Colors.white;
        canvas.drawCircle(e.translate(r * 0.04, -r * 0.04), r * 0.035, fill);
      }
    }

    // Cheeks.
    fill.color = _cheek;
    for (final dx in [-0.55, 0.55]) {
      canvas.drawCircle(Offset(c.dx + dx * r, c.dy + r * 0.02), r * 0.11, fill);
    }

    // Beak: open when happy.
    fill.color = _orange;
    final beakTop = c.dy - r * 0.06;
    final beak = Path()
      ..moveTo(c.dx - r * 0.14, beakTop)
      ..lineTo(c.dx + r * 0.14, beakTop)
      ..lineTo(c.dx, beakTop + r * (happy ? 0.12 : 0.18))
      ..close();
    canvas.drawPath(beak, fill);
    if (happy) {
      final lower = Path()
        ..moveTo(c.dx - r * 0.1, beakTop + r * 0.16)
        ..lineTo(c.dx + r * 0.1, beakTop + r * 0.16)
        ..lineTo(c.dx, beakTop + r * 0.3)
        ..close();
      canvas.drawPath(lower, fill);
    }
  }

  @override
  bool shouldRepaint(_PipPainter old) =>
      old.mood != mood || old.blinking != blinking || old.flap != flap;
}
