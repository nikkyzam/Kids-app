import 'package:flutter/material.dart';

import '../data/letters.dart';
import '../data/stickers.dart';
import '../services/progress_store.dart';
import '../services/settings_store.dart';

/// Grown-ups only (opened behind the parental gate): how the child is doing,
/// and the few settings a parent may want. Everything shown and stored here
/// stays on the device.
class ParentCornerScreen extends StatefulWidget {
  const ParentCornerScreen({
    super.key,
    required this.progress,
    required this.settings,
    this.today,
  });

  final ProgressStore progress;
  final SettingsStore settings;

  /// Injectable "now" for tests.
  final DateTime? today;

  @override
  State<ParentCornerScreen> createState() => _ParentCornerScreenState();
}

class _ParentCornerScreenState extends State<ParentCornerScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.settings.childName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
            'This clears stars, stickers, learned letters and play time on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              key: const Key('parent-confirm-reset'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) await widget.progress.reset();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: const Text("Grown-ups' corner"),
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.progress, settings]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const Text(
              'Everything here stays on this device. Nothing is sent anywhere.',
              style: TextStyle(color: Colors.black54),
            ),
            _Section('Your child', [
              TextField(
                key: const Key('child-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'First name or nickname (optional)',
                  helperText: 'Pip uses it to say hello.',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => settings.childName = v,
              ),
            ]),
            _Section('Progress', [
              Row(children: [
                _Stat('⭐', '${widget.progress.stars}', 'stars'),
                _Stat(
                    '📒',
                    '${widget.progress.stickersUnlocked}/${stickers.length}',
                    'stickers'),
                _Stat('🔤', '${widget.progress.masteredCount}/26',
                    'letters learned'),
              ]),
              const SizedBox(height: 16),
              _PlayTimeChart(
                progress: widget.progress,
                today: widget.today ?? DateTime.now(),
              ),
              const SizedBox(height: 16),
              _MasteryGrid(progress: widget.progress),
            ]),
            _Section('Settings', [
              const Text('Speech speed'),
              const SizedBox(height: 6),
              SegmentedButton<SpeechSpeed>(
                key: const Key('speech-speed'),
                segments: const [
                  ButtonSegment(value: SpeechSpeed.slow, label: Text('Slow')),
                  ButtonSegment(
                      value: SpeechSpeed.normal, label: Text('Normal')),
                ],
                selected: {settings.speed},
                onSelectionChanged: (s) => settings.speed = s.first,
              ),
              const SizedBox(height: 16),
              const Text('Break reminder'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in SettingsStore.breakChoices)
                    ChoiceChip(
                      key: Key('break-$m'),
                      label: Text(m == 0 ? 'Off' : '$m min'),
                      selected: settings.breakMinutes == m,
                      onSelected: (_) => settings.breakMinutes = m,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'After this much play, Pip takes a nap and the games pause until '
                'a grown-up says to carry on.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              SwitchListTile(
                key: const Key('haptics'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Gentle vibration on taps'),
                value: settings.haptics,
                onChanged: (v) => settings.haptics = v,
              ),
              SwitchListTile(
                key: const Key('reduce-motion'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Calmer screen (fewer animations)'),
                value: settings.reduceMotion,
                onChanged: (v) => settings.reduceMotion = v,
              ),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('parent-reset'),
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset progress'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.emoji, this.value, this.label);

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      );
}

/// Minutes played on each of the last 7 days. One series, so one hue and no
/// legend; only today's bar carries its number. Bars sit on a shared baseline
/// with rounded tops.
class _PlayTimeChart extends StatelessWidget {
  const _PlayTimeChart({required this.progress, required this.today});

  final ProgressStore progress;
  final DateTime today;

  static const _bar = Color(0xFF7E57C2);
  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    final minutes = [for (final d in days) progress.minutesOn(d)];
    final peak = minutes.fold(0, (a, b) => a > b ? a : b);
    final week = minutes.fold(0, (a, b) => a + b);
    return Semantics(
      label: 'Minutes played, last 7 days: '
          '${[
        for (var i = 0; i < 7; i++)
          '${_dayLetters[days[i].weekday - 1]} ${minutes[i]}'
      ].join(', ')}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minutes played · last 7 days ($week min)',
                key: const Key('play-chart-title'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              // Tallest bar (60) + its label + the day letter, with room to
              // spare at larger text sizes.
              height: 112,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (i == 6)
                              Text('${minutes[i]}',
                                  key: const Key('play-today'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            Container(
                              height:
                                  peak == 0 ? 2 : 2 + 58 * minutes[i] / peak,
                              decoration: const BoxDecoration(
                                color: _bar,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_dayLetters[days[i].weekday - 1],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
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

/// A letter's state for the grown-ups' map.
enum LetterState {
  learned('Learned', '✓', Color(0xFF0CA30C), Colors.white),
  practising('Practising', '', Color(0xFFFAB219), Color(0xFF0B0B0B)),
  tricky('Tricky', '!', Color(0xFFEC835A), Colors.white),
  fresh('Not yet tried', '', Colors.white, Color(0xFF555555));

  const LetterState(this.label, this.mark, this.fill, this.ink);

  final String label;

  /// Second channel beside colour, so state is never colour alone.
  final String mark;
  final Color fill;
  final Color ink;

  static LetterState of(LetterStats s) {
    if (s.mastered) return learned;
    if (s.misses > s.correct) return tricky;
    if (s.isNew) return fresh;
    return practising;
  }
}

class _MasteryGrid extends StatelessWidget {
  const _MasteryGrid({required this.progress});

  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    final tricky = [
      for (final l in letters)
        if (LetterState.of(progress.statsFor(l.letter)) == LetterState.tricky)
          l.letter,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Letters', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final l in letters)
              () {
                final state = LetterState.of(progress.statsFor(l.letter));
                return Container(
                  key: Key('mastery-${l.letter}-${state.name}'),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: state.fill,
                    borderRadius: BorderRadius.circular(8),
                    border: state == LetterState.fresh
                        ? Border.all(color: const Color(0xFFD0D0D0))
                        : null,
                  ),
                  child: Text('${l.letter}${state.mark}',
                      style: TextStyle(
                          color: state.ink, fontWeight: FontWeight.w800)),
                );
              }(),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final s in LetterState.values)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: s.fill,
                    borderRadius: BorderRadius.circular(3),
                    border: s == LetterState.fresh
                        ? Border.all(color: const Color(0xFFD0D0D0))
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                Text('${s.label}${s.mark.isEmpty ? '' : ' ${s.mark}'}',
                    style: const TextStyle(fontSize: 12)),
              ]),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          tricky.isEmpty
              ? 'No tricky letters right now.'
              : 'Practising most: ${tricky.join(', ')}. The games bring these back more often.',
          key: const Key('tricky-letters'),
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
