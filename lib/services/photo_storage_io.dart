import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Overrides the storage root in tests, where `path_provider` has no platform
/// implementation to answer with.
String? testPhotoRoot;

/// Where photo memories live: a directory the app owns, inside its documents
/// area, so the OS never reclaims them.
Future<Directory> _photoDir() async {
  final root = testPhotoRoot ?? (await getApplicationDocumentsDirectory()).path;
  final dir = Directory('$root/photos');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

Future<String> photoStorageDirectory() async => (await _photoDir()).path;

/// Copies [sourcePath] into the app's own photo directory and returns the new
/// path.
///
/// The image picker hands back a file in the *cache* directory, which both
/// Android and iOS are free to purge whenever they need the space. Keeping the
/// picker's path meant a memory could quietly stop existing weeks later. The
/// copy is verified before the path is returned, so a write that ran out of
/// disk halfway reports a failure instead of leaving a truncated file behind
/// for the timeline to choke on.
Future<String> persistPhotoFile(String sourcePath, String filename) async {
  final dir = await _photoDir();
  final source = File(sourcePath);
  final expected = await source.length();
  final target = File('${dir.path}/$filename');

  try {
    await source.copy(target.path);
    final written = await target.length();
    if (written != expected) {
      throw const PhotoStorageException(
          'The photo did not copy completely — the device may be out of '
          'storage.');
    }
    return target.path;
  } on PhotoStorageException {
    await _deleteQuietly(target);
    rethrow;
  } on FileSystemException catch (e) {
    await _deleteQuietly(target);
    // ENOSPC is 28 on both Linux/Android and Darwin.
    final noSpace = e.osError?.errorCode == 28;
    throw PhotoStorageException(noSpace
        ? 'There is not enough free storage on this device to save the photo.'
        : 'The photo could not be saved: ${e.message}');
  }
}

Future<void> deletePhotoFile(String path) async {
  final file = File(path);
  // Only files this app put there: a path from an older build could point at
  // the picker's cache or, in principle, somewhere in the user's own library,
  // and "delete my PlaySteps data" is not permission to delete that.
  if (!path.startsWith(await photoStorageDirectory())) return;
  await _deleteQuietly(file);
}

/// Removes every stored photo file, leaving the (now empty) directory.
Future<void> deleteAllPhotoFiles() async {
  final dir = await _photoDir();
  await for (final entity in dir.list()) {
    if (entity is File) await _deleteQuietly(entity);
  }
}

Future<void> _deleteQuietly(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // A file that cannot be deleted must not abort the wipe of the others.
  }
}

/// Whether there is plausibly room for [bytes] more.
///
/// Free space is not readable without a platform channel, so this makes no
/// prediction: it writes a probe of the requested size and reports whether the
/// write survived. That is a real answer rather than a guess, and it is cheap
/// at the sizes photos and backups actually use.
Future<bool> hasRoomFor(int bytes) async {
  final dir = await _photoDir();
  final probe = File('${dir.path}/.space_probe');
  try {
    await probe.writeAsBytes(List<int>.filled(bytes, 0), flush: true);
    final ok = await probe.length() == bytes;
    return ok;
  } on FileSystemException {
    return false;
  } finally {
    await _deleteQuietly(probe);
  }
}

class PhotoStorageException implements Exception {
  final String message;
  const PhotoStorageException(this.message);
  @override
  String toString() => message;
}
