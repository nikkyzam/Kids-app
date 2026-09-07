import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:playsteps/services/photo_storage.dart';

/// A photo memory is the one thing in this app a parent cannot recreate, so
/// the failures worth testing are the ones that end with a database row
/// pointing at a file that is missing or half-written.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('photo_storage_test');
    PhotoStorage.testRoot = root.path;
  });

  tearDown(() {
    PhotoStorage.testRoot = null;
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File sourceImage(String name, {int bytes = 32}) {
    final file = File('${root.path}/$name')
      ..writeAsBytesSync(List<int>.filled(bytes, 7));
    return file;
  }

  group('persisting a picked photo', () {
    test('copies it into storage the app owns', () async {
      final source = sourceImage('picked.jpg');

      final stored = await PhotoStorage.persist(source.path, id: 'mem-1');

      expect(stored, endsWith('/photos/mem-1.jpg'));
      expect(File(stored).readAsBytesSync(), source.readAsBytesSync());
      expect(source.existsSync(), isTrue,
          reason: 'the picker owns the original; it is copied, not moved');
    });

    test('reports a source it cannot read as a PhotoStorageException',
        () async {
      // The picker hands back a cache path the OS is free to purge, so by the
      // time it is copied the file may be gone. Measuring it used to happen
      // outside the guard, so this surfaced as a raw FileSystemException that
      // nothing up the stack caught.
      await expectLater(
        PhotoStorage.persist('${root.path}/never-existed.jpg', id: 'mem-2'),
        throwsA(isA<PhotoStorageException>()),
      );
    });

    test('leaves nothing behind when the copy fails', () async {
      try {
        await PhotoStorage.persist('${root.path}/never-existed.jpg',
            id: 'gone');
      } on PhotoStorageException {
        // expected
      }

      final dir = Directory('${root.path}/photos');
      final leftovers = dir.existsSync()
          ? dir.listSync().map((e) => e.path).toList()
          : <String>[];
      expect(leftovers, isEmpty,
          reason: 'a truncated file would be a broken memory in the timeline');
    });

    test('falls back to .jpg for a path with no usable extension', () async {
      final source = sourceImage('no-extension');

      final stored = await PhotoStorage.persist(source.path, id: 'mem-3');

      expect(stored, endsWith('mem-3.jpg'));
    });
  });

  group('the storage guard', () {
    test('says there is room for a photo-sized write', () async {
      expect(
          await PhotoStorage.hasRoomFor(PhotoStorage.photoBudgetBytes), isTrue);
    });

    test('cleans up its probe', () async {
      await PhotoStorage.hasRoomFor(1024);

      final dir = Directory('${root.path}/photos');
      expect(dir.listSync(), isEmpty);
    });
  });

  group('deleting', () {
    test('removes a file this app stored', () async {
      final stored =
          await PhotoStorage.persist(sourceImage('a.jpg').path, id: 'mem-4');

      await PhotoStorage.delete(stored);

      expect(File(stored).existsSync(), isFalse);
    });

    test('refuses a path outside its own directory', () async {
      // "Delete my PlaySteps data" is not permission to delete a file
      // elsewhere on the device, which a path from an older build could name.
      final outsider = sourceImage('not-ours.jpg');

      await PhotoStorage.delete(outsider.path);

      expect(outsider.existsSync(), isTrue);
    });

    test('deleteAll empties the directory without removing it', () async {
      await PhotoStorage.persist(sourceImage('a.jpg').path, id: 'mem-5');
      await PhotoStorage.persist(sourceImage('b.jpg').path, id: 'mem-6');

      await PhotoStorage.deleteAll();

      final dir = Directory('${root.path}/photos');
      expect(dir.existsSync(), isTrue);
      expect(dir.listSync(), isEmpty);
    });

    test('deleting a path that is already gone is not an error', () async {
      final stored =
          await PhotoStorage.persist(sourceImage('a.jpg').path, id: 'mem-7');
      File(stored).deleteSync();

      await expectLater(PhotoStorage.delete(stored), completes);
    });
  });
}
