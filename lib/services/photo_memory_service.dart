import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/photo_memory.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';
import 'photo_storage.dart';

/// Capturing a photo memory, end to end.
///
/// Shared by the activity card and the milestone ledger so the storage rules
/// hold in both: check for room before opening the camera, copy the picture
/// into storage the app owns, and only then write the row that points at it.
class PhotoMemoryService {
  PhotoMemoryService._();

  /// Opens the camera and stores the result against [referenceType] /
  /// [referenceId]. Returns the saved memory, or null if the parent backed out
  /// or the device had no room. Any failure is reported through [context]; the
  /// caller does not need to.
  static Future<PhotoMemory?> capture(
    BuildContext context, {
    required int profileId,
    required String referenceType,
    required String referenceId,
    ImageSource source = ImageSource.camera,
    String? caption,
    ImagePicker? picker,
  }) async {
    // Asked before the camera opens: framing a photo and then being told there
    // is nowhere to put it is a worse experience than being told up front.
    final hasRoom =
        await PhotoStorage.hasRoomFor(PhotoStorage.photoBudgetBytes);
    if (!context.mounted) return null;
    if (!hasRoom) {
      _report(
          context,
          'There is not enough free storage on this device to save a photo. '
          'Free up some space and try again.');
      return null;
    }

    final picked = await (picker ?? ImagePicker())
        .pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;

    String storedPath;
    try {
      storedPath =
          await PhotoStorage.persist(picked.path, id: const Uuid().v4());
    } on PhotoStorageException catch (e) {
      // No row is written: a memory pointing at a file that is not there is
      // worse than no memory, because it looks like data loss.
      if (context.mounted) _report(context, e.message);
      return null;
    }

    return DatabaseHelper.instance.savePhoto(PhotoMemory(
      profileId: profileId,
      referenceType: referenceType,
      referenceId: referenceId,
      imagePath: storedPath,
      caption: caption,
      capturedAt: Clock.now().toIso8601String(),
    ));
  }

  static void _report(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }
}
