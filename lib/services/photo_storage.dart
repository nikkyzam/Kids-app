import 'package:flutter/foundation.dart' show visibleForTesting;

import 'photo_storage_io.dart' if (dart.library.html) 'photo_storage_web.dart'
    as io;

/// Photo memories on disk.
///
/// Photos are the one thing in this app a parent cannot recreate, so they get
/// their own directory that the app owns and the OS will not reclaim, and every
/// write is verified before a database row is allowed to point at it.
class PhotoStorage {
  PhotoStorage._();

  /// Copies a picked image into the app's own storage, returning the stored
  /// path. Throws [PhotoStorageException] — with a message worth showing a
  /// parent — if the device is out of room.
  static Future<String> persist(String sourcePath, {required String id}) {
    final extension = _extensionOf(sourcePath);
    return io.persistPhotoFile(sourcePath, '$id$extension');
  }

  static Future<void> delete(String path) => io.deletePhotoFile(path);

  static Future<void> deleteAll() => io.deleteAllPhotoFiles();

  /// Whether a write of roughly [bytes] would succeed right now.
  static Future<bool> hasRoomFor(int bytes) => io.hasRoomFor(bytes);

  /// A generous allowance for one camera photo, used as the pre-flight check.
  static const int photoBudgetBytes = 8 * 1024 * 1024;

  /// Points photo storage at a throwaway directory in tests, where
  /// `path_provider` has no platform implementation.
  @visibleForTesting
  static set testRoot(String? root) => io.testPhotoRoot = root;

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf('/');
    if (dot <= slash || dot == -1) return '.jpg';
    final ext = path.substring(dot);
    // Guard against a query string or a suspiciously long tail being treated
    // as a file extension.
    return ext.length <= 5 ? ext : '.jpg';
  }
}

typedef PhotoStorageException = io.PhotoStorageException;
