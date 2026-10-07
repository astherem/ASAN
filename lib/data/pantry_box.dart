import 'package:asan/data/storage_box.dart';
import 'package:asan/models/pantry_item.dart';

class PantryBox {
  PantryBox(this._box);
  final StorageBox _box;

  List<PantryItem> read() => _box.readMaps().map(_fromJson).toList();
  Future<void> write(Iterable<PantryItem> items) =>
      _box.writeMaps(items.map(_toJson));

  static String? _date(DateTime? value) => value?.toIso8601String();
  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic> _toJson(PantryItem item) => {
    'name': item.name, 'amount': item.amount, 'unit': item.unit,
    'aisle': item.aisle, 'purchaseDate': _date(item.purchaseDate),
    'expiryDate': _date(item.expiryDate), 'notes': item.notes,
    'consumed': item.consumed, 'consumedDate': _date(item.consumedDate),
  };

  static PantryItem _fromJson(Map<String, dynamic> json) => PantryItem(
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
