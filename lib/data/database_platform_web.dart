import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// On web, sqflite has no native implementation. Route it through the
// IndexedDB-backed FFI web factory so the existing DatabaseHelper code
// (openDatabase / onCreate / queries) works unchanged in the browser.
Future<void> configureDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}
