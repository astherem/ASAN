import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/filter_selection.dart';

import 'package:asan/services/api/recipe_api.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/selections.dart';

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

  const SearchScreen({super.key, this.initialFilters});

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
  late AsanFilterSelection? _filters = widget.initialFilters;

  List<String> get _activeFilterLabels => [
    ...?_filters?.totalTimeRanges,
    ...?_filters?.mealTimes,
    ...?_filters?.mealTimeCategories,
    ...?_filters?.mealCategories,
    ...?_filters?.cuisines,
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _recipeApi.close();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final request = ++_request;
    setState(() { _loading = true; _error = null; });
    try {
      final recipes = await _recipeApi.search(query);
      if (!mounted || request != _request) return;
      setState(() { _recipes = recipes; _loading = false; });
    } on RecipeApiException catch (error) {
      if (!mounted || request != _request) return;
      setState(() { _error = error.message; _loading = false; });
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
      final time = recipe.totalTime > 0 ? recipe.totalTime : recipe.prepTime + recipe.cookTime;
      final timeMatch = filters.totalTimeRanges.isEmpty || filters.totalTimeRanges.contains(asanTotalTimeRangeFor(time));
      final dietMatch = filters.mealCategories.isEmpty || recipe.tags.any((tag) => filters.mealCategories.any((value) => value.toLowerCase() == tag.toLowerCase()));
      final mealMatch = filters.mealTimes.isEmpty || recipe.tags.any((tag) => filters.mealTimes.any((value) => value.toLowerCase() == tag.toLowerCase()));
      final types = [...recipe.dishTypes, recipe.category];
      final typeMatch = filters.mealTimeCategories.isEmpty || types.any((type) => filters.mealTimeCategories.any((value) => value.toLowerCase() == type.toLowerCase()));
      final cuisineMatch = filters.cuisines.isEmpty || filters.cuisines.any((value) => (recipe.cuisine ?? '').toLowerCase().split(',').map((part) => part.trim()).contains(value.toLowerCase()));
      return timeMatch && dietMatch && mealMatch && typeMatch && cuisineMatch;
    }).toList();
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
      _recipes = const [];
      _error = null;
      _loading = query.isNotEmpty;
    });
    if (query.isEmpty) {
      ++_request;
    } else {
      _search(query);
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
      _recipes = const [];
      _error = null;
      _loading = query.isNotEmpty;
    });
    if (query.isEmpty) {
      ++_request;
    } else {
      _search(query);
    }
  }

  void _returnToInitial() {
    _debounce?.cancel();
    ++_request;
    setState(() {
      _query = '';
      _filters = null;
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _query.trim().isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AsanSpacing.lg),
              children: [
                _selectionSection('Search by Meal Time', _mealTimeSearchCards, _filters?.mealTimes ?? const {}, dishType: false),
                _selectionSection('Search by Dish Type', _dishTypeSearchCards, _filters?.mealTimeCategories ?? const {}, dishType: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_activeFilterLabels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AsanSpacing.lg, AsanSpacing.sm, AsanSpacing.lg, 0),
                    child: Wrap(
                      spacing: AsanSpacing.sm,
                      runSpacing: AsanSpacing.sm,
                      children: _activeFilterLabels.map((label) => AsanFilterChip(
                        label: label,
                        isSelected: true,
                        onPressed: () => _removeFilter(label),
                      )).toList(),
                    ),
                  ),
                Expanded(child: _error != null && _recipes.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(AsanSpacing.lg), child: Text(_error!, textAlign: TextAlign.center)))
          : _loading && _recipes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : recipes.isEmpty
                  ? Center(child: Text(_query.isEmpty ? 'Search for a recipe' : 'No recipes found', style: AsanTextTheme.bodyMedium))
                  : GridView.builder(
                      padding: const EdgeInsets.all(AsanSpacing.lg),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AsanSpacing.md,
                        mainAxisSpacing: AsanSpacing.lg,
                        childAspectRatio: 0.72,
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
                        );
                      },
                    )),
              ],
            ),
      ),
    );
  }
}
