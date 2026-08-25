import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/child_profile.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../../utils/clock.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = Clock.now();
    DateTime? picked;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => Container(
          height: 300,
          color: Colors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            maximumDate: now,
            minimumDate: now.subtract(const Duration(days: 365 * 4)),
            initialDateTime:
                _selectedDob ?? now.subtract(const Duration(days: 90)),
            onDateTimeChanged: (dt) => picked = dt,
          ),
        ),
      );
      if (picked != null && mounted) setState(() => _selectedDob = picked);
    } else {
      final result = await showDatePicker(
        context: context,
        initialDate: _selectedDob ?? now.subtract(const Duration(days: 90)),
        firstDate: now.subtract(const Duration(days: 365 * 4)),
        lastDate: now,
        helpText: 'Select Date of Birth',
      );
      if (result != null && mounted) setState(() => _selectedDob = result);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDob == null) return;

    setState(() => _isSaving = true);
    try {
      final profile = ChildProfile(
        name: name,
        dateOfBirth: _selectedDob!,
        createdAt: Clock.now(),
      );
      await context.read<ProfileProvider>().addProfile(profile);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _selectedDob != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A soft wash behind the first screen so the page reads as a designed
      // surface rather than a blank form.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F5FF), AppTheme.surface],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          // On a tall screen the Spacer pushes the button to the bottom; on a
          // short one (small phones, split screen, or a visible keyboard) the
          // content scrolls instead of overflowing.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildForm(),
                        const Spacer(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7BA5F5), AppTheme.primary],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.glow(AppTheme.primary),
          ),
          child: const Icon(Icons.child_care_rounded,
              color: Colors.white, size: 38),
        ),
        const SizedBox(height: 24),
        Text('Welcome to\nPlaySteps',
            style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 10),
        Text(
          // The app has optional accounts and cloud sync for family sharing,
          // so the old "No accounts. No cloud." line was no longer true. What
          // is still true is that nothing leaves the device on its own.
          'No ads. No tracking. Just play.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Baby's Name or Nickname",
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'e.g. Emma or Bug',
          ),
        ),
        const SizedBox(height: 24),
        Text("Date of Birth", style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        // Mirrors inputDecorationTheme (radius, fill, padding) so the date
        // field and the name field read as the same control.
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedDob == null
                      ? const Color(0xFFEDF0F7)
                      : AppTheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDob == null
                          ? 'Tap to select date of birth'
                          : DateFormat('MMMM d, yyyy').format(_selectedDob!),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _selectedDob == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: _selectedDob == null
                            ? AppTheme.textMuted
                            : AppTheme.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _selectedDob == null
                        ? AppTheme.textMuted
                        : AppTheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedDob != null) ...[
          const SizedBox(height: 12),
          _buildAgeBadge(),
        ],
      ],
    );
  }

  Widget _buildAgeBadge() {
    final now = Clock.now();
    final days = now.difference(_selectedDob!).inDays;
    final weeks = days ~/ 7;
    String ageText;
    if (weeks < 4) {
      ageText = '$weeks week${weeks == 1 ? '' : 's'} old';
    } else if (weeks < 26) {
      ageText = '$weeks weeks old';
    } else {
      final months = ((now.year - _selectedDob!.year) * 12 +
          now.month -
          _selectedDob!.month);
      ageText = '$months month${months == 1 ? '' : 's'} old';
    }

    return TweenAnimationBuilder<double>(
      // Small entrance so the badge feels like a response to picking a date
      // rather than a jump in layout.
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: 0.85 + (0.15 * t),
        alignment: Alignment.centerLeft,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cake_rounded, size: 15, color: AppTheme.primary),
            const SizedBox(width: 7),
            Text(ageText,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // The glow appears only once the form is valid, so the button visibly
        // "wakes up" instead of just changing opacity.
        boxShadow: _canSave ? AppTheme.glow(AppTheme.primary) : const [],
      ),
      child: FilledButton(
        onPressed: (_canSave && !_isSaving) ? _saveProfile : null,
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Get Started'),
      ),
    );
  }
}
