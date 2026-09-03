import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../theme/app_theme.dart';

class ChildProfileDropdown extends StatelessWidget {
  final List<ChildProfile> profiles;
  final ChildProfile activeProfile;
  final ValueChanged<ChildProfile> onChanged;
  final bool canAddMore;

  const ChildProfileDropdown({
    super.key,
    required this.profiles,
    required this.activeProfile,
    required this.onChanged,
    this.canAddMore = true,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.length == 1) {
      return Text(activeProfile.name,
          style: Theme.of(context).appBarTheme.titleTextStyle);
    }

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(activeProfile.name,
              style: Theme.of(context).appBarTheme.titleTextStyle),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Select Profile',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            ...profiles.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.id == activeProfile.id
                        ? AppTheme.primary
                        : AppTheme.primaryLight,
                    child: Text(
                      p.name[0].toUpperCase(),
                      style: TextStyle(
                        color: p.id == activeProfile.id
                            ? Colors.white
                            : AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(p.name),
                  subtitle: Text(p.ageSummary),
                  trailing: p.id == activeProfile.id
                      ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (p.id != activeProfile.id) onChanged(p);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
