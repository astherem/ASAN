class ApiRecipe {
  final String id;
  final String title;
  final String category;
  final String description;
  final String? difficulty;
  final String? cuisine;
  final List<String> tags;
  final String imageUrl;
  final List<String> instructions;
  final List<String> ingredients;
  final List<String?> ingredientAisles;
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

  const ApiRecipe({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.difficulty,
    required this.cuisine,
    required this.tags,
    required this.imageUrl,
    required this.instructions,
    required this.ingredients,
    this.ingredientAisles = const [],
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.calories,
    required this.fats,
    required this.cholesterol,
    required this.sodium,
    required this.carbohydrates,
    required this.protein,
    this.dishTypes = const [],
  });

  factory ApiRecipe.fromMealDbJson(Map<String, dynamic> meal) {
    String value(String key) => (meal[key] ?? '').toString().trim();
    final category = value('strCategory');
    final area = value('strArea');
    final tags = value('strTags')
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final ingredients = <String>[];
    for (var i = 1; i <= 20; i++) {
      final ingredient = value('strIngredient$i');
      if (ingredient.isEmpty) continue;
      final measure = value('strMeasure$i');
      ingredients.add(measure.isEmpty ? ingredient : '$measure $ingredient');
    }

    final rawInstructions = value('strInstructions');
    final instructions = rawInstructions
        .split(RegExp(r'\r?\n+|(?<=[.!?])\s+'))
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();

    return ApiRecipe(
      id: 'mealdb:${value('idMeal')}',
      title: value('strMeal').isEmpty ? 'Untitled recipe' : value('strMeal'),
      category: category.isEmpty ? 'Recipe' : category,
      description: '',
      difficulty: null,
      cuisine: area.isEmpty ? null : area,
      tags: tags,
      imageUrl: value('strMealThumb'),
      instructions: instructions,
      ingredients: ingredients,
      ingredientAisles: const [],
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
    );
  }

  factory ApiRecipe.fromDummyJson(Map<String, dynamic> recipe) {
    List<String> stringList(Object? value) => value is List
        ? value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList()
        : const <String>[];
    int number(Object? value, {int fallback = 0}) => value is num ? value.round() : fallback;
    String? optionalString(Object? value) {
      final text = value?.toString().trim();
      return text == null || text.isEmpty ? null : text;
    }

    final categories = stringList(recipe['mealType']);
    final tags = stringList(recipe['tags']).toList();
    return ApiRecipe(
      id: 'dummy:${recipe['id'] ?? ''}',
      title: '${recipe['name'] ?? 'Untitled recipe'}',
      category: categories.isNotEmpty ? categories.first : 'Recipe',
      description: '',
      difficulty: optionalString(recipe['difficulty']),
      cuisine: optionalString(recipe['cuisine']),
      tags: tags,
      imageUrl: '${recipe['image'] ?? ''}',
      instructions: stringList(recipe['instructions']),
      ingredients: stringList(recipe['ingredients']),
      prepTime: number(recipe['preparationMinutes']),
      cookTime: number(recipe['cookingMinutes']),
      totalTime: number(recipe['readyInMinutes'], fallback: number(recipe['prepTimeMinutes']) + number(recipe['cookTimeMinutes'])),
      servings: number(recipe['servings'], fallback: 1),
      calories: number(recipe['caloriesPerServing']),
      fats: 0,
      cholesterol: 0,
      sodium: 0,
      carbohydrates: 0,
      protein: 0,
    );
  }

  factory ApiRecipe.fromSpoonacularJson(Map<String, dynamic> recipe) {
    String text(Object? value) => value?.toString().trim() ?? '';
    int number(Object? value) => value is num ? value.round() : 0;
    final id = text(recipe['id']);
    final nutrition = recipe['nutrition'] is Map<String, dynamic>
        ? recipe['nutrition'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final nutrients = nutrition['nutrients'] is List
        ? (nutrition['nutrients'] as List).whereType<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];
    int nutrient(String name) {
      for (final item in nutrients) {
        if (item['name'] == name) return number(item['amount']);
      }
      return 0;
    }
    List<String> stringList(Object? value) => value is List
        ? value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList()
        : const <String>[];

    final instructions = <String>[];
    final analyzed = recipe['analyzedInstructions'];
    if (analyzed is List && analyzed.isNotEmpty && analyzed.first is Map) {
      final steps = (analyzed.first as Map)['steps'];
      if (steps is List) {
        for (final step in steps.whereType<Map>()) {
          final value = text(step['step']);
          if (value.isNotEmpty) instructions.add(value);
        }

      }
    }
    if (instructions.isEmpty) {
      final rawInstructions = text(recipe['instructions'])
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'&nbsp;|&#160;'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (rawInstructions.isNotEmpty) instructions.add(rawInstructions);
    }
    final extended = recipe['extendedIngredients'];
    final ingredientRecords = extended is List
        ? extended.whereType<Map>().map((item) {
            final original = text(item['original']).isNotEmpty
                ? text(item['original'])
                : text(item['originalString']);
            final formatted = original.isNotEmpty ? original : [text(item['amount']), text(item['unit']), text(item['name'])]
                .where((part) => part.isNotEmpty)
                .join(' ');
            final aisle = text(item['aisle']);
            return (formatted: formatted, aisle: aisle.isEmpty ? null : aisle);
          }).where((item) => item.formatted.isNotEmpty).toList()
        : <({String formatted, String? aisle})>[];
    final ingredients = ingredientRecords.map((item) => item.formatted).toList();
    final ingredientAisles = ingredientRecords.map((item) => item.aisle).toList();
    final cuisines = recipe['cuisines'] is List
        ? (recipe['cuisines'] as List).whereType<String>().toList()
        : const <String>[];
    final dishTypes = stringList(recipe['dishTypes'])
      .map((type) => type.toLowerCase() == 'morning meal' ? 'Breakfast' : type)
      .toList();
    final diets = stringList(recipe['diets']);
    final prepTime = number(recipe['preparationMinutes']);
    final cookTime = number(recipe['cookingMinutes']);
    final totalTime = number(recipe['readyInMinutes']);
    final tags = stringList(recipe['tags']).toList();
    void addTagIfMissing(String value) {
      if (value.trim().isNotEmpty &&
          !tags.any((tag) => tag.toLowerCase() == value.trim().toLowerCase())) {
        tags.add(value.trim());
      }
    }
    for (final diet in diets) {
      addTagIfMissing(diet);
    }
    if (recipe['vegetarian'] == true) addTagIfMissing('Vegetarian');
    if (recipe['vegan'] == true) addTagIfMissing('Vegan');
    tags.removeWhere((tag) => cuisines.any(
      (cuisine) => cuisine.toLowerCase() == tag.toLowerCase(),
    ));
    return ApiRecipe(
      id: 'spoonacular:$id', title: text(recipe['title']).isEmpty ? 'Untitled recipe' : text(recipe['title']),
      category: dishTypes.isNotEmpty ? dishTypes.first : 'Recipe',
      description: text(recipe['summary']).replaceAll(RegExp(r'<[^>]*>'), ''),
      difficulty: null, cuisine: cuisines.isEmpty ? null : cuisines.join(', '),
      tags: tags,
      imageUrl: text(recipe['image']), instructions: instructions, ingredients: ingredients,
      ingredientAisles: ingredientAisles,
      prepTime: prepTime, cookTime: cookTime,
      totalTime: totalTime > 0 ? totalTime : prepTime + cookTime,
      servings: number(recipe['servings']) == 0 ? 1 : number(recipe['servings']),
      calories: nutrient('Calories'), fats: nutrient('Fat'), cholesterol: nutrient('Cholesterol'),
      sodium: nutrient('Sodium'), carbohydrates: nutrient('Carbohydrates'), protein: nutrient('Protein'),
      dishTypes: dishTypes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'description': description,
        'difficulty': difficulty,
        'cuisine': cuisine,
        'tags': tags,
        'imageUrl': imageUrl,
        'instructions': instructions,
        'ingredients': ingredients,
        'ingredientAisles': ingredientAisles,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'totalTime': totalTime,
        'servings': servings,
        'calories': calories,
        'fats': fats,
        'cholesterol': cholesterol,
        'sodium': sodium,
        'carbohydrates': carbohydrates,
        'protein': protein,
        'dishTypes': dishTypes,
      };

  factory ApiRecipe.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) => value is List
        ? value.whereType<String>().toList()
        : const <String>[];
    List<String?> nullableStrings(Object? value) => value is List
        ? value.map((item) => item is String ? item : null).toList()
        : const <String?>[];
    int integer(Object? value) => value is num ? value.round() : 0;
    String text(Object? value) => value is String ? value : '';

    return ApiRecipe(
      id: text(json['id']),
      title: text(json['title']),
      category: text(json['category']),
      description: text(json['description']),
      difficulty: json['difficulty'] as String?,
      cuisine: json['cuisine'] as String?,
      tags: strings(json['tags']),
      imageUrl: text(json['imageUrl']),
      instructions: strings(json['instructions']),
      ingredients: strings(json['ingredients']),
      ingredientAisles: nullableStrings(json['ingredientAisles']),
      prepTime: integer(json['prepTime']),
      cookTime: integer(json['cookTime']),
      totalTime: integer(json['totalTime']),
      servings: integer(json['servings']),
      calories: integer(json['calories']),
      fats: integer(json['fats']),
      cholesterol: integer(json['cholesterol']),
      sodium: integer(json['sodium']),
      carbohydrates: integer(json['carbohydrates']),
      protein: integer(json['protein']),
      dishTypes: strings(json['dishTypes']),
    );
  }
}
