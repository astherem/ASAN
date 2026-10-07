import 'package:hive_flutter/hive_flutter.dart';

class StorageBox {
  StorageBox(this._box);

  final Box<dynamic> _box;
  Future<void> _writeQueue = Future<void>.value();

  List<Map<String, dynamic>> readMaps() {
    return _box.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> writeMaps(Iterable<Map<String, dynamic>> values) async {
    final entries = values.toList();
    _writeQueue = _writeQueue.then((_) async {
      await _box.clear();
      await _box.putAll({
        for (var index = 0; index < entries.length; index++)
          index: entries[index],
      });
    });
    return _writeQueue;
  }

  List<String> readStrings() => _box.values.whereType<String>().toList();

  Future<void> writeStrings(Iterable<String> values) async {
    final entries = values.toList();
    _writeQueue = _writeQueue.then((_) async {
      await _box.clear();
      await _box.putAll({
        for (var index = 0; index < entries.length; index++) index: entries[index],
      });
    });
    return _writeQueue;
  }
}
