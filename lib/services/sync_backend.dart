import 'package:supabase_flutter/supabase_flutter.dart';

/// The remote operations sync needs, narrowed to two calls.
///
/// [SyncService] holds all of the merge and conflict logic and talks to the
/// backend only through this interface, so that logic can be tested against a
/// fake instead of a live Supabase project. [SupabaseSyncBackend] is the thin
/// adapter that actually issues the queries.
abstract class SyncBackend {
  /// Rows in [table] for [familyId] whose `updated_at` is at or after [since].
  Future<List<Map<String, dynamic>>> fetchSince(
    String table, {
    required String familyId,
    required String since,
  });

  /// Inserts or updates [rows] in [table], resolving collisions on the
  /// comma-separated column list [onConflict].
  Future<void> upsertAll(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
  });
}

class SupabaseSyncBackend implements SyncBackend {
  const SupabaseSyncBackend();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchSince(
    String table, {
    required String familyId,
    required String since,
  }) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('family_id', familyId)
        .gte('updated_at', since);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> upsertAll(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
  }) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert(rows, onConflict: onConflict);
  }
}
