import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/child_profile.dart';
import '../models/activity_completion.dart';
import '../models/milestone_achievement.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'playsteps.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE child_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        activity_id TEXT NOT NULL,
        date_key TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES child_profiles(id) ON DELETE CASCADE,
        UNIQUE(profile_id, date_key)
      )
    ''');

    await db.execute('''
      CREATE TABLE milestone_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        milestone_id TEXT NOT NULL,
        achieved_date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (profile_id) REFERENCES child_profiles(id) ON DELETE CASCADE,
        UNIQUE(profile_id, milestone_id)
      )
    ''');
  }

  // ─── Child Profiles ───────────────────────────────────────────────────────

  Future<List<ChildProfile>> getProfiles() async {
    final db = await database;
    final rows = await db.query('child_profiles', orderBy: 'created_at ASC');
    return rows.map(ChildProfile.fromMap).toList();
  }

  Future<ChildProfile> insertProfile(ChildProfile profile) async {
    final db = await database;
    final id = await db.insert('child_profiles', profile.toMap()..remove('id'));
    return profile.copyWith(id: id);
  }

  Future<void> updateProfile(ChildProfile profile) async {
    final db = await database;
    await db.update('child_profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<void> deleteProfile(int id) async {
    final db = await database;
    await db.delete('child_profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Activity Completions ─────────────────────────────────────────────────

  Future<ActivityCompletion?> getCompletion(int profileId, String dateKey) async {
    final db = await database;
    final rows = await db.query(
      'activity_completions',
      where: 'profile_id = ? AND date_key = ?',
      whereArgs: [profileId, dateKey],
    );
    return rows.isEmpty ? null : ActivityCompletion.fromMap(rows.first);
  }

  Future<List<ActivityCompletion>> getCompletions(int profileId) async {
    final db = await database;
    final rows = await db.query(
      'activity_completions',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'date_key DESC',
    );
    return rows.map(ActivityCompletion.fromMap).toList();
  }

  Future<void> saveCompletion(ActivityCompletion completion) async {
    final db = await database;
    await db.insert(
      'activity_completions',
      completion.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCompletion(int profileId, String dateKey) async {
    final db = await database;
    await db.delete(
      'activity_completions',
      where: 'profile_id = ? AND date_key = ?',
      whereArgs: [profileId, dateKey],
    );
  }

  // ─── Milestone Achievements ───────────────────────────────────────────────

  Future<List<MilestoneAchievement>> getAchievements(int profileId) async {
    final db = await database;
    final rows = await db.query(
      'milestone_achievements',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
    return rows.map(MilestoneAchievement.fromMap).toList();
  }

  Future<void> saveAchievement(MilestoneAchievement achievement) async {
    final db = await database;
    await db.insert(
      'milestone_achievements',
      achievement.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAchievement(int profileId, String milestoneId) async {
    final db = await database;
    await db.delete(
      'milestone_achievements',
      where: 'profile_id = ? AND milestone_id = ?',
      whereArgs: [profileId, milestoneId],
    );
  }

  Future<MilestoneAchievement?> getAchievement(int profileId, String milestoneId) async {
    final db = await database;
    final rows = await db.query(
      'milestone_achievements',
      where: 'profile_id = ? AND milestone_id = ?',
      whereArgs: [profileId, milestoneId],
    );
    return rows.isEmpty ? null : MilestoneAchievement.fromMap(rows.first);
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    await _db?.close();
    _db = null;
  }
}
