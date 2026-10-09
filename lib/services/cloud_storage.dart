import 'package:supabase_flutter/supabase_flutter.dart';

class CloudStorage {
  CloudStorage(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>?> loadCollection(String type) async {
    final row = await client
        .from('user_data')
        .select('payload')
        .eq('data_type', type)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    final payload = row['payload'];
    if (payload is! List) return <Map<String, dynamic>>[];
    return payload
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> saveCollection(
    String type,
    Iterable<Map<String, dynamic>> payload,
  ) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('You must be signed in to sync your data.');
    }
    await client.from('user_data').upsert({
      'user_id': userId,
      'data_type': type,
      'payload': payload.toList(),
      'amount': null,
      'unit': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_at': null,
    }, onConflict: 'user_id,data_type');
  }
}
