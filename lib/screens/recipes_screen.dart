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
      imageUrl:
          'https://images.pexels.com/photos/24866519/pexels-photo-24866519.jpeg',
    ),
    _ExploreRecipe(
      title: 'Recipe 2',
      mealCategory: 'Meal Category',
      imageUrl:
          'https://images.pexels.com/photos/26076240/pexels-photo-26076240.jpeg',
    ),
    _ExploreRecipe(
      title: 'Recipe 3',
      mealCategory: 'Meal Category',
      imageUrl:
          'https://images.pexels.com/photos/32214637/pexels-photo-32214637.jpeg',
    ),
    _ExploreRecipe(
      title: 'Recipe 4',
      mealCategory: 'Meal Category',
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
    ...?_activeFilters?.expirationStatuses,
    ...?_activeFilters?.foodGroups,
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

    final foodGroups = {...filters.foodGroups}..remove(label);
    setState(() {
      _activeFilters = filters.copyWith(
        expirationStatuses: {...filters.expirationStatuses}..remove(label),
        foodGroups: foodGroups,
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
        sliver: SliverList.separated(
          itemCount: _groupedItems.length,
          itemBuilder: (context, index) {
            final group = _groupedItems[index];
            return AsanExpansionTile(
              key: ValueKey(group.key),
              title: group.key,
              itemCount: group.value.length,
              children: group.value.map(_buildListTile).toList(),
            );
          },
          separatorBuilder: (context, index) => const Column(
            children: [
              SizedBox(height: AsanSpacing.md),
              AsanDivider(),
              SizedBox(height: AsanSpacing.md),
            ],
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
          return Stack(
            children: [
              RecipeCard(
                title: recipe.title,
                mealCategory: recipe.mealCategory,
                imageUrl: recipe.imageUrl,
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  tooltip: isSaved ? 'Remove from saved' : 'Save recipe',
                  icon: Icon(
                    isSaved
                        ? Symbols.bookmark_rounded
                        : Symbols.bookmark_border_rounded,
                    fill: isSaved ? 1 : 0,
                  ),
                  onPressed: () => setState(() {
                    if (isSaved) {
                      _savedRecipeTitles.remove(recipe.title);
                    } else {
                      _savedRecipeTitles.add(recipe.title);
                    }
                  }),
                ),
              ),
            ],
          );
        }, childCount: recipes.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AsanSpacing.md,
          mainAxisSpacing: AsanSpacing.lg,
          childAspectRatio: 0.72,
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
              (filters?.expirationStatuses.isEmpty ?? true
                  ? true
                  : filters!.expirationStatuses.contains(
                      _expirationStatus(item),
                    )),
        )
        .where(
          (item) => filters?.foodGroups.isEmpty ?? true
              ? true
              : filters!.foodGroups.contains(item.foodGroup),
        )
        .toList();
    final sortBy = filters?.sortBy ?? 'Expiration date';
    items.sort((first, second) {
      final result = switch (sortBy) {
        'Food group' => (first.foodGroup ?? 'Uncategorized').compareTo(
          second.foodGroup ?? 'Uncategorized',
        ),
        'Item name' => first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        ),
        'Purchase date' => _compareDates(
          first.purchaseDate,
          second.purchaseDate,
        ),
        _ => _compareDates(first.expiryDate, second.expiryDate),
      };
      return (filters?.sortAscending ?? true) ? result : -result;
    });

    final groups = <String, List<Recipes>>{};
    for (final item in items) {
      final label = item.consumed
          ? 'Consumed'
          : switch (sortBy) {
              'Food group' => item.foodGroup ?? 'Uncategorized',
              'Item name' =>
                item.name.trim().isEmpty
                    ? '#'
                    : item.name.trim()[0].toUpperCase(),
              'Purchase date' =>
                item.purchaseDate == null
                    ? 'No purchase date'
                    : _formatDate(item.purchaseDate!),
              _ =>
                item.expiryDate == null
                    ? 'No expiration date'
                    : _formatDate(item.expiryDate!),
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

  Widget _buildListTile(Recipes item) => AsanListTile(
    key: ValueKey(item),
    itemName: item.name,
    quantity: item.quantity,
    unit: item.unit,
    category: item.consumed
        ? item.foodGroup ?? 'Uncategorized'
        : _activeSort == 'Food group'
        ? 'expires ${_formatDate(item.expiryDate)}'
        : item.foodGroup ?? 'Uncategorized',
    purchasedDate: item.consumed
        ? 'consumed ${_formatConsumedDate(item.consumedDate)}'
        : _activeSort == 'Item name' || _activeSort == 'Purchase date'
        ? 'expires ${_formatDate(item.expiryDate)}'
        : item.purchaseDate == null
        ? ''
        : 'bought ${_formatDate(item.purchaseDate!)}',
    notes: item.notes,
    isChecked: item.consumed,
    onChanged: (checked) {
      final index = _items.indexOf(item);
      if (index != -1) {
        setState(
          () => _items[index] = item.copyWith(
            consumed: checked,
            consumedDate: checked ? DateTime.now() : null,
          ),
        );
      }
    },
    onTap: () => _showEditItemDialog(item),
  );

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

  String get _activeSort => _activeFilters?.sortBy ?? 'Expiration date';

  String _expirationStatus(Recipes item) {
    if (item.consumed) return 'Consumed';
    if (item.expiryDate == null) return 'No expiration date';
    final today = DateTime.now();
    final date = DateTime(
      item.expiryDate!.year,
      item.expiryDate!.month,
      item.expiryDate!.day,
    );
    final days = date
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (days < 0) return 'Expired';
    if (days <= 7) return 'Expiring soon';
    return 'Not expired';
  }

  int _compareDates(DateTime? first, DateTime? second) {
    if (first == null && second == null) return 0;
    if (first == null) return 1;
    if (second == null) return -1;
    return first.compareTo(second);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No expiration date';
    return _formatCalendarDate(date);
  }

  String _formatConsumedDate(DateTime? date) {
    if (date == null) return 'date unavailable';
    return _formatCalendarDate(date);
  }

  String _formatCalendarDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
  final String imageUrl;

  const _ExploreRecipe({
    required this.title,
    required this.mealCategory,
    required this.imageUrl,
  });
}
