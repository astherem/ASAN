import 'package:asan/models/recipes.dart';

class MealPlans {
  final DateTime date;
  final String mealTime;
  final Recipes recipe;
  final String? dishType;
  final int? servingsOverride;

  const MealPlans({
    required this.date,
    required this.mealTime,
    required this.recipe,
    this.dishType,
    this.servingsOverride,
  });

  int get servings => servingsOverride ?? recipe.servings;

  bool isOnDate(DateTime other) =>
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;

  MealPlans copyWith({
    DateTime? date,
    String? mealTime,
    Recipes? recipe,
    String? dishType,
    int? servingsOverride,
  }) {
    return MealPlans (
      date: date ?? this.date,
      mealTime: mealTime ?? this.mealTime,
      recipe: recipe ?? this.recipe,
      dishType: dishType ?? this.dishType,
      servingsOverride: servingsOverride ?? this.servingsOverride,
    );
  }

}
