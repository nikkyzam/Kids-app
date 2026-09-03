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
  bool _bornEarly = false;
  DateTime? _selectedDueDate;
  ChildSex? _sex;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = Clock.now();
    final picked = await _showDatePicker(
      initial: _selectedDob ?? now.subtract(const Duration(days: 90)),
      first: now.subtract(const Duration(days: 365 * 4)),
      last: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        // A due date that no longer sits after the birth date would silently
        // stop correcting the age, so drop it and ask again.
        if (_selectedDueDate != null && !_selectedDueDate!.isAfter(picked)) {
          _selectedDueDate = null;
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final dob = _selectedDob;
    if (dob == null) return;
    // A due date can only ever be after the birth date, and at most 17 weeks
    // after it — the picker enforces the same window the model clamps to.
    final picked = await _showDatePicker(
      initial: _selectedDueDate ?? dob.add(const Duration(days: 42)),
      first: dob.add(const Duration(days: 1)),
      last: dob.add(const Duration(days: 119)),
      helpText: 'Select Original Due Date',
    );
    if (picked != null && mounted) setState(() => _selectedDueDate = picked);
  }

  Future<DateTime?> _showDatePicker({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
    required String helpText,
  }) async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      DateTime? picked;
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => Container(
          height: 300,
          color: Colors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            maximumDate: last,
            minimumDate: first,
            initialDateTime: initial,
            onDateTimeChanged: (dt) => picked = dt,
          ),
        ),
      );
      return picked;
    }
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: helpText,
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDob == null) return;

    setState(() => _isSaving = true);
    try {
      final profile = ChildProfile(
        name: name,
        dateOfBirth: _selectedDob!,
        dueDate: _bornEarly ? _selectedDueDate : null,
        sex: _sex,
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
      _nameController.text.trim().isNotEmpty &&
      _selectedDob != null &&
      // "Born early" without a due date would produce no correction at all,
      // so the parent would have answered a question that changed nothing.
      (!_bornEarly || _selectedDueDate != null);

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
        _FieldButton(
          label: _selectedDob == null
              ? 'Tap to select date of birth'
              : DateFormat('MMMM d, yyyy').format(_selectedDob!),
          filled: _selectedDob != null,
          icon: Icons.calendar_today_rounded,
          onTap: _pickDate,
        ),
        if (_selectedDob != null) ...[
          const SizedBox(height: 12),
          _buildAgeBadge(),
          const SizedBox(height: 20),
          _buildPrematureSection(),
        ],
        const SizedBox(height: 24),
        _buildSexSection(),
      ],
    );
  }

  Widget _buildPrematureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deliberately phrased as a fact about the birth, not as a problem to
        // declare. Parents of preemies hear enough clinical language already.
        SwitchListTile.adaptive(
          value: _bornEarly,
          onChanged: (v) => setState(() {
            _bornEarly = v;
            if (!v) _selectedDueDate = null;
          }),
          contentPadding: EdgeInsets.zero,
          title: const Text('Arrived early',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: const Text(
            "We'll match activities to their adjusted age until they turn two.",
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        if (_bornEarly) ...[
          const SizedBox(height: 8),
          _FieldButton(
            label: _selectedDueDate == null
                ? 'Tap to select original due date'
                : DateFormat('MMMM d, yyyy').format(_selectedDueDate!),
            filled: _selectedDueDate != null,
            icon: Icons.event_rounded,
            onTap: _pickDueDate,
          ),
        ],
      ],
    );
  }

  Widget _buildSexSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sex (optional)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        const Text(
          'Only used to draw the right WHO growth curves. You can skip it.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final option in ChildSex.values)
              ChoiceChip(
                label: Text(option.label),
                selected: _sex == option,
                // Tapping the selected chip clears it, so a parent who
                // answered by accident is not stuck with the answer.
                onSelected: (selected) =>
                    setState(() => _sex = selected ? option : null),
              ),
          ],
        ),
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

/// A tappable field that mirrors `inputDecorationTheme` so the date pickers
/// read as the same control as the name field beside them.
class _FieldButton extends StatelessWidget {
  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;

  const _FieldButton({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled
                  ? AppTheme.primary.withValues(alpha: 0.35)
                  : const Color(0xFFEDF0F7),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                    color: filled ? AppTheme.textDark : AppTheme.textMuted,
                  ),
                ),
              ),
              Icon(icon,
                  color: filled ? AppTheme.primary : AppTheme.textMuted,
                  size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
