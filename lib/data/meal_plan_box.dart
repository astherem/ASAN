import 'package:asan/data/recipe_box.dart';
import 'package:asan/data/storage_box.dart';
import 'package:asan/models/meal_plans.dart';

class MealPlanBox {
  MealPlanBox(this._box);
  final StorageBox _box;

  List<MealPlans> read() => _box.readMaps().map(fromJson).toList();

  static MealPlans fromJson(Map<String, dynamic> json) {
    final recipeJson = json['recipe'];
    if (recipeJson is! Map) {
      throw const FormatException('Meal plan entry has no recipe');
    }
    return MealPlans(
      date: DateTime.parse(json['date'] as String),
      mealTime: json['mealTime'] as String? ?? '',
      recipe: RecipeBox.fromJson(Map<String, dynamic>.from(recipeJson)),
      dishType: json['dishType'] as String?,
      servingsOverride: (json['servingsOverride'] as num?)?.toInt(),
    );
  }

  Future<void> write(Iterable<MealPlans> entries) =>
      _box.writeMaps(entries.map(toJson));

  static Map<String, dynamic> toJson(MealPlans entry) => {
    'date': entry.date.toIso8601String(),
    'mealTime': entry.mealTime,
    'recipe': RecipeBox.toJson(entry.recipe),
    'dishType': entry.dishType,
    'servingsOverride': entry.servingsOverride,
  };
}
