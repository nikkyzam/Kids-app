import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../services/settings_store.dart';

/// Haptic feedback, if the grown-up has it switched on. Off outside a
/// [SoundStepsScope] (screens pumped alone in tests). Uses the system's
/// haptic API, which needs no Android permission.
void tapHaptic(BuildContext context) {
  if (SoundStepsScope.maybeOf(context)?.haptics ?? false) {
    HapticFeedback.selectionClick();
  }
}

void successHaptic(BuildContext context) {
  if (SoundStepsScope.maybeOf(context)?.haptics ?? false) {
    HapticFeedback.mediumImpact();
  }
}
