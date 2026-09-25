class PantryItem {
  final String name;
  final String quantity;
  final String unit;
  final String? foodGroup;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String notes;
  final bool consumed;
  final DateTime? consumedDate;

  const PantryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.foodGroup,
    this.purchaseDate,
    this.expiryDate,
    required this.notes,
    this.consumed = false,
    this.consumedDate,
  });

  PantryItem copyWith({String? name, bool? consumed, DateTime? consumedDate}) =>
      PantryItem(
        name: name ?? this.name,
        quantity: quantity,
        unit: unit,
        foodGroup: foodGroup,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        notes: notes,
        consumed: consumed ?? this.consumed,
        consumedDate: consumedDate ?? this.consumedDate,
      );

}
