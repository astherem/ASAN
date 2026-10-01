class GroceryItem {
  final String name;
  final String amount;
  final String unit;
  final String? aisle;
  final String notes;
  final DateTime? purchaseDate;

  const GroceryItem({
    required this.name,
    required this.amount,
    required this.unit,
    this.aisle,
    required this.notes,
    this.purchaseDate,
  });

  GroceryItem copyWith({String? name}) => GroceryItem(
    name: name ?? this.name,
    amount: amount,
    unit: unit,
    aisle: aisle,
    notes: notes,
    purchaseDate: purchaseDate,
  );

}
