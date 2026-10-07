import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';
import 'package:asan/models/recipes.dart';
import 'package:asan/models/grocery_item.dart';
import 'package:asan/models/filters.dart';
import 'package:asan/services/api/recipe_api.dart';

import 'package:asan/screens/recipe_form_screen.dart';
import 'package:asan/screens/recipe_details_screen.dart';
import 'package:asan/screens/search_screen.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

GroceryItem _groceryItemFromFormattedIngredient(
  String ingredient,
  String? aisle,
  double multiplier,
) {
  final match = RegExp(
    r'^(\d+(?:\s+\d+/\d+|[./]\d+)?)(?:\s+(cups?|tbsp|tablespoons?|tsp|teaspoons?|g|kg|mg|ml|l|oz|ounces?|lb|lbs|pounds?|cloves?|cans?|slices?|pieces?|pinch(?:es)?))?\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(ingredient.trim());
  if (match == null) {
    return GroceryItem(
      name: ingredient.trim(),
      amount: '',
      unit: '',
      aisle: aisle ?? 'Other',
      notes: '',
    );
  }

  final rawUnit = match.group(2);
  final name = match
      .group(3)!
      .trim()
      .replaceFirst(RegExp(r'^of\s+', caseSensitive: false), '');
  return GroceryItem(
    name: name,
    amount: _scaleIngredientAmount(match.group(1)!, multiplier),
    unit: rawUnit == null ? '' : _shortIngredientUnit(rawUnit),
    aisle: aisle ?? 'Other',
    notes: '',
  );
}

String _scaleIngredientAmount(String raw, double multiplier) {
  final parts = raw.trim().split(RegExp(r'\s+'));
  var amount = 0.0;
  for (final part in parts) {
    if (part.contains('/')) {
      final fraction = part.split('/');
      if (fraction.length == 2) {
        amount +=
            (double.tryParse(fraction[0]) ?? 0) /
            (double.tryParse(fraction[1]) ?? 1);
      }
    } else {
      amount += double.tryParse(part) ?? 0;
    }
  }
  final scaled = amount * multiplier;
  final whole = scaled.floor();
  final remainder = scaled - whole;
  if (remainder < 0.0001) return '$whole';

  const denominators = [2, 3, 4, 8, 16];
  var bestNumerator = 0;
  var bestDenominator = 1;
  var smallestDifference = double.infinity;
  for (final denominator in denominators) {
    final numerator = (remainder * denominator).round();
    final difference = (remainder - numerator / denominator).abs();
    if (difference < smallestDifference) {
      smallestDifference = difference;
      bestNumerator = numerator;
      bestDenominator = denominator;
    }
  }
  if (bestNumerator == bestDenominator) return '${whole + 1}';
  if (bestNumerator == 0) return '$whole';

  var numerator = bestNumerator;
  var denominator = bestDenominator;
  for (var divisor = denominator; divisor > 1; divisor--) {
    if (numerator % divisor == 0 && denominator % divisor == 0) {
      numerator ~/= divisor;
      denominator ~/= divisor;
    }
  }
  final fraction = '$numerator/$denominator';
  return whole == 0 ? fraction : '$whole $fraction';
}

String _shortIngredientUnit(String unit) {
  switch (unit.toLowerCase()) {
    case 'cup':
    case 'cups':
      return 'cup';
    case 'tablespoon':
    case 'tablespoons':
    case 'tbsp':
      return 'tbsp';
    case 'teaspoon':
    case 'teaspoons':
    case 'tsp':
      return 'tsp';
    case 'ounce':
    case 'ounces':
    case 'oz':
      return 'oz';
    case 'pound':
    case 'pounds':
    case 'lb':
    case 'lbs':
      return 'lb';
    case 'clove':
    case 'cloves':
      return 'cloves';
    case 'slice':
    case 'slices':
      return 'slices';
    case 'piece':
    case 'pieces':
      return 'pcs';
    case 'pinch':
    case 'pinches':
      return 'pinch';
    default:
      return unit;
  }
}

class RecipesScreen extends StatefulWidget {
  final Future<void> Function(List<GroceryItem>)? onAddToGroceries;
  final VoidCallback? onViewGroceries;
  final List<Recipes> incomingRecipes;
  final List<String> initialSavedRecipeTitles;
  final List<ApiRecipe> initialSavedRecipes;
  final ValueChanged<Set<ApiRecipe>>? onSavedRecipesChanged;
  final ValueChanged<List<Recipes>>? onRecipesChanged;
  final ValueChanged<Recipes>? onAddToMealPlan;
  final AsanFilterSelection? initialFilters;
  final String initialQuery;
  final ValueChanged<Recipes>? onRecipeSelected;
  final VoidCallback? onPickerBack;

  const RecipesScreen({
    super.key,
    this.incomingRecipes = const [],
    this.initialSavedRecipeTitles = const [],
    this.initialSavedRecipes = const [],
    this.onSavedRecipesChanged,
    this.onRecipesChanged,
    this.onAddToMealPlan,
    this.initialFilters,
    this.initialQuery = '',
    this.onRecipeSelected,
    this.onPickerBack,
    this.onAddToGroceries,
    this.onViewGroceries,
  });

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  _RecipesScreenState();
  final List<Recipes> _items = [];
  final RecipeApi _recipeApi = RecipeApi();
  final Map<String, String?> _recipeImages = {};
  final Set<String> _pendingRecipeImages = {};
  List<ApiRecipe> _exploreRecipes = const [];
  bool _isLoadingExplore = true;
  String? _exploreError;
  int? _exploreHttpStatusCode;
  int _exploreRequest = 0;
  Timer? _searchDebounce;
  String _searchQuery = '';
  AsanFilterSelection? _activeFilters;
  int _selectedView = 0;
  late final ScrollController _contentScrollController;
  late final ScrollController _filterScrollController;
  bool _isContentScrolled = false;
  int _receivedItemCount = 0;
  final Set<String> _savedRecipeTitles = {};
  final Map<String, ApiRecipe> _savedRecipes = {};
  String? _exploreCategory;
  String? _savedCategory;

  static const _views = ['Explore', 'Saved', 'My Recipes'];
  @override
  void initState() {
    super.initState();
    _contentScrollController = ScrollController()
      ..addListener(_handleContentScroll);
    _filterScrollController = ScrollController();
    _items.addAll(widget.incomingRecipes);
    _receivedItemCount = widget.incomingRecipes.length;
    _savedRecipeTitles.addAll(widget.initialSavedRecipeTitles);
    for (final recipe in widget.initialSavedRecipes) {
      _savedRecipeTitles.add(recipe.title);
      _savedRecipes[recipe.title] = recipe;
    }
    _activeFilters = widget.initialFilters;
    _searchQuery = widget.initialQuery;
    _loadExploreRecipes(_searchQuery);
  }

  @override
  void didUpdateWidget(covariant RecipesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.incomingRecipes.length > _receivedItemCount) {
      _items.addAll(widget.incomingRecipes.skip(_receivedItemCount));
      _receivedItemCount = widget.incomingRecipes.length;
      widget.onRecipesChanged?.call(List.unmodifiable(_items));
      setState(() {});
    }
  }

  @override
  void dispose() {
    _contentScrollController
      ..removeListener(_handleContentScroll)
      ..dispose();
    _filterScrollController.dispose();
    _searchDebounce?.cancel();
    _recipeApi.close();
    super.dispose();
  }

  void _handleContentScroll() {
    final isScrolled = _contentScrollController.offset > 0;
    if (isScrolled != _isContentScrolled) {
      setState(() => _isContentScrolled = isScrolled);
    }
  }

  String _cardDishType(Iterable<String> values, {String? fallback}) {
    final dishType = values
        .map((value) => value.trim())
        .firstWhere(
          (value) =>
              value.isNotEmpty &&
              !asanMealTimes.any(
                (mealTime) => mealTime.toLowerCase() == value.toLowerCase(),
              ),
          orElse: () => '',
        );
    return dishType.isNotEmpty ? dishType : (fallback ?? '');
  }

  List<String> get _activeFilterLabels => [
    ...?_activeFilters?.totalTimeRanges,
    ...?_activeFilters?.mealTimes,
    ...?_activeFilters?.mealTimeCategories,
    ...?_activeFilters?.mealCategories,
    ...?_activeFilters?.cuisines,
  ];

  Future<void> _showFilters() async {
    final selection = await showModalBottomSheet<AsanFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: filterSheetInitialSize(
          context,
          menuType: AsanFilterMenuType.recipes,
        ),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AsanFilterList(
          scrollController: scrollController,
          menuType: AsanFilterMenuType.recipes,
          initialSelection: _activeFilters,
        ),
      ),
    );
    if (selection != null && mounted) {
      setState(() => _activeFilters = selection);
    }
  }

  void _removeFilter(String label) {
    final filters = _activeFilters;
    if (filters == null) return;

    setState(() {
      _activeFilters = filters.copyWith(
        totalTimeRanges: {...filters.totalTimeRanges}..remove(label),
        mealTimes: {...filters.mealTimes}..remove(label),
        mealTimeCategories: {...filters.mealTimeCategories}..remove(label),
        mealCategories: {...filters.mealCategories}..remove(label),
        cuisines: {...filters.cuisines}..remove(label),
      );
    });
  }

  void _openExploreCategoryInSearch(String category) {
    final filters = _activeFilters;
    final totalTimeRanges = {...?filters?.totalTimeRanges};
    final mealTimeCategories = {...?filters?.mealTimeCategories};
    final mealCategories = {...?filters?.mealCategories};

    switch (category) {
      case 'Quick Meals':
        totalTimeRanges
          ..add('15 minutes or less')
          ..add('30 minutes or less');
        break;
      case 'Vegetarian':
        mealCategories.add('Vegetarian');
        break;
      case 'Sweet Treats':
        mealTimeCategories.add('Dessert');
        break;
      case 'Comfort Food':
        mealTimeCategories.add('Main Course');
        break;
    }

    final categoryFilters =
        (filters ??
                const AsanFilterSelection(
                  sortBy: 'Dish type',
                  sortAscending: true,
                  purchaseStatuses: {},
                  expirationStatuses: {},
                  foodGroups: {},
                ))
            .copyWith(
              totalTimeRanges: totalTimeRanges,
              mealTimeCategories: mealTimeCategories,
              mealCategories: mealCategories,
            );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          initialFilters: categoryFilters,
          onAddToGroceries: widget.onAddToGroceries,
          onViewGroceries: widget.onViewGroceries,
          onAddToMealPlan: widget.onAddToMealPlan,
          onRecipeSelected: widget.onRecipeSelected,
          isRecipeSaved: (title) => _savedRecipeTitles.contains(title),
          onToggleSaved: _toggleSavedRecipe,
        ),
      ),
    );
  }

  Future<void> _showAddRecipeDialog(BuildContext context) async {
    final item = await showDialog<Recipes>(
      context: context,
      useSafeArea: false,
      builder: (context) => const RecipeFormScreen(),
    );
    if (item != null && mounted) {
      setState(() => _items.add(item));
      _receivedItemCount = _items.length;
      widget.onRecipesChanged?.call(List.unmodifiable(_items));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: widget.onRecipeSelected != null
          ? null
          : AsanAppBar(
              backgroundColor: AsanColorScheme.primary,
              screenTitle: 'Recipes',
              icon: const Icon(Symbols.add_rounded),
              onIconPressed: () {
                _showAddRecipeDialog(context);
              },
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(
                  38 +
                      AsanSpacing.sm +
                      (_activeFilterLabels.isEmpty ? 0 : 40 + AsanSpacing.md) +
                      AsanSpacing.lg,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AsanSpacing.sm,
                    bottom: AsanSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SearchScreen(
                                    initialFilters: _activeFilters,
                                    onAddToGroceries: widget.onAddToGroceries,
                                    onViewGroceries: widget.onViewGroceries,
                                    onAddToMealPlan: widget.onAddToMealPlan,
                                    onRecipeSelected: widget.onRecipeSelected,
                                    isRecipeSaved: (title) =>
                                        _savedRecipeTitles.contains(title),
                                    onToggleSaved: _toggleSavedRecipe,
                                  ),
                                ),
                              ),
                              child: AbsorbPointer(
                                child: AsanSearchBar(
                                  hintText: 'Search recipes...',
                                  initialQuery: _searchQuery,
                                  onChanged: (query) {
                                    setState(() => _searchQuery = query);
                                    if (_selectedView < 2) {
                                      _searchDebounce?.cancel();
                                      _searchDebounce = Timer(
                                        const Duration(milliseconds: 350),
                                        () => _loadExploreRecipes(query),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AsanSpacing.sm),
                          FilledIconButton(
                            icon: const Icon(Symbols.tune_rounded),
                            isActive: _activeFilterLabels.isNotEmpty,
                            badgeCount: _activeFilterLabels.length,
                            onPressed: _showFilters,
                          ),
                        ],
                      ),
                      if (_activeFilterLabels.isNotEmpty) ...[
                        const SizedBox(height: AsanSpacing.md),
                        SizedBox(
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
                              controller: _filterScrollController,
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
                      ],
                    ],
                  ),
                ),
              ),
            ),
      body: SafeArea(
        top: widget.onRecipeSelected != null,
        child: CustomScrollView(
          controller: _contentScrollController,
          slivers: [
            if (widget.onRecipeSelected != null)
              SliverPersistentHeader(
                pinned: true,
                delegate: _RecipePickerSearchHeaderDelegate(
                  filterCount: _activeFilterLabels.length,
                  labels: _activeFilterLabels,
                  onBack:
                      widget.onPickerBack ??
                      () => Navigator.of(context).maybePop(),
                  onFilter: _showFilters,
                  onRemoveFilter: _removeFilter,
                  searchBar: _buildSearchBar(context),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SegmentedButtonHeaderDelegate(
                selectedIndex: _selectedView,
                views: _views,
                onChanged: (index) {
                  final shouldReloadExplore = _selectedView >= 2 && index < 2;
                  setState(() {
                    _selectedView = index;
                    if (shouldReloadExplore) _exploreCategory = null;
                    if (index != 1) _savedCategory = null;
                  });
                  if (shouldReloadExplore) {
                    _searchDebounce?.cancel();
                    _loadExploreRecipes(_searchQuery);
                  }
                },
              ),
            ),
            ..._buildSelectedView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SearchScreen(
            initialFilters: _activeFilters,
            onAddToGroceries: widget.onAddToGroceries,
            onViewGroceries: widget.onViewGroceries,
            onAddToMealPlan: widget.onAddToMealPlan,
            onRecipeSelected: widget.onRecipeSelected,
            isRecipeSaved: (title) => _savedRecipeTitles.contains(title),
            onToggleSaved: _toggleSavedRecipe,
          ),
        ),
      ),
      child: AbsorbPointer(
        child: AsanSearchBar(
          hintText: 'Search recipes...',
          initialQuery: _searchQuery,
          onChanged: (query) {
            setState(() => _searchQuery = query);
            if (_selectedView < 2) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 350),
                () => _loadExploreRecipes(query),
              );
            }
          },
        ),
      ),
    ),
  );

  List<Widget> _buildSelectedView() {
    if (_selectedView < 2) {
      final recipes = _selectedView == 0
          ? _filteredExploreRecipes
          : _savedRecipes.values.toList();
      return [_buildExploreView(recipes)];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        sliver:
            _items.isEmpty &&
                (_searchQuery.trim().isNotEmpty ||
                    _activeFilterLabels.isNotEmpty)
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: AsanEmptyState(
                  icon: Symbols.search_off_rounded,
                  title: _searchQuery.trim().isNotEmpty
                      ? 'No recipes found'
                      : 'No recipes match these filters',
                  message: _searchQuery.trim().isNotEmpty
                      ? 'No recipes match "${_searchQuery.trim()}".'
                      : 'Try removing or changing a filter.',
                ),
              )
            : _items.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: AsanEmptyState(
                  icon: Symbols.edit_document_rounded,
                  title: 'No created recipes yet',
                  message: 'When you add recipes, they will show up here.',
                  actionLabel: 'Add Recipe',
                  onAction: () => _showAddRecipeDialog(context),
                ),
              )
            : _groupedRecipesFlat.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: AsanEmptyState(
                  icon: Symbols.search_off_rounded,
                  title: _searchQuery.trim().isNotEmpty
                      ? 'No recipes found'
                      : 'No recipes match these filters',
                  message: _searchQuery.trim().isNotEmpty
                      ? 'No recipes match "${_searchQuery.trim()}".'
                      : 'Try removing or changing a filter.',
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = _groupedItems[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _groupedItems.length - 1
                          ? 0
                          : AsanSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AsanSpacing.md,
                          ),
                          child: Text(
                            _capitalizeCategory(group.key),
                            style: AsanTextTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width =
                                (constraints.maxWidth - AsanSpacing.md) / 2;
                            return Wrap(
                              spacing: AsanSpacing.md,
                              runSpacing: AsanSpacing.sm,
                              children: group.value.map((recipe) {
                                return SizedBox(
                                  width: width,
                                  height:
                                      width *
                                      (widget.onRecipeSelected == null
                                          ? 218
                                          : 246) /
                                      163,
                                  child: RecipeCard(
                                    recipeName: recipe.name,
                                    mealCategory: _cardDishType([
                                      recipe.mealCategory ?? '',
                                      ...recipe.dishTypes,
                                    ], fallback: '-'),
                                    imageBytes: recipe.imageBytes,
                                    totalTime: recipe.formattedTotalTime,
                                    showBookmark: false,
                                    onViewPressed:
                                        widget.onRecipeSelected != null
                                        ? () => _showRecipeDetails(recipe)
                                        : null,
                                    onTap: () => widget.onRecipeSelected != null
                                        ? widget.onRecipeSelected!(recipe)
                                        : _showRecipeDetails(recipe),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }, childCount: _groupedItems.length),
              ),
      ),
    ];
  }

  Widget _buildExploreView(List<ApiRecipe> recipes) {
    if (_isLoadingExplore && _exploreRecipes.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.zero,
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_exploreError != null && _exploreRecipes.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: AsanEmptyState(
            icon: Symbols.error_rounded,
            title: _exploreHttpStatusCode == null
                ? 'Recipes could not be loaded'
                : 'Error ${_exploreHttpStatusCode!}',
            message: _exploreHttpStatusCode == null
                ? _exploreError!
                : _exploreError!,
            actionIcon: const Icon(Symbols.refresh_rounded, weight: 600),
            actionLabel: 'Try again',
            onAction: () => _loadExploreRecipes(_searchQuery),
          ),
        ),
      );
    }
    if (recipes.isEmpty) {
      if (_selectedView == 1) {
        final hasSearchOrFilters =
            _searchQuery.trim().isNotEmpty || _activeFilterLabels.isNotEmpty;
        return SliverPadding(
          padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: AsanEmptyState(
              icon: hasSearchOrFilters
                  ? Symbols.search_off_rounded
                  : Symbols.bookmark_rounded,
              title: hasSearchOrFilters
                  ? (_searchQuery.trim().isNotEmpty
                        ? 'No recipes found'
                        : 'No recipes match these filters')
                  : 'No saved recipes yet',
              message: hasSearchOrFilters
                  ? (_searchQuery.trim().isNotEmpty
                        ? 'No recipes match "${_searchQuery.trim()}".'
                        : 'Try removing or changing a filter.')
                  : 'When you save recipes, they will show up here.',
              actionLabel: hasSearchOrFilters ? null : 'Save Recipes',
              onAction: hasSearchOrFilters
                  ? null
                  : () => setState(() => _selectedView = 0),
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: AsanEmptyState(
            icon:
                _searchQuery.trim().isNotEmpty || _activeFilterLabels.isNotEmpty
                ? Symbols.search_off_rounded
                : Symbols.restaurant_menu_rounded,
            title: _searchQuery.trim().isNotEmpty
                ? 'No recipes found'
                : _activeFilterLabels.isNotEmpty
                ? 'No recipes match these filters'
                : 'No recipes to explore yet',
            message: _searchQuery.trim().isNotEmpty
                ? 'No recipes match "${_searchQuery.trim()}".'
                : _activeFilterLabels.isNotEmpty
                ? 'Try adjusting your filters.'
                : 'Recipes will appear here when they are available.',
          ),
        ),
      );
    }

    if (_selectedView == 1) return _buildSavedRecipesView(recipes);

    final groups = <String, List<ApiRecipe>>{
      'Quick Meals': recipes.where((recipe) {
        final minutes = recipe.totalTime > 0
            ? recipe.totalTime
            : recipe.prepTime + recipe.cookTime;
        return minutes > 0 && minutes <= 30;
      }).toList(),
      'Vegetarian': recipes
          .where(
            (recipe) => recipe.tags.any(
              (tag) => const {
                'vegetarian',
                'vegan',
                'lacto-vegetarian',
                'ovo-vegetarian',
              }.contains(tag.toLowerCase()),
            ),
          )
          .toList(),
      'Sweet Treats': recipes
          .where(
            (recipe) => [...recipe.dishTypes, recipe.category].any(
              (type) => const {
                'dessert',
                'sweet',
              }.contains(type.trim().toLowerCase()),
            ),
          )
          .toList(),
      'Comfort Food': recipes.where((recipe) {
        final searchableText = [
          recipe.title,
          recipe.description,
          recipe.category,
          ...recipe.dishTypes,
          ...recipe.tags,
        ].join(' ').toLowerCase();
        return const [
          'comfort',
          'casserole',
          'mac and cheese',
          'macaroni',
          'mashed potato',
          'meatloaf',
          'pot pie',
          'chicken pot pie',
          'stew',
          'chili',
          'lasagna',
          'baked pasta',
          'grilled cheese',
          'shepherd',
          'fried chicken',
          'soup',
        ].any(searchableText.contains);
      }).toList(),
    };
    groups.removeWhere((_, items) => items.isEmpty);
    final categories = groups.keys.toList();

    if (_exploreCategory != null && groups.containsKey(_exploreCategory)) {
      final categoryRecipes = groups[_exploreCategory]!;
      return SliverPadding(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AsanSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _capitalizeCategory(_exploreCategory!),
                        style: AsanTextTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AsanTextButton(
                      label: 'All Recipes',
                      onPressed: () => setState(() => _exploreCategory = null),
                    ),
                  ],
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildExploreRecipeCard(categoryRecipes[index]),
                childCount: categoryRecipes.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AsanSpacing.md,
                mainAxisSpacing: AsanSpacing.sm,
                childAspectRatio:
                    163 / (widget.onRecipeSelected != null ? 246 : 218),
              ),
            ),
          ],
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final category = categories[index];
            final categoryRecipes = groups[category]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: AsanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AsanSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _capitalizeCategory(category),
                            style: AsanTextTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AsanTextButton(
                          label: 'View all',
                          onPressed: () =>
                              _openExploreCategoryInSearch(category),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AsanSpacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth =
                          (constraints.maxWidth -
                              (AsanSpacing.lg * 2) -
                              AsanSpacing.md) /
                          2;
                      return SizedBox(
                        height:
                            cardWidth +
                            (widget.onRecipeSelected != null ? 80 : 52),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                            },
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AsanSpacing.lg,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: categoryRecipes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AsanSpacing.md),
                            itemBuilder: (context, recipeIndex) => SizedBox(
                              width: cardWidth,
                              child: _buildExploreRecipeCard(
                                categoryRecipes[recipeIndex],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }, childCount: categories.length),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AsanSpacing.lg,
            0,
            AsanSpacing.lg,
            AsanSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Discover Recipes',
                    style: AsanTextTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AsanSpacing.lg,
            0,
            AsanSpacing.lg,
            AsanSpacing.lg,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildExploreRecipeCard(recipes[index]),
              childCount: recipes.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AsanSpacing.md,
              mainAxisSpacing: AsanSpacing.md,
              childAspectRatio:
                  163 / (widget.onRecipeSelected != null ? 246 : 218),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedRecipesView(List<ApiRecipe> recipes) {
    final sortBy = _activeFilters?.sortBy ?? 'Dish type';
    final ascending = _activeFilters?.sortAscending ?? true;

    String dishType(ApiRecipe recipe) {
      final type = recipe.dishTypes
          .map((type) => type.trim())
          .firstWhere(
            (type) => type.isNotEmpty,
            orElse: () => recipe.category.trim().isEmpty
                ? 'Unknown dish type'
                : recipe.category.trim(),
          );
      return type.isEmpty
          ? type
          : '${type[0].toUpperCase()}${type.substring(1).toLowerCase()}';
    }

    String cuisine(ApiRecipe recipe) {
      final storedCuisine = recipe.cuisine?.trim();
      if (storedCuisine?.isNotEmpty == true) return storedCuisine!;
      return asanCuisines.firstWhere(
        (value) => recipe.tags.any(
          (tag) => tag.trim().toLowerCase() == value.toLowerCase(),
        ),
        orElse: () => 'Unknown cuisine',
      );
    }

    String diet(ApiRecipe recipe) => asanDiets.firstWhere(
      (value) => recipe.tags.any(
        (tag) => tag.trim().toLowerCase() == value.toLowerCase(),
      ),
      orElse: () => 'Unknown diet',
    );

    int totalTime(ApiRecipe recipe) => recipe.totalTime > 0
        ? recipe.totalTime
        : recipe.prepTime + recipe.cookTime;

    String groupLabel(ApiRecipe recipe) => switch (sortBy) {
      'Dish type' => dishType(recipe),
      'Cuisine' => cuisine(recipe),
      'Diet' => diet(recipe),
      'Recipe name' =>
        recipe.title.trim().isEmpty
            ? '#'
            : recipe.title.trim()[0].toUpperCase(),
      'Total time' =>
        totalTime(recipe) <= 0
            ? 'Unknown time'
            : asanTotalTimeRangeFor(totalTime(recipe)) ?? 'Unknown time',
      _ => dishType(recipe),
    };

    int compare(ApiRecipe first, ApiRecipe second) {
      final result = switch (sortBy) {
        'Dish type' => dishType(
          first,
        ).toLowerCase().compareTo(dishType(second).toLowerCase()),
        'Cuisine' => cuisine(
          first,
        ).toLowerCase().compareTo(cuisine(second).toLowerCase()),
        'Diet' => diet(
          first,
        ).toLowerCase().compareTo(diet(second).toLowerCase()),
        'Recipe name' => first.title.toLowerCase().compareTo(
          second.title.toLowerCase(),
        ),
        'Total time' => totalTime(first).compareTo(totalTime(second)),
        _ => first.title.toLowerCase().compareTo(second.title.toLowerCase()),
      };
      return ascending ? result : -result;
    }

    final sortedRecipes = [...recipes]..sort(compare);
    final groups = <String, List<ApiRecipe>>{};
    for (final recipe in sortedRecipes) {
      (groups[groupLabel(recipe)] ??= []).add(recipe);
    }
    final entries = groups.entries.toList()
      ..sort((first, second) {
        final result = sortBy == 'Total time'
            ? (first.key == 'Unknown time'
                      ? 1 << 30
                      : asanTotalTimes.indexOf(first.key))
                  .compareTo(
                    second.key == 'Unknown time'
                        ? 1 << 30
                        : asanTotalTimes.indexOf(second.key),
                  )
            : first.key.toLowerCase().compareTo(second.key.toLowerCase());
        return ascending ? result : -result;
      });

    final selectedGroupIndex = _savedCategory == null
        ? -1
        : entries.indexWhere((entry) => entry.key == _savedCategory);
    if (selectedGroupIndex != -1) {
      final selectedGroup = entries[selectedGroupIndex];
      return SliverPadding(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AsanSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _capitalizeCategory(selectedGroup.key),
                        style: AsanTextTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AsanTextButton(
                      label: 'All Recipes',
                      onPressed: () => setState(() => _savedCategory = null),
                    ),
                  ],
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildExploreRecipeCard(selectedGroup.value[index]),
                childCount: selectedGroup.value.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AsanSpacing.md,
                mainAxisSpacing: AsanSpacing.md,
                childAspectRatio:
                    163 / (widget.onRecipeSelected != null ? 246 : 218),
              ),
            ),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: AsanSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final group = entries[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == entries.length - 1 ? 0 : AsanSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AsanSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _capitalizeCategory(group.key),
                          style: AsanTextTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AsanTextButton(
                        label: 'View all',
                        onPressed: () =>
                            setState(() => _savedCategory = group.key),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AsanSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width =
                        (constraints.maxWidth -
                            (AsanSpacing.lg * 2) -
                            AsanSpacing.md) /
                        2;
                    return SizedBox(
                      height:
                          width + (widget.onRecipeSelected != null ? 80 : 52),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AsanSpacing.lg,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: group.value.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AsanSpacing.md),
                          itemBuilder: (context, recipeIndex) => SizedBox(
                            width: width,
                            child: _buildExploreRecipeCard(
                              group.value[recipeIndex],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }, childCount: entries.length),
      ),
    );
  }

  Widget _buildExploreRecipeCard(ApiRecipe recipe) {
    _loadRecipeImage(recipe.title, recipe.imageUrl);
    final isSaved = _savedRecipeTitles.contains(recipe.title);
    final totalTime = recipe.totalTime > 0
        ? recipe.totalTime
        : recipe.prepTime + recipe.cookTime;
    return RecipeCard(
      recipeName: recipe.title,
      mealCategory: _cardDishType([
        recipe.category,
        ...recipe.dishTypes,
      ], fallback: 'Recipe'),
      imageUrl:
          _recipeImages[recipe.title] ??
          (recipe.imageUrl.isEmpty ? null : recipe.imageUrl),
      totalTime: totalTime > 0
          ? Recipes.formatTotalTime(totalTime)
          : 'Open recipe',
      isSaved: isSaved,
      onViewPressed: widget.onRecipeSelected != null
          ? () => _showExploreRecipeDetails(recipe)
          : null,
      onIconPressed: () => _toggleSavedRecipe(recipe.title, recipe),
      onTap: () => widget.onRecipeSelected != null
          ? widget.onRecipeSelected!(
              _apiRecipeToRecipe(
                recipe,
                _recipeImages[recipe.title] ?? recipe.imageUrl,
              ),
            )
          : _showExploreRecipeDetails(recipe),
    );
  }

  Recipes _apiRecipeToRecipe(ApiRecipe recipe, String? imageUrl) => Recipes(
    name: recipe.title,
    imageUrl: imageUrl,
    mealCategory: recipe.category,
    description: recipe.description,
    difficulty: recipe.difficulty,
    cuisine: recipe.cuisine,
    tags: recipe.tags,
    idealFor: recipe.tags.where(asanMealTimes.contains).toList(),
    prepTime: recipe.prepTime,
    cookTime: recipe.cookTime,
    totalTime: recipe.totalTime > 0
        ? recipe.totalTime
        : recipe.prepTime + recipe.cookTime,
    servings: recipe.servings,
    calories: recipe.calories,
    fats: recipe.fats,
    cholesterol: recipe.cholesterol,
    sodium: recipe.sodium,
    carbohydrates: recipe.carbohydrates,
    protein: recipe.protein,
    dishTypes: recipe.dishTypes,
    ingredients: recipe.ingredients,
    ingredientAisles: recipe.ingredientAisles,
    instructions: recipe.instructions,
  );

  List<ApiRecipe> get _filteredExploreRecipes {
    final filters = _activeFilters;
    return _exploreRecipes.where((recipe) {
      final time = recipe.totalTime > 0
          ? recipe.totalTime
          : recipe.prepTime + recipe.cookTime;
      final totalTimeMatch = filters?.totalTimeRanges.isEmpty ?? true
          ? true
          : filters!.totalTimeRanges.contains(asanTotalTimeRangeFor(time));
      final dietMatch = filters?.mealCategories.isEmpty ?? true
          ? true
          : recipe.tags.any(
              (tag) => filters!.mealCategories.any(
                (diet) => tag.toLowerCase() == diet.toLowerCase(),
              ),
            );
      final mealTimeMatch = filters?.mealTimes.isEmpty ?? true
          ? true
          : recipe.tags.any(
              (tag) => filters!.mealTimes.any(
                (mealTime) => tag.toLowerCase() == mealTime.toLowerCase(),
              ),
            );
      final dishTypes = [...recipe.dishTypes, recipe.category];
      final dishTypeMatch = filters?.mealTimeCategories.isEmpty ?? true
          ? true
          : dishTypes.any(
              (type) => filters!.mealTimeCategories.any(
                (selected) => type.toLowerCase() == selected.toLowerCase(),
              ),
            );
      final cuisineMatch = filters?.cuisines.isEmpty ?? true
          ? true
          : filters!.cuisines.any(
              (cuisine) => (recipe.cuisine ?? '')
                  .toLowerCase()
                  .split(',')
                  .map((part) => part.trim())
                  .contains(cuisine.toLowerCase()),
            );
      return totalTimeMatch &&
          dietMatch &&
          mealTimeMatch &&
          dishTypeMatch &&
          cuisineMatch;
    }).toList();
  }

  Future<void> _loadExploreRecipes([String query = '']) async {
    final request = ++_exploreRequest;
    if (mounted) {
      setState(() {
        _isLoadingExplore = true;
        _exploreError = null;
        _exploreHttpStatusCode = null;
      });
    }
    try {
      final recipes = await _recipeApi.search(query);
      if (!mounted || request != _exploreRequest) return;
      setState(() {
        _exploreRecipes = recipes;
        _isLoadingExplore = false;
      });
      for (final recipe in recipes) {
        _loadRecipeImage(recipe.title, recipe.imageUrl);
      }
    } catch (error) {
      if (!mounted || request != _exploreRequest) return;
      setState(() {
        _exploreError = error.toString();
        _exploreHttpStatusCode = error is RecipeApiException
            ? error.statusCode
            : null;
        _isLoadingExplore = false;
      });
    }
  }

  void _loadRecipeImage(String title, [String? imageUrl]) {
    if (_recipeImages.containsKey(title) || !_pendingRecipeImages.add(title))
      return;
    _recipeApi.imageFor(title, imageUrl: imageUrl).then((imageUrl) {
      _pendingRecipeImages.remove(title);
      if (!mounted) return;
      setState(() => _recipeImages[title] = imageUrl);
    });
  }

  List<MapEntry<String, List<Recipes>>> get _groupedItems {
    final query = _searchQuery.trim().toLowerCase();
    final filters = _activeFilters;
    final items = _items
        .where(
          (item) =>
              (query.isEmpty || item.name.toLowerCase().contains(query)) &&
              (filters?.totalTimeRanges.isEmpty ?? true
                  ? true
                  : filters!.totalTimeRanges.contains(
                      asanTotalTimeRangeFor(
                        item.totalTime > 0
                            ? item.totalTime
                            : item.prepTime + item.cookTime,
                      ),
                    )),
        )
        .where(
          (item) => filters?.mealCategories.isEmpty ?? true
              ? true
              : item.tags.any(
                  (tag) => filters!.mealCategories.any(
                    (diet) => tag.toLowerCase() == diet.toLowerCase(),
                  ),
                ),
        )
        .where(
          (item) => filters?.mealTimeCategories.isEmpty ?? true
              ? true
              : item.dishTypes.any(
                  (type) => filters!.mealTimeCategories.any(
                    (selected) => type.toLowerCase() == selected.toLowerCase(),
                  ),
                ),
        )
        .where(
          (item) => filters?.mealTimes.isEmpty ?? true
              ? true
              : [
                  ...item.idealFor,
                  ...item.tags.where(asanMealTimes.contains),
                ].any(
                  (mealTime) => filters!.mealTimes.any(
                    (selected) =>
                        mealTime.toLowerCase() == selected.toLowerCase(),
                  ),
                ),
        )
        .where(
          (item) => filters?.cuisines.isEmpty ?? true
              ? true
              : filters!.cuisines.any(
                  (cuisine) =>
                      (item.cuisine ?? '')
                          .toLowerCase()
                          .split(',')
                          .map((part) => part.trim())
                          .contains(cuisine.toLowerCase()) ||
                      item.tags.any(
                        (tag) =>
                            tag.trim().toLowerCase() == cuisine.toLowerCase(),
                      ),
                ),
        )
        .toList();
    final sortBy = filters?.sortBy ?? 'Meal category';
    int totalTime(Recipes recipe) => recipe.totalTime > 0
        ? recipe.totalTime
        : recipe.prepTime + recipe.cookTime;

    String firstDishType(Recipes recipe) {
      final type = recipe.dishTypes
          .map((type) => type.trim())
          .firstWhere(
            (type) => type.isNotEmpty,
            orElse: () => recipe.mealCategory?.trim().isNotEmpty == true
                ? recipe.mealCategory!.trim()
                : 'Uncategorized',
          );
      return type.isEmpty
          ? type
          : '${type[0].toUpperCase()}${type.substring(1).toLowerCase()}';
    }

    String cuisine(Recipes recipe) {
      final storedCuisine = recipe.cuisine?.trim();
      if (storedCuisine?.isNotEmpty == true) return storedCuisine!;
      return asanCuisines.firstWhere(
        (value) => recipe.tags.any(
          (tag) => tag.trim().toLowerCase() == value.toLowerCase(),
        ),
        orElse: () => 'Unknown cuisine',
      );
    }

    String diet(Recipes recipe) => asanDiets.firstWhere(
      (value) => recipe.tags.any(
        (tag) => tag.trim().toLowerCase() == value.toLowerCase(),
      ),
      orElse: () => 'Unknown diet',
    );

    String timeGroup(Recipes recipe) {
      final minutes = totalTime(recipe);
      return asanTotalTimeRangeFor(minutes) ?? 'Unknown time';
    }

    items.sort((first, second) {
      final result = switch (sortBy) {
        'Dish type' => firstDishType(
          first,
        ).toLowerCase().compareTo(firstDishType(second).toLowerCase()),
        'Cuisine' => cuisine(
          first,
        ).toLowerCase().compareTo(cuisine(second).toLowerCase()),
        'Diet' => diet(
          first,
        ).toLowerCase().compareTo(diet(second).toLowerCase()),
        'Meal category' =>
          (first.mealCategory ?? 'Uncategorized').toLowerCase().compareTo(
            (second.mealCategory ?? 'Uncategorized').toLowerCase(),
          ),
        'Recipe name' => first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        ),
        'Total time' => totalTime(first).compareTo(totalTime(second)),
        _ => first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      };
      return (filters?.sortAscending ?? true) ? result : -result;
    });

    final groups = <String, List<Recipes>>{};
    for (final item in items) {
      final label = switch (sortBy) {
        'Dish type' => firstDishType(item),
        'Cuisine' => cuisine(item),
        'Diet' => diet(item),
        'Meal category' => _capitalizeCategory(
          item.mealCategory ?? 'Uncategorized',
        ),
        'Total time' => timeGroup(item),
        'Recipe name' =>
          item.name.trim().isEmpty ? '#' : item.name.trim()[0].toUpperCase(),
        _ => item.mealCategory ?? 'Uncategorized',
      };
      (groups[label] ??= []).add(item);
    }
    final entries = groups.entries.toList();
    entries.sort((first, second) {
      if (sortBy == 'Total time') {
        int bucket(String label) =>
            label == 'Unknown time' ? 1 << 30 : asanTotalTimes.indexOf(label);
        final result = bucket(first.key).compareTo(bucket(second.key));
        return (filters?.sortAscending ?? true) ? result : -result;
      }
      final result = first.key.toLowerCase().compareTo(
        second.key.toLowerCase(),
      );
      return (filters?.sortAscending ?? true) ? result : -result;
    });
    return entries;
  }

  List<Recipes> get _groupedRecipesFlat =>
      _groupedItems.expand((entry) => entry.value).toList();

  Future<Recipes?> _showEditItemDialog(Recipes item) async {
    final updatedItem = await showDialog<Recipes>(
      context: context,
      useSafeArea: false,
      builder: (context) => RecipeFormScreen(
        initialItem: item,
        onDelete: () {
          setState(() => _items.remove(item));
          _receivedItemCount = _items.length;
          widget.onRecipesChanged?.call(List.unmodifiable(_items));
        },
      ),
    );
    if (updatedItem != null && mounted) {
      final index = _items.indexOf(item);
      if (index != -1) {
        setState(() => _items[index] = updatedItem);
        _receivedItemCount = _items.length;
        widget.onRecipesChanged?.call(List.unmodifiable(_items));
      }
    }
    return updatedItem;
  }

  void _showRecipeDetails(Recipes recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: recipe,
          headerVerticalPadding: widget.onRecipeSelected != null
              ? AsanSpacing.lg
              : AsanSpacing.sm,
          ingredients: recipe.ingredients,
          ingredientAmounts: recipe.ingredientAmounts,
          ingredientUnits: recipe.ingredientUnits,
          ingredientNotes: recipe.ingredientNotes,
          instructions: recipe.instructions,
          onAddToGroceries: (servings) async {
            final baseServings = recipe.servings > 0 ? recipe.servings : 1;
            await widget.onAddToGroceries?.call(
              List.generate(
                recipe.ingredients.length,
                (index) => GroceryItem(
                  name: recipe.ingredients[index],
                  amount: index < recipe.ingredientAmounts.length
                      ? _scaleIngredientAmount(
                          recipe.ingredientAmounts[index],
                          servings / baseServings,
                        )
                      : '',
                  unit: index < recipe.ingredientUnits.length
                      ? recipe.ingredientUnits[index]
                      : '',
                  aisle: index < recipe.ingredientAisles.length
                      ? recipe.ingredientAisles[index] ?? 'Other'
                      : 'Other',
                  notes: index < recipe.ingredientNotes.length
                      ? recipe.ingredientNotes[index]
                      : '',
                ),
              ),
            );
          },
          onViewGroceries: widget.onViewGroceries,
          onAddToMealPlan: () {
            if (widget.onRecipeSelected != null) {
              Navigator.of(context).pop();
              widget.onRecipeSelected!(recipe);
              return;
            }
            widget.onAddToMealPlan?.call(recipe);
          },
          showEditButton: true,
          onEdit: (currentRecipe) {
            return _showEditItemDialog(currentRecipe);
          },
        ),
      ),
    );
  }

  Future<void> _showExploreRecipeDetails(ApiRecipe recipe) async {
    final isSaved = _savedRecipeTitles.contains(recipe.title);
    ApiRecipe details;
    try {
      details = await _recipeApi.getById(recipe.id);
    } on RecipeApiException {
      details = recipe;
    } catch (_) {
      details = recipe;
    }
    if (!mounted) return;
    final imageUrl = await _recipeApi.imageFor(
      details.title,
      imageUrl: details.imageUrl,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: Recipes(
            name: details.title,
            imageUrl: imageUrl,
            mealCategory: details.category,
            description: details.description,
            difficulty: details.difficulty,
            cuisine: details.cuisine,
            tags: details.tags,
            idealFor: details.tags.where(asanMealTimes.contains).toList(),
            prepTime: details.prepTime,
            cookTime: details.cookTime,
            totalTime: details.totalTime > 0
                ? details.totalTime
                : details.prepTime + details.cookTime,
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
          ),
          imageUrl: imageUrl,
          ingredients: details.ingredients,
          onAddToGroceries: (servings) async {
            final baseServings = details.servings > 0 ? details.servings : 1;
            await widget.onAddToGroceries?.call(
              List.generate(
                details.ingredients.length,
                (index) => _groceryItemFromFormattedIngredient(
                  details.ingredients[index],
                  index < details.ingredientAisles.length
                      ? details.ingredientAisles[index]
                      : null,
                  servings / baseServings,
                ),
              ),
            );
          },
          onViewGroceries: widget.onViewGroceries,
          onAddToMealPlan: () {
            final selectedRecipe = _apiRecipeToRecipe(details, imageUrl);
            if (widget.onRecipeSelected != null) {
              Navigator.of(context).pop();
              widget.onRecipeSelected!(selectedRecipe);
              return;
            }
            widget.onAddToMealPlan?.call(selectedRecipe);
          },
          instructions: details.instructions,
          isSaved: isSaved,
          onToggleSaved: () => _toggleSavedRecipe(recipe.title, recipe),
        ),
      ),
    );
  }

  void _toggleSavedRecipe(String title, [ApiRecipe? recipe]) {
    setState(() {
      if (_savedRecipeTitles.contains(title)) {
        _savedRecipeTitles.remove(title);
        _savedRecipes.remove(title);
      } else {
        _savedRecipeTitles.add(title);
        final savedRecipe =
            recipe ??
            _exploreRecipes
                .where((item) => item.title == title)
                .cast<ApiRecipe?>()
                .firstWhere((item) => item != null, orElse: () => null);
        if (savedRecipe != null) _savedRecipes[title] = savedRecipe;
      }
    });
    widget.onSavedRecipesChanged?.call(
      Set.unmodifiable(_savedRecipes.values.toSet()),
    );
  }

  String _capitalizeCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }
}

