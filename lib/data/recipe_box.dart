import 'dart:convert';
import 'dart:typed_data';

import 'package:asan/data/storage_box.dart';
import 'package:asan/models/recipes.dart';

class RecipeBox {
  RecipeBox(this._box);
  final StorageBox _box;

  List<Recipes> read() => _box.readMaps().map(fromJson).toList();
  Future<void> write(Iterable<Recipes> recipes) =>
      _box.writeMaps(recipes.map(toJson));

  static Map<String, dynamic> toJson(Recipes recipe) => {
    'name': recipe.name,
    'imageBytes': recipe.imageBytes == null ? null : base64Encode(recipe.imageBytes!),
    'imageUrl': recipe.imageUrl, 'mealCategory': recipe.mealCategory,
    'difficulty': recipe.difficulty, 'cuisine': recipe.cuisine,
    'tags': recipe.tags, 'idealFor': recipe.idealFor,
    'description': recipe.description, 'notes': recipe.notes,
    'prepTime': recipe.prepTime, 'cookTime': recipe.cookTime,
    'totalTime': recipe.totalTime, 'servings': recipe.servings,
    'calories': recipe.calories, 'fats': recipe.fats,
    'cholesterol': recipe.cholesterol, 'sodium': recipe.sodium,
    'carbohydrates': recipe.carbohydrates, 'protein': recipe.protein,
    'dishTypes': recipe.dishTypes, 'ingredients': recipe.ingredients,
    'ingredientAmounts': recipe.ingredientAmounts,
    'ingredientUnits': recipe.ingredientUnits,
    'ingredientNotes': recipe.ingredientNotes,
    'ingredientAisles': recipe.ingredientAisles,
    'instructions': recipe.instructions, 'healthScore': recipe.healthScore,
    'aggregateLikes': recipe.aggregateLikes,
    'pricePerServing': recipe.pricePerServing,
    'sourceName': recipe.sourceName, 'sourceUrl': recipe.sourceUrl,
  };

  static Recipes fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List? ?? const []).whereType<String>().toList();
    final encodedImage = json['imageBytes'] as String?;
    return Recipes(
      name: json['name'] as String? ?? '',
      imageBytes: encodedImage == null
          ? null
          : Uint8List.fromList(base64Decode(encodedImage)),
      imageUrl: json['imageUrl'] as String?,
      mealCategory: json['mealCategory'] as String?,
      difficulty: json['difficulty'] as String?,
      cuisine: json['cuisine'] as String?,
      tags: strings('tags'), idealFor: strings('idealFor'),
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      prepTime: (json['prepTime'] as num?)?.toInt() ?? 0,
      cookTime: (json['cookTime'] as num?)?.toInt() ?? 0,
      totalTime: (json['totalTime'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      fats: (json['fats'] as num?)?.toInt() ?? 0,
      cholesterol: (json['cholesterol'] as num?)?.toInt() ?? 0,
      sodium: (json['sodium'] as num?)?.toInt() ?? 0,
      carbohydrates: (json['carbohydrates'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      dishTypes: strings('dishTypes'), ingredients: strings('ingredients'),
      ingredientAmounts: strings('ingredientAmounts'),
      ingredientUnits: strings('ingredientUnits'),
      ingredientNotes: strings('ingredientNotes'),
      ingredientAisles: (json['ingredientAisles'] as List? ?? const [])
          .map((value) => value as String?)
          .toList(),
      instructions: strings('instructions'),
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
      aggregateLikes: (json['aggregateLikes'] as num?)?.toInt() ?? 0,
      pricePerServing: (json['pricePerServing'] as num?)?.toDouble() ?? 0,
      sourceName: json['sourceName'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
    );
  }
}
