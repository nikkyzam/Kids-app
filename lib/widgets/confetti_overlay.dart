import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void play() => _controller.play();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _controller,
        blastDirection: pi / 2,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 30,
        gravity: 0.3,
        emissionFrequency: 0.05,
        colors: const [
          Color(0xFF5B8DEF),
          Color(0xFFF5A623),
          Color(0xFF4CAF7D),
          Color(0xFFFF7043),
          Color(0xFF9C6FDE),
        ],
      ),
    );
  }
}
