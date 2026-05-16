import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/child_profile.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

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
    final now = DateTime.now();
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
            initialDateTime: _selectedDob ?? now.subtract(const Duration(days: 90)),
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
        createdAt: DateTime.now(),
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

  bool get _canSave => _nameController.text.trim().isNotEmpty && _selectedDob != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildForm(),
              const Spacer(),
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.child_care_rounded, color: AppTheme.primary, size: 32),
        ),
        const SizedBox(height: 20),
        Text('Welcome to\nPlaySteps', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          'No accounts. No cloud. Just play.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Baby's Name or Nickname", style: Theme.of(context).textTheme.labelLarge),
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
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(12),
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
                      color: _selectedDob == null ? AppTheme.textMuted : AppTheme.textDark,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted, size: 18),
              ],
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
    final now = DateTime.now();
    final days = now.difference(_selectedDob!).inDays;
    final weeks = days ~/ 7;
    String ageText;
    if (weeks < 4) {
      ageText = '$weeks week${weeks == 1 ? '' : 's'} old';
    } else if (weeks < 26) {
      ageText = '$weeks weeks old';
    } else {
      final months = ((now.year - _selectedDob!.year) * 12 + now.month - _selectedDob!.month);
      ageText = '$months month${months == 1 ? '' : 's'} old';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cake_rounded, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(ageText, style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedOpacity(
      opacity: _canSave ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: FilledButton(
        onPressed: (_canSave && !_isSaving) ? _saveProfile : null,
        child: _isSaving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Get Started'),
      ),
    );
  }
}
