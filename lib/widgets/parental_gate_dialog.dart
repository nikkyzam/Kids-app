import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({super.key});

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late int _a;
  late int _b;
  late int _correctAnswer;
  late List<int> _options;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  void _generateChallenge() {
    final rng = Random();
    _a = rng.nextInt(9) + 2;     // 2–10
    _b = rng.nextInt(9) + 2;     // 2–10
    _correctAnswer = _a * _b;

    final wrongAnswers = <int>{};
    while (wrongAnswers.length < 3) {
      final offset = rng.nextInt(10) - 5;
      final wrong = _correctAnswer + offset;
      if (wrong != _correctAnswer && wrong > 0) wrongAnswers.add(wrong);
    }

    _options = [_correctAnswer, ...wrongAnswers]..shuffle();
    _failed = false;
  }

  String _numberToWord(int n) {
    const words = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
    return n <= 10 ? words[n] : n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          const Text('Parent Check'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What is ${_numberToWord(_a)} times ${_numberToWord(_b)}?',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_failed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Incorrect — try again', style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: _options.map((opt) => OutlinedButton(
              onPressed: () => _checkAnswer(opt),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                foregroundColor: AppTheme.primary,
              ),
              child: Text('$opt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _checkAnswer(int answer) {
    if (answer == _correctAnswer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _failed = true;
        _generateChallenge();
      });
    }
  }
}
