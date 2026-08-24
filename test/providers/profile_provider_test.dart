import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:playsteps/data/database_helper.dart';
import 'package:playsteps/models/child_profile.dart';
import 'package:playsteps/providers/profile_provider.dart';

ChildProfile _profile(String name, {DateTime? dob}) => ChildProfile(
      name: name,
      dateOfBirth: dob ?? DateTime(2025, 1, 1),
      createdAt: DateTime(2025, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.testDatabasePath = inMemoryDatabasePath;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.instance.resetForTesting();
  });

  Future<ProfileProvider> newProvider() async =>
      ProfileProvider(await SharedPreferences.getInstance());

  group('initial state', () {
    test('starts loading with nothing selected', () async {
      final p = await newProvider();
      expect(p.isLoading, isTrue);
      expect(p.profiles, isEmpty);
      expect(p.activeProfile, isNull);
      expect(p.canAddMore, isTrue);
    });

    test('loading an empty database leaves the onboarding state', () async {
      final p = await newProvider();
      await p.loadProfiles();

      expect(p.isLoading, isFalse);
      expect(p.profiles, isEmpty);
      expect(p.activeProfile, isNull);
    });
  });

  group('adding profiles', () {
    test('the first profile becomes active automatically', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('Emma'));

      expect(p.profiles, hasLength(1));
      expect(p.activeProfile?.name, 'Emma');
      expect(p.activeProfile?.id, isNotNull);
    });

    test('caps at three children and silently ignores the fourth', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('A'));
      await p.addProfile(_profile('B'));
      await p.addProfile(_profile('C'));

      expect(p.canAddMore, isFalse);

      await p.addProfile(_profile('D'));
      expect(p.profiles, hasLength(3));
      expect(p.profiles.map((e) => e.name), isNot(contains('D')));
    });

    test('adding switches the active profile to the new child', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('First'));
      await p.addProfile(_profile('Second'));

      expect(p.activeProfile?.name, 'Second');
    });

    test('two children may share a name and stay distinct', () async {
      // Twins, or a re-used nickname: they must not collapse into one row.
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('Sam'));
      await p.addProfile(_profile('Sam'));

      expect(p.profiles, hasLength(2));
      expect(p.profiles[0].id, isNot(p.profiles[1].id));
    });
  });

  group('active profile persistence', () {
    test('the active choice survives a reload', () async {
      final prefs = await SharedPreferences.getInstance();
      final first = ProfileProvider(prefs);
      await first.loadProfiles();
      await first.addProfile(_profile('A'));
      await first.addProfile(_profile('B'));
      await first.setActiveProfile(first.profiles.first);

      final reloaded = ProfileProvider(prefs);
      await reloaded.loadProfiles();

      expect(reloaded.activeProfile?.name, 'A');
    });

    test('a stale saved id falls back to the first profile', () async {
      SharedPreferences.setMockInitialValues({'active_profile_id': 9999});
      final prefs = await SharedPreferences.getInstance();
      final p = ProfileProvider(prefs);
      await p.loadProfiles();
      await p.addProfile(_profile('Only'));

      final reloaded = ProfileProvider(prefs);
      await reloaded.loadProfiles();

      // The saved id points at a profile that no longer exists.
      expect(reloaded.activeProfile, isNotNull);
      expect(reloaded.activeProfile?.name, 'Only');
    });
  });

  group('updating', () {
    test('an edit is reflected in the list and the active profile', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('Old Name'));

      final edited = p.activeProfile!.copyWith(name: 'New Name');
      await p.updateProfile(edited);

      expect(p.activeProfile?.name, 'New Name');
      expect(p.profiles.single.name, 'New Name');
    });

    test('editing a non-active profile leaves the selection alone', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('A'));
      final a = p.profiles.first;
      await p.addProfile(_profile('B'));

      await p.updateProfile(a.copyWith(name: 'A edited'));

      expect(p.activeProfile?.name, 'B', reason: 'selection must not move');
      expect(p.profiles.firstWhere((e) => e.id == a.id).name, 'A edited');
    });

    test('updating an unknown profile does not corrupt the list', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('Real'));

      await p.updateProfile(
        ChildProfile(
          id: 4242,
          name: 'Ghost',
          dateOfBirth: DateTime(2025, 1, 1),
          createdAt: DateTime(2025, 1, 1),
        ),
      );

      expect(p.profiles, hasLength(1));
      expect(p.profiles.single.name, 'Real');
    });
  });

  group('deleting', () {
    test('removing the active profile promotes another', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('A'));
      await p.addProfile(_profile('B'));

      await p.deleteProfile(p.activeProfile!); // deletes B

      expect(p.profiles, hasLength(1));
      expect(p.activeProfile?.name, 'A');
    });

    test('removing the last profile clears the selection', () async {
      final prefs = await SharedPreferences.getInstance();
      final p = ProfileProvider(prefs);
      await p.loadProfiles();
      await p.addProfile(_profile('Only'));

      await p.deleteProfile(p.activeProfile!);

      expect(p.profiles, isEmpty);
      expect(p.activeProfile, isNull);
      expect(prefs.getInt('active_profile_id'), isNull,
          reason: 'a dangling id would be restored on next launch');
    });

    test('removing a non-active profile keeps the selection', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('A'));
      final a = p.profiles.first;
      await p.addProfile(_profile('B'));

      await p.deleteProfile(a);

      expect(p.activeProfile?.name, 'B');
      expect(p.profiles, hasLength(1));
    });

    test('deleting frees a slot again', () async {
      final p = await newProvider();
      await p.loadProfiles();
      await p.addProfile(_profile('A'));
      await p.addProfile(_profile('B'));
      await p.addProfile(_profile('C'));
      expect(p.canAddMore, isFalse);

      await p.deleteProfile(p.profiles.first);

      expect(p.canAddMore, isTrue);
      await p.addProfile(_profile('D'));
      expect(p.profiles, hasLength(3));
    });
  });

  group('listener notifications', () {
    test('load, add and delete each notify', () async {
      final p = await newProvider();
      var count = 0;
      p.addListener(() => count++);

      await p.loadProfiles();
      expect(count, greaterThan(0));

      final afterLoad = count;
      await p.addProfile(_profile('A'));
      expect(count, greaterThan(afterLoad));

      final afterAdd = count;
      await p.deleteProfile(p.activeProfile!);
      expect(count, greaterThan(afterAdd));
    });
  });
}
