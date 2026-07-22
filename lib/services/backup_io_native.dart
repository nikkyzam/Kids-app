import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes [contents] to a file in the app documents directory and returns its
/// path. Native (mobile/desktop) implementation.
Future<String> writeBackupJson(String filename, String contents) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(contents);
  return file.path;
}

Future<String> readTextFile(String path) => File(path).readAsString();
