import 'dart:math';

import 'package:flutter/material.dart';

/// Whether to play decorative animation. Honours the device's "remove
/// animations" / reduce-motion setting; some children (and parents) need it.
bool motionEnabled(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// A controller that plays once each time [trigger] changes.
mixin _TriggerAnimation<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController controller;

  int get trigger;
  Duration get duration;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: duration);
  }

  void playIfTriggered(int oldTrigger) {
    if (trigger != oldTrigger && motionEnabled(context)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Pops the child up and settles it, each time [trigger] changes.
/// "I heard you": used on tapped letters and on the picture when it speaks.
class Bounce extends StatefulWidget {
  const Bounce({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Bounce> createState() => _BounceState();
}

class _BounceState extends State<Bounce>
    with TickerProviderStateMixin, _TriggerAnimation<Bounce> {
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.92), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 40),
  ]);

  @override
  int get trigger => widget.trigger;
  @override
  Duration get duration => const Duration(milliseconds: 450);

  @override
  void didUpdateWidget(Bounce old) {
    super.didUpdateWidget(old);
    playIfTriggered(old.trigger);
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: controller.drive(_scale),
        child: widget.child,
      );
}

/// A quick side-to-side wobble, each time [trigger] changes. The gentle
/// "not that one": a shake, never a buzzer or a red cross.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake>
    with TickerProviderStateMixin, _TriggerAnimation<Shake> {
  @override
  int get trigger => widget.trigger;
  @override
  Duration get duration => const Duration(milliseconds: 400);

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    playIfTriggered(old.trigger);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        child: widget.child,
        builder: (context, child) {
          final t = controller.value;
          final dx = sin(t * pi * 4) * 12 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}

/// A burst of stars flying out from the centre, each time [trigger] changes.
/// Draws nothing at rest and ignores touches, so it can sit over anything.
class StarBurst extends StatefulWidget {
  const StarBurst({super.key, required this.trigger});

  final int trigger;

  @override
  State<StarBurst> createState() => _StarBurstState();
}

class _StarBurstState extends State<StarBurst>
    with TickerProviderStateMixin, _TriggerAnimation<StarBurst> {
  static const _count = 10;

  @override
  int get trigger => widget.trigger;
  @override
  Duration get duration => const Duration(milliseconds: 1000);

  @override
  void didUpdateWidget(StarBurst old) {
    super.didUpdateWidget(old);
    playIfTriggered(old.trigger);
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (!controller.isAnimating) return const SizedBox.shrink();
            final t = Curves.easeOut.transform(controller.value);
            return LayoutBuilder(builder: (context, box) {
              final reach = min(box.maxWidth, box.maxHeight) * 0.5;
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < _count; i++)
                    Transform.translate(
                      offset: Offset.fromDirection(
                        2 * pi * i / _count,
                        reach * t,
                      ),
                      child: Opacity(
                        opacity: (1 - controller.value).clamp(0.0, 1.0),
                        child: Text(
                          i.isEven ? '⭐' : '✨',
                          style: TextStyle(fontSize: 22 + 16 * (1 - t)),
                        ),
                      ),
                    ),
                ],
              );
            });
          },
        ),
      );
}
