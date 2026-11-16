// Renders the SoundSteps Play Store feature graphic (1024x500) with the real
// Pip widget, so the store art always matches the app. Not part of the app.
//
//   flutter build web -t tool/soundsteps_store_art.dart --web-renderer html
//   node tool/soundsteps_store_shots.js   (see docs/soundsteps/STORE_ASSETS.md)
import 'package:flutter/material.dart';
import 'package:playsteps/soundsteps/widgets/mascot.dart';

void main() => runApp(const _StoreArt());

class _StoreArt extends StatelessWidget {
  const _StoreArt();

  static const _tiles = [
    ('A', Color(0xFFFF7043), -0.18),
    ('b', Color(0xFF1E88E5), 0.12),
    ('C', Color(0xFF43A047), -0.08),
    ('d', Color(0xFF8E24AA), 0.16),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Nunito'),
      // Material gives the text its theme style; bare Text draws Flutter's
      // yellow-underlined "no Material ancestor" warning style.
      home: Material(
        child: Center(
          child: SizedBox(
            key: const Key('feature-graphic'),
            width: 1024,
            height: 500,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB07A), Color(0xFFFF8A5B)],
                ),
              ),
              child: Stack(
                children: [
                  // Soft circles for depth.
                  const Positioned(
                      left: -60, top: -80, child: _Blob(size: 320)),
                  const Positioned(
                      right: -40, bottom: -120, child: _Blob(size: 360)),
                  const Positioned(
                    left: 70,
                    top: 70,
                    child: Mascot(size: 360, mood: MascotMood.happy),
                  ),
                  Positioned(
                    left: 470,
                    top: 92,
                    right: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SoundSteps',
                          style: TextStyle(
                            fontSize: 84,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Letters & sounds for little ones',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5A2A12),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            for (final (letter, color, tilt) in _tiles)
                              Padding(
                                padding: const EdgeInsets.only(right: 18),
                                child: Transform.rotate(
                                  angle: tilt,
                                  child: Container(
                                    width: 92,
                                    height: 92,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 8,
                                            offset: Offset(0, 4)),
                                      ],
                                    ),
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        fontSize: 58,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0x22FFFFFF),
          shape: BoxShape.circle,
        ),
      );
}
