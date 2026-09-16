class GroceryItem {
  final String name;
  final String quantity;
  final String unit;
  final String? foodGroup;
  final String notes;
  final DateTime? purchaseDate;

  const GroceryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.foodGroup,
    required this.notes,
    this.purchaseDate,
  });

  GroceryItem copyWith({String? name}) => GroceryItem(
    name: name ?? this.name,
    quantity: quantity,
    unit: unit,
    foodGroup: foodGroup,
    notes: notes,
    purchaseDate: purchaseDate,
  );
}
