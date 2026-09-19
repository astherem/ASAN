class Recipes {
  final String name;
  final String? mealCategory;
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

  const Recipes({
    required this.name,
    this.description = '',
    this.mealCategory,
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
  });

  Recipes copyWith({
    String? name,
    String? description,
    String? mealCategory,
    String? notes,
    int? prepTime,
    int? cookTime,
    int? totalTime,
  }) {
    return Recipes(
      name: name ?? this.name,
      description: description ?? this.description,
      mealCategory: mealCategory ?? this.mealCategory,
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