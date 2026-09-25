import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RecipeApiException implements Exception {
  final String message;

  const RecipeApiException(this.message);

  @override
  String toString() => message;
}

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
  final List<String> diets;
  final List<String> occasions;
  final bool vegetarian;
  final bool vegan;
  final bool glutenFree;
  final bool dairyFree;
  final bool veryHealthy;
  final bool cheap;
  final String? creditsText;
  final int fiber;
  final int sugar;
  final int saturatedFat;

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
    this.creditsText,
    this.dishTypes = const [], this.diets = const [], this.occasions = const [],
    this.vegetarian = false, this.vegan = false, this.glutenFree = false,
    this.dairyFree = false, this.veryHealthy = false, this.cheap = false,
    this.fiber = 0, this.sugar = 0, this.saturatedFat = 0,
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
    final tags = stringList(recipe['tags']);
    return ApiRecipe(
      id: 'dummy:${recipe['id'] ?? ''}',
      title: '${recipe['name'] ?? 'Untitled recipe'}',
      category: categories.isNotEmpty ? categories.first : (tags.isNotEmpty ? tags.first : 'Recipe'),
      description: '',
      difficulty: optionalString(recipe['difficulty']),
      cuisine: optionalString(recipe['cuisine']),
      tags: tags,
      imageUrl: '${recipe['image'] ?? ''}',
      instructions: stringList(recipe['instructions']),
      ingredients: stringList(recipe['ingredients']),
      prepTime: number(recipe['prepTimeMinutes']),
      cookTime: number(recipe['cookTimeMinutes']),
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
    final ingredients = extended is List
        ? extended.whereType<Map>().map((item) {
            final original = text(item['original']).isNotEmpty
                ? text(item['original'])
                : text(item['originalString']);
            if (original.isNotEmpty) return original;
            return [text(item['amount']), text(item['unit']), text(item['name'])]
                .where((part) => part.isNotEmpty)
                .join(' ');
          }).where((item) => item.isNotEmpty).toList()
        : const <String>[];
    final cuisines = recipe['cuisines'] is List
        ? (recipe['cuisines'] as List).whereType<String>().toList()
        : const <String>[];
    final dishTypes = stringList(recipe['dishTypes']);
    final diets = stringList(recipe['diets']);
    final occasions = stringList(recipe['occasions']);
    final prepTime = number(recipe['preparationMinutes']);
    final cookTime = number(recipe['cookingMinutes']);
    final totalTime = number(recipe['readyInMinutes']);
    return ApiRecipe(
      id: 'spoonacular:$id', title: text(recipe['title']).isEmpty ? 'Untitled recipe' : text(recipe['title']),
      category: recipe['dishTypes'] is List && (recipe['dishTypes'] as List).isNotEmpty
          ? text((recipe['dishTypes'] as List).first) : 'Recipe',
      description: text(recipe['description']).replaceAll(RegExp(r'<[^>]*>'), ''),
      difficulty: null, cuisine: cuisines.isEmpty ? null : cuisines.first,
      tags: [...cuisines, ...diets, ...occasions,
        if (recipe['vegetarian'] == true && !diets.contains('vegetarian')) 'Vegetarian',
        if (recipe['vegan'] == true && !diets.contains('vegan')) 'Vegan'],
      imageUrl: text(recipe['image']), instructions: instructions, ingredients: ingredients,
      prepTime: prepTime, cookTime: cookTime,
      totalTime: totalTime > 0 ? totalTime : prepTime + cookTime,
      servings: number(recipe['servings']) == 0 ? 1 : number(recipe['servings']),
      calories: nutrient('Calories'), fats: nutrient('Fat'), cholesterol: nutrient('Cholesterol'),
      sodium: nutrient('Sodium'), carbohydrates: nutrient('Carbohydrates'), protein: nutrient('Protein'),
      dishTypes: dishTypes, diets: diets, occasions: occasions,
      vegetarian: recipe['vegetarian'] == true, vegan: recipe['vegan'] == true,
      glutenFree: recipe['glutenFree'] == true, dairyFree: recipe['dairyFree'] == true,
      veryHealthy: recipe['veryHealthy'] == true, cheap: recipe['cheap'] == true,
      creditsText: text(recipe['creditsText']).isEmpty ? null : text(recipe['creditsText']),
      fiber: nutrient('Fiber'), sugar: nutrient('Sugar'), saturatedFat: nutrient('Saturated Fat'),
    );
  }
}

class RecipeApi {
  RecipeApi({http.Client? client}) : _client = client ?? http.Client();

  static String _supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String _supabasePublishableKey =
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static Future<void> loadConfig() async {
    try {
      final config = jsonDecode(
        await rootBundle.loadString('assets/config/supabase.json'),
      );
      if (config is Map<String, dynamic>) {
        final url = config['SUPABASE_URL'];
        final publishableKey = config['SUPABASE_PUBLISHABLE_KEY'];
        if (url is String && url.trim().isNotEmpty) {
          _supabaseUrl = url.trim();
        }
        if (publishableKey is String && publishableKey.trim().isNotEmpty) {
          _supabasePublishableKey = publishableKey.trim();
        }
      }
    } on FlutterError {
      // The runtime config is optional when build-time defines are supplied.
    } on FormatException {
      // Keep build-time values if the local config file is invalid.
    }
  }

  final http.Client _client;

  Future<String?> imageFor(String recipeTitle, {String? imageUrl}) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final uri = Uri.tryParse(imageUrl.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri.toString()
        : null;
  }

  Future<List<ApiRecipe>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length > 100) {
      throw const RecipeApiException('Search must be 100 characters or fewer.');
    }
    _checkSupabaseConfig();
    final response = await _invokeSpoonacular({'action': 'search', 'query': trimmedQuery});
    final recipes = response['results'];
    if (recipes is! List) throw const RecipeApiException('Spoonacular returned invalid data.');
    return recipes.whereType<Map<String, dynamic>>().map(ApiRecipe.fromSpoonacularJson).toList();
  }

  Future<ApiRecipe> getById(String id) async {
    final sourceId = id.startsWith('spoonacular:') ? id.substring('spoonacular:'.length) : id;
    if (sourceId.isEmpty || sourceId.length > 64 || !RegExp(r'^\d+$').hasMatch(sourceId)) {
      throw const RecipeApiException('Invalid recipe id.');
    }
    _checkSupabaseConfig();
    final response = await _invokeSpoonacular({'action': 'information', 'id': sourceId});
    return ApiRecipe.fromSpoonacularJson(response);
  }

  void _checkSupabaseConfig() {
    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
      throw const RecipeApiException('Recipe search is not configured. Add the Supabase URL and publishable key to the app build settings.');
    }
  }

  Future<Map<String, dynamic>> _invokeSpoonacular(Map<String, Object> payload) =>
      _post(Uri.parse('$_supabaseUrl/functions/v1/spoonacular'), payload);

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, Object> payload) async {
    late final http.Response response;
    try {
      response = await _client.post(uri,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'apikey': _supabasePublishableKey},
        body: jsonEncode(payload));
    } on Exception {
      throw const RecipeApiException('Could not reach the recipe service. Check your connection.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RecipeApiException('Recipe service request failed (HTTP ${response.statusCode}).');
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
    } on FormatException {}
    throw const RecipeApiException('Recipe service returned invalid data.');
  }

  void close() => _client.close();
}
