import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/recipes.dart';
import 'package:asan/models/grocery_item.dart';

import 'package:asan/services/api/recipe_api.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/selections.dart';
import 'package:asan/screens/recipe_details_screen.dart';

class _SearchCardOption {
  final String title;
  final IconData icon;
  final Color? color;

  const _SearchCardOption({required this.title, required this.icon, this.color});
}

const _mealTimeSearchCards = <_SearchCardOption>[
  _SearchCardOption(title: 'Breakfast', icon: Symbols.breakfast_dining_rounded, color: AsanColorScheme.yellow),
  _SearchCardOption(title: 'Brunch', icon: Symbols.brunch_dining_rounded, color: AsanColorScheme.orange),
  _SearchCardOption(title: 'Lunch', icon: Symbols.lunch_dining_rounded, color: AsanColorScheme.blue),
  _SearchCardOption(title: 'Snack', icon: Symbols.cookie_rounded, color: AsanColorScheme.pink),
  _SearchCardOption(title: 'Dinner', icon: Symbols.dinner_dining_rounded, color: AsanColorScheme.purple),
];

const _dishTypeSearchCards = <_SearchCardOption>[
  _SearchCardOption(title: 'Main Course', icon: Symbols.room_service_rounded),
  _SearchCardOption(title: 'Side Dish', icon: Symbols.washoku_rounded),
  _SearchCardOption(title: 'Dessert', icon: Symbols.cake_rounded),
  _SearchCardOption(title: 'Appetizer', icon: Symbols.tapas_rounded),
  _SearchCardOption(title: 'Salad', icon: Symbols.eco_rounded),
  _SearchCardOption(title: 'Bread', icon: Symbols.bakery_dining_rounded),
  _SearchCardOption(title: 'Soup', icon: Symbols.soup_kitchen_rounded),
  _SearchCardOption(title: 'Beverage', icon: Symbols.emoji_food_beverage_rounded),
  _SearchCardOption(title: 'Sauce', icon: Symbols.water_drop_rounded),
  _SearchCardOption(title: 'Marinade', icon: Symbols.kitchen_rounded),
  _SearchCardOption(title: 'Fingerfood', icon: Symbols.kebab_dining_rounded),
  _SearchCardOption(title: 'Snack', icon: Symbols.cookie_rounded),
  _SearchCardOption(title: 'Drink', icon: Symbols.water_full_rounded),
];

class SearchScreen extends StatefulWidget {
  final AsanFilterSelection? initialFilters;
  final Future<void> Function(List<GroceryItem>)? onAddToGroceries;
  final VoidCallback? onViewGroceries;
  final ValueChanged<Recipes>? onAddToMealPlan;
  final ValueChanged<Recipes>? onRecipeSelected;
  final bool Function(String title)? isRecipeSaved;
  final ValueChanged<String>? onToggleSaved;

  const SearchScreen({
    super.key,
    this.initialFilters,
    this.onAddToGroceries,
    this.onViewGroceries,
    this.onAddToMealPlan,
    this.onRecipeSelected,
    this.isRecipeSaved,
    this.onToggleSaved,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final RecipeApi _recipeApi = RecipeApi();
  Timer? _debounce;
  String _query = '';
  int _request = 0;
  List<ApiRecipe> _recipes = const [];
  bool _loading = false;
  String? _error;
  int? _httpStatusCode;
  late AsanFilterSelection? _filters = widget.initialFilters;
  bool _showResults = false;

  List<String> get _activeFilterLabels => [
    ...?_filters?.totalTimeRanges,
    ...?_filters?.mealTimes,
    ...?_filters?.mealTimeCategories,
    ...?_filters?.mealCategories,
    ...?_filters?.cuisines,
  ];

  @override
  void initState() {
    super.initState();
    _showResults = _activeFilterLabels.isNotEmpty;
    if (_showResults) _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _recipeApi.close();
    super.dispose();
  }

  Future<void> _search(String query, {String? type}) async {
    final request = ++_request;
    setState(() { _loading = true; _error = null; _httpStatusCode = null; });
    try {
      final recipes = await _recipeApi.search(query, type: type);
      if (!mounted || request != _request) return;
      setState(() { _recipes = recipes; _loading = false; });
    } on RecipeApiException catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error.message;
        _httpStatusCode = error.statusCode;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() { _error = 'Could not load recipes. Please try again.'; _loading = false; });
    }
  }

