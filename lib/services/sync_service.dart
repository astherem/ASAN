import 'package:asan/services/cloud_storage.dart';

class SyncService {
  SyncService(this.cloudStorage);

  final CloudStorage cloudStorage;

  Future<List<Map<String, dynamic>>> syncCollection(
    String type,
    Iterable<Map<String, dynamic>> localPayload,
    {Iterable<String> deletedKeys = const []}
  ) async {
    final local = localPayload.toList();
    final deleted = deletedKeys.toSet();
    final remote = await cloudStorage.loadCollection(type);
    if (remote == null) {
      await cloudStorage.saveCollection(type, [
        ...local,
        ...deleted.map((key) => _tombstone(key)),
      ]);
      return local;
    }

    final mergedByKey = <String, Map<String, dynamic>>{
      for (final item in remote) _keyFor(type, item): item,
    };
    for (final item in local) {
      // Local changes are preferred for records already present on both
      // devices, while records created on either device are retained.
      mergedByKey[_keyFor(type, item)] = item;
    }
    for (final key in deleted) {
      mergedByKey[key] = _tombstone(key);
    }
    final merged = mergedByKey.values.toList();
    await cloudStorage.saveCollection(type, merged);
    return merged.where((item) => item['_deleted'] != true).toList();
  }

  String _keyFor(String type, Map<String, dynamic> item) {
    final syncKey = item['_syncKey'];
    if (syncKey is String) return syncKey;
    switch (type) {
      case 'pantry':
        return 'id:${item['id'] ?? _stableValue(item)}';
      case 'groceries':
        return 'grocery:${item['name']}|${item['aisle'] ?? ''}';
      case 'recipes':
        return 'recipe:${item['name']}';
      case 'saved_recipes':
        return 'saved:${item['id'] ?? item['title'] ?? _stableValue(item)}';
      case 'meal_plans':
        return 'meal:${item['date']}|${item['mealTime']}|'
            '${(item['recipe'] as Map?)?['name'] ?? ''}';
      default:
        return _stableValue(item);
    }
  }

  String _stableValue(Map<String, dynamic> item) =>
      item.entries.map((entry) => '${entry.key}=${entry.value}').join('|');

  Map<String, dynamic> _tombstone(String key) => {
        '_deleted': true,
        '_syncKey': key,
      };
}