class _SegmentedButtonHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int selectedIndex;
  final List<String> views;
  final ValueChanged<int> onChanged;

  _SegmentedButtonHeaderDelegate({
    required this.selectedIndex,
    required this.views,
    required this.onChanged,
  });

  static const double _height = 40 + (AsanSpacing.md * 2);

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AsanColorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AsanSpacing.lg,
          vertical: AsanSpacing.md,
        ),
        child: AsanSegmentedButton(
          views: views,
          selectedIndex: selectedIndex,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SegmentedButtonHeaderDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.views != views;
  }
}

class _RecipePickerSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int filterCount;
  final List<String> labels;
  final VoidCallback onBack;
  final VoidCallback onFilter;
  final ValueChanged<String> onRemoveFilter;
  final Widget searchBar;

  _RecipePickerSearchHeaderDelegate({
    required this.filterCount,
    required this.labels,
    required this.onBack,
    required this.onFilter,
    required this.onRemoveFilter,
    required this.searchBar,
  });

  double get _height =>
      38 + AsanSpacing.lg + (labels.isEmpty ? 0 : 40 + AsanSpacing.md);

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AsanColorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AsanSpacing.lg,
          right: AsanSpacing.lg,
          top: AsanSpacing.lg,
          bottom: 0,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    icon: const Icon(
                      Symbols.chevron_left_rounded,
                      size: 34,
                      weight: 600,
                    ),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: AsanSpacing.sm),
                  searchBar,
                  const SizedBox(width: AsanSpacing.sm),
                  FilledIconButton(
                    icon: const Icon(Symbols.tune_rounded),
                    isActive: filterCount > 0,
                    badgeCount: filterCount,
                    onPressed: onFilter,
                  ),
                ],
              ),
            ),
            if (labels.isNotEmpty) ...[
              const SizedBox(height: AsanSpacing.md),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  itemCount: labels.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AsanSpacing.sm),
                  itemBuilder: (context, index) => AsanFilterChip(
                    label: labels[index],
                    isSelected: true,
                    onPressed: () => onRemoveFilter(labels[index]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RecipePickerSearchHeaderDelegate oldDelegate) =>
      oldDelegate.filterCount != filterCount ||
      oldDelegate.labels != labels ||
      oldDelegate.searchBar != searchBar;
}
