import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/child_profile.dart';
import '../../theme/app_theme.dart';
import '../../utils/clock.dart';

/// Edits a child's details after onboarding.
///
/// Onboarding asks for these once, which is no help to a parent who onboarded
/// before the app knew about due dates and sex, mistyped a birthday, or simply
/// did not want to answer at the time. Everything except the name and birth
/// date stays optional, and both optional answers can be taken back.
class EditChildSheet extends StatefulWidget {
  final ChildProfile profile;

  const EditChildSheet({super.key, required this.profile});

  /// Returns the edited profile, or null if the parent backed out.
  static Future<ChildProfile?> show(
      BuildContext context, ChildProfile profile) {
    return showModalBottomSheet<ChildProfile>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        // Lifts the sheet clear of the keyboard while the name is being typed.
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditChildSheet(profile: profile),
      ),
    );
  }

  @override
  State<EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends State<EditChildSheet> {
  late final TextEditingController _name;
  late DateTime _dateOfBirth;
  late DateTime? _dueDate;
  late ChildSex? _sex;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _dateOfBirth = widget.profile.dateOfBirth;
    _dueDate = widget.profile.dueDate;
    _sex = widget.profile.sex;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  Future<void> _pickDateOfBirth() async {
    final now = Clock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateOfBirth = picked;
      // A due date that no longer sits after the birth date would silently
      // stop correcting the age.
      if (_dueDate != null && !_dueDate!.isAfter(picked)) _dueDate = null;
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _dateOfBirth.add(const Duration(days: 42)),
      firstDate: _dateOfBirth.add(const Duration(days: 1)),
      // The same 17-week window the model clamps to.
      lastDate: _dateOfBirth.add(const Duration(days: 119)),
      helpText: 'Original due date',
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  void _save() {
    Navigator.pop(
      context,
      widget.profile.copyWith(
        name: _name.text.trim(),
        dateOfBirth: _dateOfBirth,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        sex: _sex,
        clearSex: _sex == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit ${widget.profile.name}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            const _Label('Name or nickname'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            const _Label('Date of birth'),
            _Field(
              label: DateFormat('MMMM d, yyyy').format(_dateOfBirth),
              icon: Icons.calendar_today_rounded,
              onTap: _pickDateOfBirth,
            ),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              value: _dueDate != null,
              onChanged: (on) {
                if (on) {
                  _pickDueDate();
                } else {
                  setState(() => _dueDate = null);
                }
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Arrived early',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                'Activities and milestones use the adjusted age until two.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
            if (_dueDate != null) ...[
              const SizedBox(height: 8),
              _Field(
                label: DateFormat('MMMM d, yyyy').format(_dueDate!),
                icon: Icons.event_rounded,
                onTap: _pickDueDate,
              ),
            ],
            const SizedBox(height: 20),
            const _Label('Sex (optional)'),
            const Text(
              'Only used to draw the right WHO growth curves.',
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
                    // Tapping the selected chip clears it, so an answer given
                    // by accident can be taken back.
                    onSelected: (selected) =>
                        setState(() => _sex = selected ? option : null),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _Field({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
              ),
              Icon(icon, color: AppTheme.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
