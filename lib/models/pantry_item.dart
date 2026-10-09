class PantryItem {
  final String id;
  final DateTime updatedAt;
  final String name;
  final String amount;
  final String unit;
  final String? aisle;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String notes;
  final bool consumed;
  final DateTime? consumedDate;

  const PantryItem({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.amount,
    required this.unit,
    this.aisle,
    this.purchaseDate,
    this.expiryDate,
    required this.notes,
    this.consumed = false,
    this.consumedDate,
  });

  PantryItem copyWith({
    String? name,
    bool? consumed,
    DateTime? consumedDate,
    DateTime? updatedAt,
  }) =>
      PantryItem(
        id: id,
        updatedAt: updatedAt ?? this.updatedAt,
        name: name ?? this.name,
        amount: amount,
        unit: unit,
        aisle: aisle,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        notes: notes,
        consumed: consumed ?? this.consumed,
        consumedDate: consumedDate ?? this.consumedDate,
      );
}
