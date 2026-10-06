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
  final Set<String> days;

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
    this.days = const {},
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
    Set<String>? days,
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
      days: days ?? this.days,
    );
  }
}

enum AsanFilterMenuType { pantry, groceries, recipes, meals }

const asanAisles = [
  'Produce', 'Spices and Seasonings', 'Milk, Eggs, Other Dairy', 'Meat', 'Seafood',
  'Bakery/Bread', 'Pasta and Rice', 'Canned and Jarred', 'Frozen', 'Condiments', 'Beverages',
  'Baking', 'Nuts', 'Oil, Vinegar, Salad Dressing', 'Cereal', 'Snacks', 'Other',
];

const asanMealTimes = ['Breakfast', 'Brunch', 'Lunch', 'Snack', 'Dinner'];

const asanTotalTimes = [
  '15 minutes or less', '30 minutes or less', '1 hour or less', 'More than 1 hour',
];

String? asanTotalTimeRangeFor(int minutes) {
  if (minutes <= 0) return null;
  if (minutes <= 15) return asanTotalTimes[0];
  if (minutes <= 30) return asanTotalTimes[1];
  if (minutes <= 60) return asanTotalTimes[2];
  return asanTotalTimes[3];
}

const asanDiets = [
  'Gluten Free', 'Ketogenic', 'Vegetarian', 'Lacto-Vegetarian', 'Ovo-Vegetarian',
  'Vegan', 'Pescetarian', 'Paleo', 'Primal', 'Low FODMAP', 'Whole30',
];

const asanDishTypes = [
  'Main Course', 'Side Dish', 'Dessert', 'Appetizer', 'Salad', 'Bread',
  'Soup', 'Beverage', 'Sauce', 'Marinade', 'Fingerfood', 'Snack', 'Drink',
];

const asanCuisines = [
  'African', 'Asian', 'American', 'British', 'Cajun', 'Caribbean', 'Chinese',
  'Eastern European', 'European', 'French', 'German', 'Greek', 'Indian', 'Irish',
  'Italian', 'Japanese', 'Jewish', 'Korean', 'Latin American', 'Mediterranean',
  'Mexican', 'Middle Eastern', 'Nordic', 'Southern', 'Spanish', 'Thai', 'Vietnamese',
];
