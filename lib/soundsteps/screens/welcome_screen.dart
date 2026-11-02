import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../widgets/mascot.dart';

/// First launch only, for the grown-up: meet Pip, optionally give the child's
/// name, go. One screen, one optional field: nothing between a toddler and
/// the games for longer than it takes to hand the phone over.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    widget.settings.childName = _name.text;
    widget.settings.onboarded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(size: 140, mood: MascotMood.happy),
                const SizedBox(height: 16),
                const Text('Welcome to SoundSteps',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                  'Letters and sounds for little ones, with Pip the chick. '
                  'No ads, no accounts, and everything stays on this phone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('welcome-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: "Your child's first name (optional)",
                    helperText: 'So Pip can say hello. Stays on this phone.',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _start(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('welcome-start'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFFF7043),
                    ),
                    onPressed: _start,
                    child: const Text("Let's play!",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
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
