import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/models/recipes.dart';

import 'package:asan/screens/recipe_form_screen.dart';

import 'package:asan/widgets/buttons.dart';
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
  String _searchQuery = '';
  AsanFilterSelection? _activeFilters;
  int _selectedView = 0;
  late final ScrollController _contentScrollController;
  late final ScrollController _filterScrollController;
  bool _isContentScrolled = false;
  int _receivedItemCount = 0;
  final Set<String> _savedRecipeTitles = {};

  static const _views = ['Explore', 'Saved', 'My Recipes'];
  static const _exploreRecipes = [
    _ExploreRecipe(
      title: 'Recipe 1',
      mealCategory: 'Meal Category',
      totalTime: '25 mins',
      imageUrl:
          'https://images.pexels.com/photos/24866519/pexels-photo-24866519.jpeg',
    ),
    _ExploreRecipe(
      title: 'Recipe 2',
      mealCategory: 'Meal Category',
      totalTime: '25 mins',
      imageUrl:
          'https://images.pexels.com/photos/26076240/pexels-photo-26076240.jpeg',
    ),
    _ExploreRecipe(
      title: 'Recipe 3',
      mealCategory: 'Meal Category',
      totalTime: '25 mins',
      imageUrl:
          'https://images.pexels.com/photos/32214637/pexels-photo-32214637.jpeg',
    ),
    _ExploreRecipe(
      title: 'Recipe 4',
      mealCategory: 'Meal Category',
      totalTime: '25 mins',
      imageUrl:
          'https://images.pexels.com/photos/15486347/pexels-photo-15486347.jpeg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentScrollController = ScrollController()
      ..addListener(_handleContentScroll);
    _filterScrollController = ScrollController();
    _items.addAll(widget.incomingRecipes);
    _receivedItemCount = widget.incomingRecipes.length;
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
    ...?_activeFilters?.mealCategories,
  ];

  Future<void> _showFilters() async {
    final selection = await showModalBottomSheet<AsanFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: filterSheetInitialSize(context),
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
        purchaseStatuses: {...filters.purchaseStatuses}..remove(label),
        totalTimeRanges: {...filters.totalTimeRanges}..remove(label),
        mealCategories: {...filters.mealCategories}..remove(label),
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
                        onChanged: (query) =>
                            setState(() => _searchQuery = query),
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
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _activeFilterLabels.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AsanSpacing.sm),
                        itemBuilder: (context, index) {
                          final label = _activeFilterLabels[index];
                          return ActiveFilterChip(
                            label: label,
                            onRemoved: () => _removeFilter(label),
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
              onChanged: (index) => setState(() => _selectedView = index),
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
        sliver: _items.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AsanSpacing.lg),
                  child: Text(
                    'No recipes added yet.',
                    style: AsanTextTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final recipe = _groupedRecipesFlat[index];
                  return RecipeCard(
                    recipeName: recipe.name,
                    mealCategory: recipe.mealCategory ?? 'Uncategorized',
                    totalTime: recipe.formattedTotalTime,
                    showBookmark: false,
                    onTap: () => _showEditItemDialog(recipe),
                  );
                }, childCount: _groupedRecipesFlat.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AsanSpacing.md,
                  mainAxisSpacing: AsanSpacing.lg,
                  childAspectRatio: 163 / 213,
                ),
              ),
      ),
    ];
  }

  SliverPadding _buildExploreView(List<_ExploreRecipe> recipes) {
    if (recipes.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        sliver: SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.lg),
            child: Text(
              _selectedView == 1
                  ? 'Your saved recipes will appear here.'
                  : 'No recipes match your search.',
              style: AsanTextTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final recipe = recipes[index];
          final isSaved = _savedRecipeTitles.contains(recipe.title);
          return RecipeCard(
            recipeName: recipe.title,
            mealCategory: recipe.mealCategory,
            imageUrl: recipe.imageUrl,
            totalTime: recipe.totalTime,
            isSaved: isSaved,
            onIconPressed: () => setState(() {
              if (isSaved) {
                _savedRecipeTitles.remove(recipe.title);
              } else {
                _savedRecipeTitles.add(recipe.title);
              }
            }),
          );
        }, childCount: recipes.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AsanSpacing.md,
          mainAxisSpacing: AsanSpacing.lg,
          childAspectRatio: 163 / 213,
        ),
      ),
    );
  }

  List<_ExploreRecipe> get _filteredExploreRecipes {
    final query = _searchQuery.trim().toLowerCase();
    return _exploreRecipes
        .where(
          (recipe) =>
              query.isEmpty ||
              recipe.title.toLowerCase().contains(query) ||
              recipe.mealCategory.toLowerCase().contains(query),
        )
        .toList();
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
                    _asanTotalTimeOptions(item.totalTime),
                  )),
        )
        .where(
          (item) => filters?.mealCategories.isEmpty ?? true
              ? true
              : filters!.mealCategories.contains(item.mealCategory),
        )
        .toList();
    final sortBy = filters?.sortBy ?? 'Meal category';
    items.sort((first, second) {
      final result = switch (sortBy) {
        'Meal Category' => (first.mealCategory ?? 'Uncategorized').compareTo(
          second.mealCategory ?? 'Uncategorized',
        ),
        'Recipe name' => first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        ),
        'Total time' => first.totalTime.compareTo(second.totalTime),
        _ => first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      };
      return (filters?.sortAscending ?? true) ? result : -result;
    });

    final groups = <String, List<Recipes>>{};
    for (final item in items) {
      final label = switch (sortBy) {
        'Meal Category' => item.mealCategory ?? 'Uncategorized',
        'Recipe name' => item.name.trim().isEmpty
            ? '#'
            : item.name.trim()[0].toUpperCase(),
        _ => item.mealCategory ?? 'Uncategorized',
      };
      (groups[label] ??= []).add(item);
    }
    final entries = groups.entries.toList();
    entries.sort((first, second) {
      final firstConsumed = first.key == 'Consumed';
      final secondConsumed = second.key == 'Consumed';
      if (firstConsumed == secondConsumed) return 0;
      return firstConsumed ? 1 : -1;
    });
    return entries;
  }

  List<Recipes> get _groupedRecipesFlat =>
      _groupedItems.expand((entry) => entry.value).toList();

  Future<void> _showEditItemDialog(Recipes item) async {
    final updatedItem = await showDialog<Recipes>(
      context: context,
      useSafeArea: false,
      builder: (context) => RecipeFormScreen(initialItem: item),
    );
    if (updatedItem != null && mounted) {
      final index = _items.indexOf(item);
      if (index != -1) setState(() => _items[index] = updatedItem);
    }
  }

  String _asanTotalTimeOptions(int minutes) {
    if (minutes <= 15) return '15 minutes or less';
    if (minutes <= 30) return '30 minutes or less';
    if (minutes <= 60) return '1 hour or less';
    return 'More than 1 hour';
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

class _ExploreRecipe {
  final String title;
  final String mealCategory;
  final String totalTime;
  final String imageUrl;

  const _ExploreRecipe({
    required this.title,
    required this.mealCategory,
    required this.totalTime,
    required this.imageUrl,
  });
}
