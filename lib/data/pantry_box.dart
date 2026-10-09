import 'package:asan/data/storage_box.dart';
import 'package:asan/models/pantry_item.dart';
import 'package:uuid/uuid.dart';

class PantryBox {
  PantryBox(this._box);
  final StorageBox _box;

  List<PantryItem> read() => _box.readMaps().map(fromJson).toList();
  Future<void> write(Iterable<PantryItem> items) =>
      _box.writeMaps(items.map(toJson));

  static String? _date(DateTime? value) => value?.toIso8601String();
  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic> toJson(PantryItem item) => {
    'id': item.id, 'updatedAt': item.updatedAt.toIso8601String(),
    'name': item.name, 'amount': item.amount, 'unit': item.unit,
    'aisle': item.aisle, 'purchaseDate': _date(item.purchaseDate),
    'expiryDate': _date(item.expiryDate), 'notes': item.notes,
    'consumed': item.consumed, 'consumedDate': _date(item.consumedDate),
  };

  static PantryItem fromJson(Map<String, dynamic> json) => PantryItem(
    id: json['id'] as String? ?? const Uuid().v4(),
    updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now().toUtc(),
    name: json['name'] as String? ?? '',
    amount: json['amount'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    aisle: json['aisle'] as String?,
    purchaseDate: _parseDate(json['purchaseDate']),
    expiryDate: _parseDate(json['expiryDate']),
    notes: json['notes'] as String? ?? '',
    consumed: json['consumed'] as bool? ?? false,
    consumedDate: _parseDate(json['consumedDate']),
  );
}