  Future<void> _showFilters() async {
    final selection = await showModalBottomSheet<AsanFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: filterSheetInitialSize(context, menuType: AsanFilterMenuType.recipes),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, controller) => AsanFilterList(
          scrollController: controller,
          menuType: AsanFilterMenuType.recipes,
          initialSelection: _filters,
        ),
      ),
    );
    if (selection != null && mounted) setState(() => _filters = selection);
  }

  List<ApiRecipe> get _filteredRecipes {
    final filters = _filters;
    if (filters == null) return _recipes;
    return _recipes.where((recipe) {
      // Spoonacular exposes meal times as dish types (for example,
      // "morning meal"), while user recipes and other providers may expose
      // them as tags. Check both so a successful search is not hidden here.
      String normalizeMealTime(String value) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'morning meal' ? 'breakfast' : normalized;
      }

      final time = recipe.totalTime > 0 ? recipe.totalTime : recipe.prepTime + recipe.cookTime;
      final timeMatch = filters.totalTimeRanges.isEmpty || filters.totalTimeRanges.contains(asanTotalTimeRangeFor(time));
      final dietMatch = filters.mealCategories.isEmpty || recipe.tags.any((tag) => filters.mealCategories.any((value) => value.toLowerCase() == tag.toLowerCase()));
      final recipeMealTimes = [...recipe.tags, ...recipe.dishTypes, recipe.category]
          .map(normalizeMealTime)
          .toSet();
      final mealMatch = filters.mealTimes.isEmpty || filters.mealTimes.any((value) => recipeMealTimes.contains(normalizeMealTime(value)));
      final types = [...recipe.dishTypes, recipe.category].map(normalizeMealTime);
      final typeMatch = filters.mealTimeCategories.isEmpty || types.any((type) => filters.mealTimeCategories.any((value) => normalizeMealTime(value) == type));
      final cuisineMatch = filters.cuisines.isEmpty || filters.cuisines.any((value) => (recipe.cuisine ?? '').toLowerCase().split(',').map((part) => part.trim()).contains(value.toLowerCase()));
      return timeMatch && dietMatch && mealMatch && typeMatch && cuisineMatch;
    }).toList();
  }

  Future<void> _openRecipeDetails(ApiRecipe recipe) async {
    ApiRecipe details;
    try {
      details = await _recipeApi.getById(recipe.id);
    } catch (_) {
      details = recipe;
    }
    if (!mounted) return;
    final imageUrl = await _recipeApi.imageFor(details.title, imageUrl: details.imageUrl);
    if (!mounted) return;
    final savedRecipe = Recipes(
      name: details.title,
      imageUrl: imageUrl,
      mealCategory: details.category,
      description: details.description,
      difficulty: details.difficulty,
      cuisine: details.cuisine,
      tags: details.tags,
      idealFor: details.tags,
      prepTime: details.prepTime,
      cookTime: details.cookTime,
      totalTime: details.totalTime > 0 ? details.totalTime : details.prepTime + details.cookTime,
      servings: details.servings,
      calories: details.calories,
      fats: details.fats,
      cholesterol: details.cholesterol,
      sodium: details.sodium,
      carbohydrates: details.carbohydrates,
      protein: details.protein,
      dishTypes: details.dishTypes,
      ingredients: details.ingredients,
      ingredientAisles: details.ingredientAisles,
      instructions: details.instructions,
    );
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute<void>(
      builder: (context) => RecipeDetailsScreen(
        recipe: savedRecipe,
        imageUrl: imageUrl,
        ingredients: details.ingredients,
        instructions: details.instructions,
        isSaved: widget.isRecipeSaved?.call(details.title) ?? false,
        onToggleSaved: widget.onToggleSaved == null
            ? null
            : () => widget.onToggleSaved!(details.title),
        onAddToGroceries: widget.onAddToGroceries == null
            ? null
            : (servings) async {
                final baseServings = details.servings > 0 ? details.servings : 1;
                await widget.onAddToGroceries!(List.generate(
                  details.ingredients.length,
                  (index) => _groceryItemFromIngredient(
                    details.ingredients[index],
                    index < details.ingredientAisles.length
                        ? details.ingredientAisles[index]
                        : null,
                    servings / baseServings,
                  ),
                ));
              },
        onViewGroceries: widget.onViewGroceries,
        onAddToMealPlan: widget.onAddToMealPlan == null && widget.onRecipeSelected == null
            ? null
            : () {
                Navigator.of(context).pop();
                if (widget.onRecipeSelected != null) {
                  Navigator.of(context).pop();
                  widget.onRecipeSelected!(savedRecipe);
                } else {
                  widget.onAddToMealPlan!(savedRecipe);
                }
              },
      ),
    ));
    if (mounted) _returnToInitial();
  }

  GroceryItem _groceryItemFromIngredient(String ingredient, String? aisle, double multiplier) {
    final match = RegExp(r'^(\d+(?:\s+\d+/\d+|[./]\d+)?)(?:\s+(cups?|tbsp|tablespoons?|tsp|teaspoons?|g|kg|mg|ml|l|oz|ounces?|lb|lbs|pounds?|cloves?|cans?|slices?|pieces?|pinches?))?\s+(.+)$', caseSensitive: false).firstMatch(ingredient.trim());
    if (match == null) {
      return GroceryItem(name: ingredient.trim(), amount: '', unit: '', aisle: aisle ?? 'Other', notes: '');
    }
    final rawAmount = match.group(1)!;
    final amount = double.tryParse(rawAmount) ?? 0;
    final rawUnit = match.group(2)?.toLowerCase();
    final unit = switch (rawUnit) {
      'cups' || 'cup' => 'cup',
      'tablespoons' || 'tablespoon' || 'tbsp' => 'tbsp',
      'teaspoons' || 'teaspoon' || 'tsp' => 'tsp',
      'ounces' || 'ounce' || 'oz' => 'oz',
      'pounds' || 'pound' || 'lbs' || 'lb' => 'lb',
      'pinches' => 'pinch',
      _ => rawUnit ?? '',
    };
    return GroceryItem(
      name: match.group(3)!.trim().replaceFirst(RegExp(r'^of\s+', caseSensitive: false), ''),
      amount: amount == 0 ? rawAmount : (amount * multiplier).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
      unit: unit,
      aisle: aisle ?? 'Other',
      notes: '',
    );
  }

  void _toggle(Set<String> values, String value, {required bool dishType}) {
    final updated = {...values};
    updated.contains(value) ? updated.remove(value) : updated.add(value);
    final current = _filters ?? const AsanFilterSelection(
      sortBy: 'Meal category', sortAscending: true, purchaseStatuses: {},
      expirationStatuses: {}, foodGroups: {},
    );
    final selection = current.copyWith(
      mealTimes: dishType ? current.mealTimes : updated,
      mealTimeCategories: dishType ? updated : current.mealTimeCategories,
    );
    final query = [...selection.mealTimes, ...selection.mealTimeCategories].join(' ');
    _debounce?.cancel();
    setState(() {
      _filters = selection;
      _query = query;
      _showResults = query.isNotEmpty || _activeFilterLabels.isNotEmpty;
      _recipes = const [];
      _error = null;
      _loading = query.isNotEmpty;
    });
    if (query.isEmpty) {
      ++_request;
    } else {
      final mealTimeType = selection.mealTimes.length == 1
          ? selection.mealTimes.first
          : null;
      _search(mealTimeType == null ? query : '', type: mealTimeType);
    }
  }

  void _removeFilter(String label) {
    final current = _filters;
    if (current == null) return;
    final selection = current.copyWith(
      mealTimes: {...current.mealTimes}..remove(label),
      mealTimeCategories: {...current.mealTimeCategories}..remove(label),
      totalTimeRanges: {...current.totalTimeRanges}..remove(label),
      mealCategories: {...current.mealCategories}..remove(label),
      cuisines: {...current.cuisines}..remove(label),
    );
    final query = [...selection.mealTimes, ...selection.mealTimeCategories].join(' ');
    _debounce?.cancel();
    setState(() {
      _filters = selection;
      _query = query;
      _showResults = query.isNotEmpty || _activeFilterLabels.isNotEmpty;
      _recipes = const [];
      _error = null;
      _loading = query.isNotEmpty;
    });
    if (query.isEmpty) {
      ++_request;
    } else {
      final mealTimeType = selection.mealTimes.length == 1
          ? selection.mealTimes.first
          : null;
      _search(mealTimeType == null ? query : '', type: mealTimeType);
    }
  }

  void _returnToInitial() {
    _debounce?.cancel();
    ++_request;
    setState(() {
      _query = '';
      _filters = null;
      _showResults = false;
      _recipes = const [];
      _error = null;
      _loading = false;
    });
  }

  Future<void> _handleBack() async {
    if (_query.trim().isNotEmpty) {
      _returnToInitial();
      return;
    }
    await Navigator.maybePop(context);
  }

  Widget _selectionSection(String title, List<_SearchCardOption> cards, Set<String> selected, {required bool dishType}) => Padding(
    padding: const EdgeInsets.only(bottom: AsanSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AsanSpacing.sm),
          child: Text(title, style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ),
        LayoutBuilder(builder: (context, constraints) => Wrap(
          spacing: AsanSpacing.sm,
          runSpacing: AsanSpacing.sm,
          children: cards.map((card) {
            final isSelected = selected.contains(card.title);
            return SizedBox(
              width: (constraints.maxWidth - AsanSpacing.sm) / 2,
              child: AsanSearchCard(
                title: card.title,
                icon: card.icon,
                color: card.color,
                isSelected: isSelected,
                onTap: () => _toggle(selected, card.title, dishType: dishType),
              ),
            );
          }).toList(),
        )),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final recipes = _filteredRecipes;
    return PopScope(
      canPop: _query.trim().isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _query.trim().isNotEmpty) _returnToInitial();
      },
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: AsanSpacing.md),
            child: SizedBox(
              width: 34,
              height: 34,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                icon: const Icon(Symbols.chevron_left_rounded, size: 34, weight: 600),
                onPressed: _handleBack,
              ),
            ),
          ),
        ),
        leadingWidth: AsanSpacing.md + 34,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: AsanSpacing.sm, right: AsanSpacing.sm),
          child: SizedBox(
            width: double.infinity,
            child: AsanSearchBar(
              hintText: 'Search recipes...',
              initialQuery: _query,
              onChanged: (value) {
                _debounce?.cancel();
                setState(() {
                  _query = value;
                  _showResults = value.trim().isNotEmpty || _activeFilterLabels.isNotEmpty;
                  if (value.trim().isEmpty) {
                    ++_request;
                    _recipes = const [];
                    _error = null;
                    _loading = false;
                  }
                });
                if (value.trim().isNotEmpty) {
                  _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
                }
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AsanSpacing.lg),
            child: FilledIconButton(
              icon: const Icon(Symbols.tune_rounded),
              isActive: _activeFilterLabels.isNotEmpty,
              badgeCount: _activeFilterLabels.length,
              onPressed: _showFilters,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            _activeFilterLabels.isEmpty
                ? AsanSpacing.md
                : AsanSpacing.sm + 40 + AsanSpacing.md,
          ),
          child: _activeFilterLabels.isEmpty
              ? const SizedBox(height: AsanSpacing.md)
              : Column(
                  children: [
                    const SizedBox(height: AsanSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AsanSpacing.lg,
                      ),
                      child: SizedBox(
                        height: 40,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                            },
                          ),
                          child: ListView.separated(
                            primary: false,
                            clipBehavior: Clip.none,
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _activeFilterLabels.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AsanSpacing.sm),
                            itemBuilder: (context, index) {
                              final label = _activeFilterLabels[index];
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: AsanFilterChip(
                                  label: label,
                                  isSelected: true,
                                  onPressed: () => _removeFilter(label),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AsanSpacing.md),
                  ],
                ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: !_showResults
          ? ListView(
              padding: const EdgeInsets.fromLTRB(AsanSpacing.lg, 0, AsanSpacing.lg, AsanSpacing.lg),
              children: [
                _selectionSection('Search by Meal Time', _mealTimeSearchCards, _filters?.mealTimes ?? const {}, dishType: false),
                _selectionSection('Search by Dish Type', _dishTypeSearchCards, _filters?.mealTimeCategories ?? const {}, dishType: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _error != null && _recipes.isEmpty
          ? AsanEmptyState(
              icon: Symbols.error_rounded,
              title: _httpStatusCode == null
                  ? 'Recipes could not be loaded'
                  : 'Error $_httpStatusCode',
              message: _error!,
              actionIcon: const Icon(Symbols.refresh_rounded, weight: 600),
              actionLabel: 'Try again',
              onAction: () => _search(_query),
            )
          : _loading && _recipes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : recipes.isEmpty
                  ? AsanEmptyState(
                      icon: Symbols.search_off_rounded,
                      title: _query.trim().isEmpty
                          ? 'No recipes match these filters'
                          : 'No recipes found',
                      message: _query.trim().isEmpty
                          ? 'Try removing a filter to see more recipes.'
                          : 'No recipes match "${_query.trim()}".',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(AsanSpacing.lg, 0, AsanSpacing.lg, AsanSpacing.lg),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AsanSpacing.md,
                        mainAxisSpacing: AsanSpacing.lg,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        final image = recipe.imageUrl;
                        return RecipeCard(
                          recipeName: recipe.title,
                          mealCategory: recipe.category,
                          imageUrl: image.isEmpty ? null : image,
                          totalTime: recipe.totalTime > 0 ? '${recipe.totalTime} min' : 'Open recipe',
                          showBookmark: false,
                          onTap: () => _openRecipeDetails(recipe),
                        );
                      },
                    )),
              ],
            ),
      ),
    );
  }
}
