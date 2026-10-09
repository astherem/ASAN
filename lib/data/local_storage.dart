import 'package:hive_flutter/hive_flutter.dart';

import 'package:asan/data/grocery_box.dart';
import 'package:asan/data/meal_plan_box.dart';
import 'package:asan/data/pantry_box.dart';
import 'package:asan/data/recipe_box.dart';
import 'package:asan/data/saved_recipe_box.dart';
import 'package:asan/data/storage_box.dart';

import 'package:asan/models/grocery_item.dart';
import 'package:asan/models/api_recipe.dart';
import 'package:asan/models/meal_plans.dart';
import 'package:asan/models/pantry_item.dart';
import 'package:asan/models/recipes.dart';

class LocalStorage {
  LocalStorage._(
    Box<dynamic> groceriesBox,
    Box<dynamic> pantryBox,
    Box<dynamic> recipesBox,
    Box<dynamic> mealPlansBox,
    Box<dynamic> savedRecipesBox,
    Box<dynamic> profilePreferencesBox,
  ) : groceries = GroceryBox(StorageBox(groceriesBox)),
      pantry = PantryBox(StorageBox(pantryBox)),
      recipes = RecipeBox(StorageBox(recipesBox)),
      mealPlans = MealPlanBox(StorageBox(mealPlansBox)),
      savedRecipes = SavedRecipeBox(StorageBox(savedRecipesBox)),
      profilePreferences = StorageBox(profilePreferencesBox);

  static Future<LocalStorage> create() async {
    await Hive.initFlutter();
    return LocalStorage._(
      await Hive.openBox<dynamic>('groceries'),
      await Hive.openBox<dynamic>('pantry'),
      await Hive.openBox<dynamic>('recipes'),
      await Hive.openBox<dynamic>('meal_plans'),
      await Hive.openBox<dynamic>('saved_recipes'),
      await Hive.openBox<dynamic>('profile_preferences'),
    );
  }

  final GroceryBox groceries;
  final PantryBox pantry;
  final RecipeBox recipes;
  final MealPlanBox mealPlans;
  final SavedRecipeBox savedRecipes;
  final StorageBox profilePreferences;

  Map<String, dynamic> loadProfilePreferences() {
    final values = profilePreferences.readMaps();
    return values.isEmpty ? {} : values.first;
  }

  Future<void> saveProfilePreferences(Map<String, dynamic> values) =>
      profilePreferences.writeMaps([values]);

  Future<List<GroceryItem>> loadGroceries() async => groceries.read();
  Future<void> saveGroceries(Iterable<GroceryItem> items) =>
      groceries.write(items);

  Future<List<PantryItem>> loadPantry() async => pantry.read();
  Future<void> savePantry(Iterable<PantryItem> items) => pantry.write(items);

  Future<List<Recipes>> loadRecipes() async => recipes.read();
  Future<void> saveRecipes(Iterable<Recipes> items) => recipes.write(items);

  Future<List<MealPlans>> loadMealPlans() async => mealPlans.read();
  Future<void> saveMealPlans(Iterable<MealPlans> entries) =>
      mealPlans.write(entries);

  List<String> loadSavedRecipeTitles() => savedRecipes.read();
  Future<void> saveSavedRecipeTitles(Iterable<String> titles) =>
      savedRecipes.write(titles);

  List<ApiRecipe> loadSavedRecipes() {
    final recipes = savedRecipes.readRecipes();
    if (recipes.isNotEmpty) return recipes;
    return savedRecipes
        .read()
        .map(
          (title) => ApiRecipe(
            id: '',
            title: title,
            category: 'Recipe',
            description: '',
            difficulty: null,
            cuisine: null,
            tags: const [],
            imageUrl: '',
            instructions: const [],
            ingredients: const [],
            prepTime: 0,
            cookTime: 0,
            totalTime: 0,
            servings: 1,
            calories: 0,
            fats: 0,
            cholesterol: 0,
            sodium: 0,
            carbohydrates: 0,
            protein: 0,
          ),
        )
        .toList();
  }
  Future<void> saveSavedRecipes(Iterable<ApiRecipe> recipes) =>
      savedRecipes.writeRecipes(recipes);
}
