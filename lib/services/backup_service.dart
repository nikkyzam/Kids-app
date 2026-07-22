import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database_helper.dart';
import '../theme/app_theme.dart';

class BackupService {
  static Future<void> exportBackup(BuildContext context) async {
    try {
      final db = DatabaseHelper.instance;
      final profiles = await db.getProfiles();

      final profilesData = <Map<String, dynamic>>[];
      for (final profile in profiles) {
        final completions = await db.getCompletions(profile.id!);
        final achievements = await db.getAchievements(profile.id!);
        final badges = await db.getUnlockedBadgeIds(profile.id!);
        profilesData.add({
          'profile': profile.toMap(),
          'completions': completions.map((c) => c.toMap()).toList(),
          'achievements': achievements.map((a) => a.toMap()).toList(),
          'badge_ids': badges,
        });
      }

      final payload = <String, dynamic>{
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'profiles': profilesData,
      };

      final json = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/playsteps_backup_$timestamp.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'PlaySteps Backup',
        text: 'PlaySteps data backup — restore anytime in Settings.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  static Future<bool> importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return false;

      final rawJson = await File(result.files.single.path!).readAsString();
      final data = jsonDecode(rawJson) as Map<String, dynamic>;

      if ((data['version'] as int?) != 1) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsupported backup version.')),
          );
        }
        return false;
      }

      if (!context.mounted) return false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text(
            'This will replace all existing profiles, activities, and milestones. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore',
                  style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      );
      if (confirmed != true) return false;

      final rawDb = await DatabaseHelper.instance.database;
      await rawDb.transaction((txn) async {
        await txn.delete('milestone_achievements');
        await txn.delete('activity_completions');
        await txn.delete('unlocked_badges');
        await txn.delete('child_profiles');

        for (final entry in (data['profiles'] as List)) {
          final map = entry as Map<String, dynamic>;

          final profileMap = Map<String, dynamic>.from(map['profile'] as Map)
            ..remove('id');
          final newId = await txn.insert('child_profiles', profileMap);

          for (final c in (map['completions'] as List)) {
            final cm = Map<String, dynamic>.from(c as Map)..remove('id');
            cm['profile_id'] = newId;
            await txn.insert('activity_completions', cm,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          for (final a in (map['achievements'] as List)) {
            final am = Map<String, dynamic>.from(a as Map)..remove('id');
            am['profile_id'] = newId;
            await txn.insert('milestone_achievements', am,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
          for (final badgeId in (map['badge_ids'] as List)) {
            await txn.insert(
              'unlocked_badges',
              {
                'profile_id': newId,
                'badge_id': badgeId as String,
                'unlocked_at': DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
      return false;
    }
  }
}
