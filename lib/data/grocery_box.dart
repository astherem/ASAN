import 'package:asan/data/storage_box.dart';
import 'package:asan/models/grocery_item.dart';

class GroceryBox {
  GroceryBox(this._box);
  final StorageBox _box;

  List<GroceryItem> read() =>
      _box.readMaps().map(_fromJson).toList();

  Future<void> write(Iterable<GroceryItem> items) =>
      _box.writeMaps(items.map(_toJson));

  static String? _date(DateTime? value) => value?.toIso8601String();
  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic> _toJson(GroceryItem item) => {
    'name': item.name, 'amount': item.amount, 'unit': item.unit,
    'aisle': item.aisle, 'notes': item.notes,
    'purchaseDate': _date(item.purchaseDate),
  };

  static GroceryItem _fromJson(Map<String, dynamic> json) => GroceryItem(
    name: json['name'] as String? ?? '',
    amount: json['amount'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    aisle: json['aisle'] as String?,
    notes: json['notes'] as String? ?? '',
    purchaseDate: _parseDate(json['purchaseDate']),
  );
}
