class AsanFilterSelection {
  final String sortBy;
  final bool sortAscending;
  final Set<String> purchaseStatuses;
  final Set<String> expirationStatuses;
  final Set<String> foodGroups;
  final Set<String> totalTimeRanges;
  final Set<String> mealTimeCategories;
  final Set<String> mealTimes;
  final Set<String> mealCategories;
  final Set<String> cuisines;

  const AsanFilterSelection({
    required this.sortBy,
    required this.sortAscending,
    required this.purchaseStatuses,
    required this.expirationStatuses,
    required this.foodGroups,
    this.totalTimeRanges = const {},
    this.mealTimeCategories = const {},
    this.mealTimes = const {},
    this.mealCategories = const {},
    this.cuisines = const {},
  });

  AsanFilterSelection copyWith({
    String? sortBy,
    bool? sortAscending,
    Set<String>? purchaseStatuses,
    Set<String>? expirationStatuses,
    Set<String>? foodGroups,
    Set<String>? totalTimeRanges,
    Set<String>? mealTimeCategories,
    Set<String>? mealTimes,
    Set<String>? mealCategories,
    Set<String>? cuisines,
  }) {
    return AsanFilterSelection(
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      purchaseStatuses: purchaseStatuses ?? this.purchaseStatuses,
      expirationStatuses: expirationStatuses ?? this.expirationStatuses,
      foodGroups: foodGroups ?? this.foodGroups,
      totalTimeRanges: totalTimeRanges ?? this.totalTimeRanges,
      mealTimeCategories: mealTimeCategories ?? this.mealTimeCategories,
      mealTimes: mealTimes ?? this.mealTimes,
      mealCategories: mealCategories ?? this.mealCategories,
      cuisines: cuisines ?? this.cuisines,
    );
  }
}

enum AsanFilterMenuType { pantry, groceries, recipes, meals }
