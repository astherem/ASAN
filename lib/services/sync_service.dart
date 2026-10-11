import 'package:asan/services/cloud_storage.dart';

class SyncService {
  SyncService(this.cloudStorage);
  final CloudStorage cloudStorage;

  Future<SyncResult> syncCollection(String type, Iterable<Map<String, dynamic>> localPayload, {Iterable<String> deletedKeys = const []}) async {
    final local = localPayload.toList();
    final deleted = deletedKeys.toSet();
    final remote = await cloudStorage.loadCollection(type);
    if (remote == null) {
      final initial = local.map(_stamp).toList();
      await cloudStorage.saveCollection(type, [...initial, ...deleted.map(_tombstone)]);
      return SyncResult(initial, added: initial.length, deleted: deleted.length);
    }
    final mergedByKey = <String, Map<String, dynamic>>{for (final item in remote) _keyFor(type, item): item};
    var added = 0, updated = 0, conflicts = 0, removed = 0;
    for (final raw in local) {
      final key = _keyFor(type, raw);
      final old = mergedByKey[key];
      final item = old == null ? _stamp(raw) : raw;
      if (old == null) { mergedByKey[key] = item; added++; continue; }
      if (_sameContent(old, item)) continue;
      conflicts++;
      final localAt = _timestamp(item), remoteAt = _timestamp(old);
      final localWins = localAt.isAfter(remoteAt) || (localAt.isAtSameMomentAs(remoteAt) && _stableValue(item).compareTo(_stableValue(old)) > 0);
      if (localWins) { mergedByKey[key] = item; updated++; }
    }
    for (final key in deleted) {
      final tombstone = {..._tombstone(key), '_syncUpdatedAt': DateTime.now().toUtc().toIso8601String()};
      final old = mergedByKey[key];
      if (old == null || _timestamp(tombstone).isAfter(_timestamp(old))) { mergedByKey[key] = tombstone; removed++; }
    }
    final merged = mergedByKey.values.toList();
    await cloudStorage.saveCollection(type, merged);
    return SyncResult(merged.where((item) => item['_deleted'] != true).toList(), added: added, updated: updated, deleted: removed, conflicts: conflicts);
  }

  Map<String, dynamic> _stamp(Map<String, dynamic> item) => {...item, '_syncUpdatedAt': item['_syncUpdatedAt'] ?? DateTime.now().toUtc().toIso8601String()};
  DateTime _timestamp(Map<String, dynamic> item) => DateTime.tryParse('${item['_syncUpdatedAt'] ?? item['updatedAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  bool _sameContent(Map<String, dynamic> a, Map<String, dynamic> b) => _stableValue({for (final e in a.entries) if (!e.key.startsWith('_sync')) e.key: e.value}) == _stableValue({for (final e in b.entries) if (!e.key.startsWith('_sync')) e.key: e.value});

  String _keyFor(String type, Map<String, dynamic> item) {
    final syncKey = item['_syncKey'];
    if (syncKey is String) return syncKey;
    switch (type) {
      case 'pantry': return 'id:${item['id'] ?? _stableValue(item)}';
      case 'groceries': return 'grocery:${item['name']}|${item['aisle'] ?? ''}';
      case 'recipes': return 'recipe:${item['name']}';
      case 'saved_recipes': return 'saved:${item['id'] ?? item['title'] ?? _stableValue(item)}';
      case 'meal_plans': return 'meal:${item['date']}|${item['mealTime']}|${(item['recipe'] as Map?)?['name'] ?? ''}';
      default: return _stableValue(item);
    }
  }
  String _stableValue(Map<String, dynamic> item) => item.entries.map((e) => '${e.key}=${e.value}').join('|');
  Map<String, dynamic> _tombstone(String key) => {'_deleted': true, '_syncKey': key, '_syncUpdatedAt': DateTime.now().toUtc().toIso8601String()};
}

class SyncResult {
  const SyncResult(this.items, {this.added = 0, this.updated = 0, this.deleted = 0, this.conflicts = 0});
  final List<Map<String, dynamic>> items;
  final int added, updated, deleted, conflicts;
}