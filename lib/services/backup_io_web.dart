// Web has no direct file-system access; the backup UI guards these paths with
// kIsWeb, so these should never be reached on web.
Future<String> writeBackupJson(String filename, String contents) async =>
    throw UnsupportedError('File backup is not available on web.');

Future<String> readTextFile(String path) async =>
    throw UnsupportedError('File backup is not available on web.');
