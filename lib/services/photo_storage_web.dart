/// Web has no file system of its own to manage: the picker hands back a blob
/// URL that the browser owns, so there is nothing to copy, delete or measure.
/// Every call is a no-op that keeps the shared interface honest rather than
/// pretending to have stored something.
String? testPhotoRoot;

Future<String> photoStorageDirectory() async => '';

Future<String> persistPhotoFile(String sourcePath, String filename) async =>
    sourcePath;

Future<void> deletePhotoFile(String path) async {}

Future<void> deleteAllPhotoFiles() async {}

Future<bool> hasRoomFor(int bytes) async => true;

class PhotoStorageException implements Exception {
  final String message;
  const PhotoStorageException(this.message);
  @override
  String toString() => message;
}
