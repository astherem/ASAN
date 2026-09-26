import 'dart:typed_data';

class Recipes {
  final String name;
  final Uint8List? imageBytes;
  final String? mealCategory;
  final String? difficulty;
  final String? cuisine;
  final List<String> tags;
  final List<String> idealFor;
  final String description;
  final String notes;
  final int prepTime;
  final int cookTime;
  final int totalTime;
  final int servings;
  final int calories;
  final int fats;
  final int cholesterol;
  final int sodium;
  final int carbohydrates;
  final int protein;
  final List<String> dishTypes;
  final List<String> ingredients;
  final List<String> ingredientNotes;
  final List<String> instructions;
  final int healthScore;
  final int aggregateLikes;
  final double pricePerServing;
  final String? sourceName;
  final String? sourceUrl;

  const Recipes({
    required this.name,
    this.imageBytes,
    this.description = '',
    this.mealCategory,
    this.difficulty,
    this.cuisine,
    this.tags = const [],
    this.idealFor = const [],
    this.notes = '',
    this.prepTime = 0,
    this.cookTime = 0,
    this.totalTime = 0,
    this.servings = 1,
    this.calories = 0,
    this.fats = 0,
    this.cholesterol = 0,
    this.sodium = 0,
    this.carbohydrates = 0,
    this.protein = 0,
    this.dishTypes = const [],
    this.ingredients = const [],
    this.ingredientNotes = const [],
    this.instructions = const [],
    this.healthScore = 0, this.aggregateLikes = 0, this.pricePerServing = 0,
    this.sourceName, this.sourceUrl,
  });

  Recipes copyWith({
    String? name,
    Uint8List? imageBytes,
    String? description,
    String? mealCategory,
    String? difficulty,
    String? cuisine,
    List<String>? tags,
    List<String>? idealFor,
    String? notes,
    int? prepTime,
    int? cookTime,
    int? totalTime,
  }) {
    return Recipes(
      name: name ?? this.name,
      imageBytes: imageBytes ?? this.imageBytes,
      description: description ?? this.description,
      mealCategory: mealCategory ?? this.mealCategory,
      difficulty: difficulty ?? this.difficulty,
      cuisine: cuisine ?? this.cuisine,
      tags: tags ?? this.tags,
      idealFor: idealFor ?? this.idealFor,
      notes: notes ?? this.notes,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
    );
  }

  static String formatTotalTime(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '${hours}h'
        : '${hours}h ${remainingMinutes}m';
  }

  String get formattedTotalTime => formatTotalTime(totalTime);

}
