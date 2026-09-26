import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';
import 'package:asan/models/recipes.dart';
import 'package:asan/models/filter_selection.dart';
import 'package:asan/services/api/recipe_api.dart';

import 'package:asan/screens/recipe_form_screen.dart';
import 'package:asan/screens/recipe_details_screen.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class RecipesScreen extends StatefulWidget {
  final List<Recipes> incomingRecipes;

  const RecipesScreen({super.key, this.incomingRecipes = const []});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}
class _RecipesScreenState extends State<RecipesScreen> {
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
  String? _exploreCategory;

  static const _views = ['Explore', 'Saved', 'My Recipes'];
  @override
  void initState() {
    super.initState();
    _contentScrollController = ScrollController()
      ..addListener(_handleContentScroll);
    _filterScrollController = ScrollController();
    _items.addAll(widget.incomingRecipes);
    _receivedItemCount = widget.incomingRecipes.length;
    _loadExploreRecipes();
  }

  @override
  void didUpdateWidget(covariant RecipesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.incomingRecipes.length > _receivedItemCount) {
      _items.addAll(widget.incomingRecipes.skip(_receivedItemCount));
      _receivedItemCount = widget.incomingRecipes.length;
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

  Future<void> _showAddRecipeDialog(BuildContext context) async {
    final item = await showDialog<Recipes>(
      context: context,
      useSafeArea: false,
      builder: (context) => const RecipeFormScreen(),
    );
    if (item != null && mounted) {
      setState(() => _items.add(item));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AsanAppBar(
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
                      child: AsanSearchBar(
                        hintText: 'Search recipes...',
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
      body: CustomScrollView(
        controller: _contentScrollController,
        slivers: [
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
    );
  }

  List<Widget> _buildSelectedView() {
    if (_selectedView < 2) {
      final recipes = _selectedView == 0
          ? _filteredExploreRecipes
          : _filteredExploreRecipes
                .where((recipe) => _savedRecipeTitles.contains(recipe.title))
                .toList();
      return [_buildExploreView(recipes)];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        sliver: _items.isEmpty &&
                (_searchQuery.trim().isNotEmpty ||
                    _activeFilterLabels.isNotEmpty)
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: AsanEmptyState(
                  icon: Symbols.search_off_rounded,
                  title: "No recipes found",
                  message: "No matches for '${_searchQuery.trim()}'."
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
                      ? "No results for '${_searchQuery.trim()}'"
                      : 'No recipes found',
                  message: _searchQuery.trim().isNotEmpty
                      ? "did you mean '${_searchQuery.trim()}'"
                      : 'Try a different search or adjust your filters.',
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
                          padding: const EdgeInsets.only(bottom: AsanSpacing.md),
                          child: Text(
                            group.key,
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
                                  height: width * 220 / 163,
                                  child: RecipeCard(
                                    recipeName: recipe.name,
                                    mealCategory: recipe.mealCategory
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? recipe.mealCategory!
                                        : '-',
                                    imageBytes: recipe.imageBytes,
                                    totalTime: recipe.formattedTotalTime,
                                    showBookmark: false,
                                    onTap: () => _showRecipeDetails(recipe),
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

  SliverPadding _buildExploreView(List<ApiRecipe> recipes) {
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
                      ? "No results for '${_searchQuery.trim()}'"
                      : 'No recipes found')
                  : 'No saved recipes yet',
              message: hasSearchOrFilters
                  ? (_searchQuery.trim().isNotEmpty
                      ? "did you mean '${_searchQuery.trim()}'"
                      : 'Try a different search or adjust your filters.')
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
            icon: _searchQuery.trim().isNotEmpty ||
                    _activeFilterLabels.isNotEmpty
                ? Symbols.search_off_rounded
                : Symbols.restaurant_menu_rounded,
            title: _searchQuery.trim().isNotEmpty
                ? "No results for '${_searchQuery.trim()}'"
                : _activeFilterLabels.isNotEmpty
                ? 'No recipes match these filters'
                : 'No recipes to explore yet',
            message: _searchQuery.trim().isNotEmpty
                ? "did you mean '${_searchQuery.trim()}'"
                : _activeFilterLabels.isNotEmpty
                ? 'Try adjusting your filters.'
                : 'Recipes will appear here when they are available.',
          ),
        ),
      );
    }

    final groups = <String, List<ApiRecipe>>{};
    for (final recipe in recipes) {
      (groups[recipe.category.trim().isEmpty ? 'Other' : recipe.category] ??= [])
          .add(recipe);
    }
    final categories = groups.keys.toList()..sort();

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
                      child: Text(_capitalizeCategory(_exploreCategory!), style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    AsanTextButton(
                      label: 'All categories',
                      onPressed: () => setState(() => _exploreCategory = null),
                    ),
                  ],
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildExploreRecipeCard(categoryRecipes[index]),
                childCount: categoryRecipes.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AsanSpacing.md,
                mainAxisSpacing: AsanSpacing.sm,
                childAspectRatio: 163 / 220,
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
          final category = categories[index];
          final categoryRecipes = groups[category]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: AsanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(child: Text(_capitalizeCategory(category), style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
                      AsanTextButton(
                        label: 'View all',
                        onPressed: () => setState(() => _exploreCategory = category),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AsanSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth - (AsanSpacing.lg * 2) - AsanSpacing.md) / 2;
                    return SizedBox(
                      height: cardWidth + 56,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.lg),
                          scrollDirection: Axis.horizontal,
                          itemCount: categoryRecipes.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AsanSpacing.md),
                          itemBuilder: (context, recipeIndex) => SizedBox(
                            width: cardWidth,
                            child: _buildExploreRecipeCard(categoryRecipes[recipeIndex]),
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
      mealCategory: recipe.category,
      imageUrl: _recipeImages[recipe.title] ?? (recipe.imageUrl.isEmpty ? null : recipe.imageUrl),
      totalTime: totalTime > 0 ? Recipes.formatTotalTime(totalTime) : 'Open recipe',
      isSaved: isSaved,
      onIconPressed: () => setState(() {
        if (isSaved) {
          _savedRecipeTitles.remove(recipe.title);
        } else {
          _savedRecipeTitles.add(recipe.title);
        }
      }),
      onTap: () => _showExploreRecipeDetails(recipe),
    );
  }

  List<ApiRecipe> get _filteredExploreRecipes {
    final filters = _activeFilters;
    return _exploreRecipes.where((recipe) {
      final time = recipe.totalTime > 0 ? recipe.totalTime : recipe.prepTime + recipe.cookTime;
      final totalTimeMatch = filters?.totalTimeRanges.isEmpty ?? true
          ? true
          : filters!.totalTimeRanges.contains(asanTotalTimeRangeFor(time));
      final dietMatch = filters?.mealCategories.isEmpty ?? true
          ? true
          : recipe.tags.any((tag) => filters!.mealCategories.any((diet) => tag.toLowerCase() == diet.toLowerCase()));
      final mealTimeMatch = filters?.mealTimes.isEmpty ?? true
          ? true
          : recipe.tags.any((tag) => filters!.mealTimes.any((mealTime) => tag.toLowerCase() == mealTime.toLowerCase()));
      final dishTypes = [...recipe.dishTypes, recipe.category];
      final dishTypeMatch = filters?.mealTimeCategories.isEmpty ?? true
          ? true
          : dishTypes.any((type) => filters!.mealTimeCategories.any((selected) => type.toLowerCase() == selected.toLowerCase()));
      final cuisineMatch = filters?.cuisines.isEmpty ?? true
          ? true
          : filters!.cuisines.any((cuisine) => (recipe.cuisine ?? '').toLowerCase().split(',').map((part) => part.trim()).contains(cuisine.toLowerCase()));
      return totalTimeMatch && dietMatch && mealTimeMatch && dishTypeMatch && cuisineMatch;
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
        _exploreHttpStatusCode = error is RecipeApiException ? error.statusCode : null;
        _isLoadingExplore = false;
      });
    }
  }

  void _loadRecipeImage(String title, [String? imageUrl]) {
    if (_recipeImages.containsKey(title) || !_pendingRecipeImages.add(title)) return;
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
                    asanTotalTimeRangeFor(item.totalTime > 0
                        ? item.totalTime
                        : item.prepTime + item.cookTime),
                  )),
        )
        .where(
          (item) => filters?.mealCategories.isEmpty ?? true
              ? true
              : item.tags.any((tag) => filters!.mealCategories.any((diet) => tag.toLowerCase() == diet.toLowerCase())),
        )
        .where(
          (item) => filters?.mealTimeCategories.isEmpty ?? true
              ? true
              : item.dishTypes.any((type) => filters!.mealTimeCategories.any((selected) => type.toLowerCase() == selected.toLowerCase())),
        )
        .where(
          (item) => filters?.mealTimes.isEmpty ?? true
              ? true
              : [...item.idealFor, ...item.tags.where(asanMealTimes.contains)].any(
                  (mealTime) => filters!.mealTimes.any((selected) => mealTime.toLowerCase() == selected.toLowerCase()),
                ),
        )
        .where(
          (item) => filters?.cuisines.isEmpty ?? true
              ? true
              : filters!.cuisines.any((cuisine) => (item.cuisine ?? '').toLowerCase().split(',').map((part) => part.trim()).contains(cuisine.toLowerCase())),
        )
        .toList();
    final sortBy = filters?.sortBy ?? 'Meal category';
    int totalTime(Recipes recipe) => recipe.totalTime > 0
        ? recipe.totalTime
        : recipe.prepTime + recipe.cookTime;

    String firstDishType(Recipes recipe) =>
        recipe.dishTypes.map((type) => type.trim()).firstWhere(
          (type) => type.isNotEmpty,
          orElse: () => recipe.mealCategory?.trim().isNotEmpty == true
              ? recipe.mealCategory!.trim()
              : 'Uncategorized',
        );

    String timeGroup(Recipes recipe) {
      final minutes = totalTime(recipe);
      if (minutes <= 0) return 'Unknown time';
      final upperBound = ((minutes + 9) ~/ 10) * 10;
      return '$upperBound mins or less';
    }

    items.sort((first, second) {
      final result = switch (sortBy) {
        'Dish type' => firstDishType(first).toLowerCase().compareTo(
          firstDishType(second).toLowerCase(),
        ),
        'Cuisine' => (first.cuisine?.trim().isNotEmpty == true
                ? first.cuisine!.trim()
                : 'Unknown cuisine')
            .toLowerCase()
            .compareTo((second.cuisine?.trim().isNotEmpty == true
                    ? second.cuisine!.trim()
                    : 'Unknown cuisine')
                .toLowerCase()),
        'Meal category' => (first.mealCategory ?? 'Uncategorized').compareTo(
          second.mealCategory ?? 'Uncategorized',
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
        'Cuisine' => item.cuisine?.trim().isNotEmpty == true
            ? item.cuisine!.trim()
            : 'Unknown cuisine',
        'Meal category' => item.mealCategory ?? 'Uncategorized',
        'Total time' => timeGroup(item),
        'Recipe name' => item.name.trim().isEmpty
            ? '#'
            : item.name.trim()[0].toUpperCase(),
        _ => item.mealCategory ?? 'Uncategorized',
      };
      (groups[label] ??= []).add(item);
    }
    final entries = groups.entries.toList();
    entries.sort((first, second) {
      if (sortBy == 'Total time') {
        int bucket(String label) => label == 'Unknown time'
            ? 1 << 30
            : int.tryParse(label.split(' ').first) ?? 0;
        final result = bucket(first.key).compareTo(bucket(second.key));
        return (filters?.sortAscending ?? true) ? result : -result;
      }
      final result = first.key.toLowerCase().compareTo(second.key.toLowerCase());
      return (filters?.sortAscending ?? true) ? result : -result;
    });
    return entries;
  }

  List<Recipes> get _groupedRecipesFlat =>
      _groupedItems.expand((entry) => entry.value).toList();

  Future<void> _showEditItemDialog(Recipes item) async {
    final updatedItem = await showDialog<Recipes>(
      context: context,
      useSafeArea: false,
      builder: (context) => RecipeFormScreen(
        initialItem: item,
        onDelete: () {
          setState(() => _items.remove(item));
        },
      ),
    );
    if (updatedItem != null && mounted) {
      final index = _items.indexOf(item);
      if (index != -1) setState(() => _items[index] = updatedItem);
    }
  }

  void _showRecipeDetails(Recipes recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: recipe,
          ingredients: recipe.ingredients,
          ingredientNotes: recipe.ingredientNotes,
          instructions: recipe.instructions,
          showEditButton: true,
          onEdit: () {
            _showEditItemDialog(recipe);
          }
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
      // Search results already contain enough data to show the details page.
      // Keep navigation available if the richer information request fails.
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
          ),
          imageUrl: imageUrl,
          ingredients: details.ingredients,
          instructions: details.instructions,
          isSaved: isSaved,
          onToggleSaved: () => setState(() {
            if (_savedRecipeTitles.contains(recipe.title)) {
              _savedRecipeTitles.remove(recipe.title);
            } else {
              _savedRecipeTitles.add(recipe.title);
            }
          }),
        ),
      ),
    );
  }

  String _capitalizeCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
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
