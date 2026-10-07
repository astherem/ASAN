import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/meal_plans.dart';
import 'package:asan/models/recipes.dart';
import 'package:asan/models/grocery_item.dart';
import 'package:asan/screens/recipes_screen.dart';
import 'package:asan/screens/recipe_details_screen.dart';
import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';
import 'package:asan/widgets/inputs.dart';

class MealPlanScreen extends StatefulWidget {
  final List<MealPlans> incomingEntries;
  final List<Recipes> recipes;
  final ValueChanged<List<MealPlans>>? onEntriesChanged;
  final VoidCallback? onViewMealPlan;
  final VoidCallback? onViewGroceries;
  final Future<bool> Function(List<GroceryItem>)? onAddToGroceries;

  const MealPlanScreen({super.key, this.incomingEntries = const [], this.recipes = const [], this.onEntriesChanged, this.onViewMealPlan, this.onViewGroceries, this.onAddToGroceries});

  @override
  State<MealPlanScreen> createState() => MealPlanScreenState();
}

class MealPlanScreenState extends State<MealPlanScreen> {
  static const _rangeViews = ['Day', 'Week'];
  static const _mealTimeOrder = asanMealTimes;
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<MealPlans> _entries = [];
  int _receivedEntryCount = 0;

  void _notifyEntriesChanged() => widget.onEntriesChanged?.call(List.unmodifiable(_entries));
  int _selectedRange = 0;
  DateTime _selectedDate = DateTime.now();
  AsanFilterSelection? _dayFilters;
  AsanFilterSelection? _weekFilters;

  AsanFilterSelection? get _activeFilters =>
      _selectedRange == 0 ? _dayFilters : _weekFilters;

  void _setActiveFilters(AsanFilterSelection? selection) {
    if (selection == null) return;
    final other = _selectedRange == 0 ? _weekFilters : _dayFilters;
    final carriedFilters = selection.copyWith(
      sortBy: other?.sortBy ?? (_selectedRange == 0 ? 'Day' : 'Meal time'),
      sortAscending: other?.sortAscending ?? true,
    );
    if (_selectedRange == 0) {
      _dayFilters = selection;
      _weekFilters = carriedFilters;
    } else {
      _weekFilters = selection;
      _dayFilters = carriedFilters;
    }
  }

  List<String> get _activeFilterLabels => [
    ...?_activeFilters?.totalTimeRanges,
    ...?_activeFilters?.mealTimeCategories,
    ...?_activeFilters?.mealCategories,
    ...?_activeFilters?.cuisines,
    if (_selectedRange == 1) ...?_activeFilters?.days,
  ];

  String get _sortBy => _selectedRange == 0 && _activeFilters?.sortBy == 'Day'
      ? 'Meal time'
      : _activeFilters?.sortBy ?? (_selectedRange == 1 ? 'Day' : 'Meal time');

  Future<void> _showFilters() async {
    final selection = await showModalBottomSheet<AsanFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: filterSheetInitialSize(context, menuType: AsanFilterMenuType.meals),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AsanFilterList(
          scrollController: scrollController,
          menuType: AsanFilterMenuType.meals,
          initialSelection: _activeFilters,
          showDaySort: _selectedRange == 1,
        ),
      ),
    );
    if (selection != null && mounted) setState(() => _setActiveFilters(selection));
  }

  Future<void> addMealFromRecipe(Recipes recipe) => _addMeal(initialRecipe: recipe);

  void updatePlannedRecipe(Recipes previous, Recipes updated) {
    var changed = false;
    for (var i = 0; i < _entries.length; i++) {
      if (identical(_entries[i].recipe, previous)) {
        _entries[i] = _entries[i].copyWith(recipe: updated);
        changed = true;
      }
    }
    if (changed) {
      _notifyEntriesChanged();
      if (mounted) setState(() {});
    }
  }

  Future<void> _addMeal({String? mealTime, String? dishType, DateTime? initialDate, Recipes? initialRecipe}) async {
    final formKey = GlobalKey<_MealPlanFormState>();
    final entries = await showDialog<List<MealPlans>>(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: FullScreenDialogHeader(
              screenTitle: 'Add Meal to Plan',
              bottomPadding: AsanSpacing.xs,
              onBackPressed: () async {
                final formState = formKey.currentState;
                if (formState == null || !formState.hasChanges) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  return;
                }
                final discard = await AsanAlertDialog.show(
                  dialogContext,
                  title: 'Discard Changes?',
                  content: 'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
                  cancelText: 'Cancel',
                  destructiveText: 'Discard',
                );
                if (discard == true && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
            body: _MealPlanForm(
              key: formKey,
              recipes: [
                ...widget.recipes,
                if (initialRecipe != null && !widget.recipes.any((r) => r.name == initialRecipe.name)) initialRecipe,
              ],
              initialDate: initialDate ?? _selectedDate,
              initialMealTime: mealTime,
              initialDishType: dishType,
              initialRecipe: initialRecipe,
              onAddToGroceries: widget.onAddToGroceries,
              onViewGroceries: widget.onViewGroceries,
            ),
          ),
        ),
      ),
    );
    if (entries != null && mounted) {
      setState(() => _entries.addAll(entries));
      _notifyEntriesChanged();
      AsanSnackBar.show(
        context,
        message: entries.length == 1
            ? '${entries.first.recipe.name} added to plan'
            : '${entries.length} meals added to plan',
        actionLabel: 'View',
        onAction: widget.onViewMealPlan == null
            ? null
            : () {
                Navigator.of(context).maybePop();
                widget.onViewMealPlan!();
              },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _entries.addAll(widget.incomingEntries);
    _receivedEntryCount = widget.incomingEntries.length;
  }

  @override
  void didUpdateWidget(covariant MealPlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.incomingEntries.length > _receivedEntryCount) {
      _entries.addAll(widget.incomingEntries.skip(_receivedEntryCount));
      _receivedEntryCount = widget.incomingEntries.length;
      setState(() {});
    }
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
    });
  }

  String get _formattedDate =>
      '${_months[_selectedDate.month - 1]} ${_selectedDate.day}';

  DateTime get _weekStart {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return date.subtract(Duration(days: date.weekday % 7));
  }

  Future<void> _addVisibleMealsToGroceries() async {
    final visibleEntries = _selectedRange == 0
        ? _groupedEntriesForSelectedDate.values.expand((entries) => entries)
        : _groupedEntriesForSelectedWeek.values.expand((entries) => entries);
    final items = <GroceryItem>[];
    for (final recipe in visibleEntries.map((entry) => entry.recipe)) {
      for (var i = 0; i < recipe.ingredients.length; i++) {
        final ingredient = recipe.ingredients[i].trim();
        final parsed = _parseFormattedIngredient(ingredient);
        if (ingredient.isEmpty) continue;
        items.add(GroceryItem(
          name: parsed?.name ?? ingredient,
          amount: i < recipe.ingredientAmounts.length && recipe.ingredientAmounts[i].trim().isNotEmpty
              ? recipe.ingredientAmounts[i]
              : parsed?.amount ?? '',
          unit: i < recipe.ingredientUnits.length && recipe.ingredientUnits[i].trim().isNotEmpty
              ? recipe.ingredientUnits[i]
              : parsed?.unit ?? '',
          aisle: i < recipe.ingredientAisles.length ? recipe.ingredientAisles[i] ?? 'Other' : 'Other',
          notes: i < recipe.ingredientNotes.length ? recipe.ingredientNotes[i] : '',
        ));
      }
    }
    if (items.isEmpty) {
      AsanSnackBar.show(context, message: 'No ingredients for $_dateLabel meal plan.');
      return;
    }
    final added = await widget.onAddToGroceries?.call(items) ?? false;
    if (!added) return;
    if (mounted) {
      AsanSnackBar.show(
        context,
        message: '${items.length} ingredients added to groceries',
        actionLabel: 'View',
        onAction: widget.onViewGroceries,
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${_months[date.month - 1].substring(0, 3)} ${date.day}';

  String _formatGroupTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  String _normalizeMealTime(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'morning meal' ? 'breakfast' : normalized;
  }

  String _mealTimeLabel(String value) =>
      _normalizeMealTime(value) == 'breakfast' ? 'Breakfast' : _formatGroupTitle(value);

  Future<void> _editMeal(MealPlans meal) async {
    final entries = await _showMealForm(meal: meal);
    if (entries == null || !mounted) return;
    final index = _entries.indexOf(meal);
    if (index < 0) return;
    setState(() {
      _entries.removeAt(index);
      _entries.insertAll(index, entries);
    });
    _notifyEntriesChanged();
  }

  Future<List<MealPlans>?> _showMealForm({MealPlans? meal}) async {
    final formKey = GlobalKey<_MealPlanFormState>();
    // Existing add flow below builds the fullscreen form; edits use the same
    // fields with a single date and meal time preselected.
    return showDialog<List<MealPlans>>(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: FullScreenDialogHeader(
              screenTitle: meal == null ? 'Add Meal to Plan' : 'Edit Planned Meal',
              bottomPadding: AsanSpacing.xs,
              onBackPressed: () async {
                final formState = formKey.currentState;
                if (formState == null || !formState.hasChanges) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  return;
                }
                final discard = await AsanAlertDialog.show(
                  dialogContext,
                  title: 'Discard Changes?',
                  content: 'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
                  cancelText: 'Cancel',
                  destructiveText: 'Discard',
                );
                if (discard == true && dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            body: _MealPlanForm(
              key: formKey,
              recipes: [
                ...widget.recipes,
                if (meal != null && !widget.recipes.any((r) => r.name == meal.recipe.name)) meal.recipe,
              ],
              initialDate: meal?.date ?? _selectedDate,
              initialMealTime: meal?.mealTime,
              initialDishType: meal?.dishType,
              initialRecipe: meal?.recipe,
              initialServings: meal?.servings,
              isEditing: meal != null,
              onAddToGroceries: widget.onAddToGroceries,
              onViewGroceries: widget.onViewGroceries,
            ),
          ),
        ),
      ),
    );
  }

  void _deleteMeal(MealPlans meal) {
    setState(() => _entries.remove(meal));
    _notifyEntriesChanged();
    AsanSnackBar.show(context, message: '${meal.recipe.name} removed from plan');
  }

  ({String amount, String unit, String name})? _parseFormattedIngredient(
    String ingredient,
  ) {
    final match = RegExp(
      r'^(\d+(?:\s+\d+/\d+|[./]\d+)?)(?:\s+(cups?|tbsp|tablespoons?|tsp|teaspoons?|g|kg|mg|ml|l|oz|ounces?|lb|lbs|pounds?|cloves?|cans?|slices?|pieces?|pinch(?:es)?))?\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(ingredient);
    if (match == null) return null;
    final rawUnit = match.group(2) ?? '';
    final unit = switch (rawUnit.toLowerCase()) {
      'cup' || 'cups' => 'cup',
      'tablespoon' || 'tablespoons' || 'tbsp' => 'tbsp',
      'teaspoon' || 'teaspoons' || 'tsp' => 'tsp',
      'ounce' || 'ounces' || 'oz' => 'oz',
      'pound' || 'pounds' || 'lb' || 'lbs' => 'lb',
      'clove' || 'cloves' => 'cloves',
      'slice' || 'slices' => 'slices',
      'piece' || 'pieces' => 'pcs',
      'pinch' || 'pinches' => 'pinch',
      _ => rawUnit,
    };
    final name = match.group(3)!.trim().replaceFirst(
      RegExp(r'^of\s+', caseSensitive: false),
      '',
    );
    return (amount: match.group(1)!, unit: unit, name: name);
  }

  String get _dateLabel {
    if (_selectedRange == 0) return _formattedDate;
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return '${_formatDate(_weekStart)} - ${_formatDate(weekEnd)}';
  }

  Map<String, List<MealPlans>> _groupedEntriesForDate(DateTime date) {
    final groups = <String, List<MealPlans>>{};
    final filters = _activeFilters;
    final sortBy = _selectedRange == 0 && filters?.sortBy == 'Day'
        ? 'Meal time'
        : filters?.sortBy ?? (_selectedRange == 1 ? 'Day' : 'Meal time');
    if (_selectedRange == 1 && filters?.days.isNotEmpty == true && !filters!.days.contains(_weekdayName(date))) return groups;
    for (final entry in _entries) {
      if (!entry.isOnDate(date)) continue;
      if (filters?.mealTimeCategories.isNotEmpty ?? false) {
        if (!filters!.mealTimeCategories.any(
          (mealTime) => _normalizeMealTime(mealTime) == _normalizeMealTime(entry.mealTime),
        )) continue;
      }
      if (filters?.mealCategories.isNotEmpty ?? false) {
        if (!_dishTypesFor(entry).any(filters!.mealCategories.contains)) continue;
      }
      if (filters?.cuisines.isNotEmpty ?? false) {
        final recipeCuisines = _cuisinesFor(entry.recipe)
            .map((cuisine) => cuisine.toLowerCase())
            .toSet();
        if (!filters!.cuisines.any(
          (cuisine) => recipeCuisines.contains(cuisine.trim().toLowerCase()),
        )) continue;
      }
      if (filters?.totalTimeRanges.isNotEmpty ?? false) {
        final range = asanTotalTimeRangeFor(entry.recipe.totalTime);
        if (range == null || !filters!.totalTimeRanges.contains(range)) continue;
      }
      final key = switch (sortBy) {
        'Dish type' => _formatGroupTitle(_primaryDishType(entry).isEmpty ? 'Uncategorized' : _primaryDishType(entry)),
        'Cuisine' => _formatGroupTitle(_primaryCuisine(entry.recipe).isEmpty ? 'Uncategorized' : _primaryCuisine(entry.recipe)),
        'Recipe name' => _recipeNameGroupTitle(entry.recipe.name),
        'Total time' =>
          asanTotalTimeRangeFor(entry.recipe.totalTime) ?? 'Unknown time',
        'Day' => '${_weekdayName(date)}, ${_formatDate(date)}',
        _ => _mealTimeLabel(entry.mealTime),
      };
      (groups[key] ??= []).add(entry);
    }
    for (final entries in groups.values) {
      entries.sort((a, b) {
        final comparison = switch (filters?.sortBy) {
          'Recipe name' => a.recipe.name.toLowerCase().compareTo(b.recipe.name.toLowerCase()),
          'Dish type' => _primaryDishType(a).toLowerCase().compareTo(_primaryDishType(b).toLowerCase()),
          'Cuisine' => _primaryCuisine(a.recipe).toLowerCase().compareTo(_primaryCuisine(b.recipe).toLowerCase()),
          'Total time' => a.recipe.totalTime.compareTo(b.recipe.totalTime),
          _ => 0,
        };
        return (filters?.sortAscending ?? true) ? comparison : -comparison;
      });
    }
    return groups;
  }

  int _totalTimeGroupOrder(String label) {
    final index = asanTotalTimes.indexOf(label);
    return index < 0 ? asanTotalTimes.length : index;
  }

  Map<String, List<MealPlans>> get _groupedEntriesForSelectedDate => _groupedEntriesForDate(_selectedDate);

  Map<String, List<MealPlans>> get _groupedEntriesForSelectedWeek {
    final groups = <String, List<MealPlans>>{};
    final sortBy = _sortBy;
    for (var day = 0; day < 7; day++) {
      final date = _weekStart.add(Duration(days: day));
      if (_activeFilters?.days.isNotEmpty == true && !_activeFilters!.days.contains(_weekdayName(date))) continue;
      final dateGroups = _groupedEntriesForDate(date);
      if (sortBy == 'Day') {
        final entries = dateGroups.values.expand((items) => items).toList();
        if (_activeFilterLabels.isNotEmpty && entries.isEmpty) continue;
        final title = '${_weekdayName(date)}, ${_formatDate(date)}';
        groups[title] = entries;
      } else {
        for (final group in dateGroups.entries) {
          (groups[group.key] ??= []).addAll(group.value);
        }
      }
    }
    return groups;
  }

  DateTime _dateForWeekTitle(String title) {
    for (var day = 0; day < 7; day++) {
      final date = _weekStart.add(Duration(days: day));
      if ('${_weekdayName(date)}, ${_formatDate(date)}' == title) return date;
    }
    return _weekStart;
  }

  String _weekdayName(DateTime date) => const ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][date.weekday % 7];

  void _removeFilter(String label) {
    final filters = _activeFilters;
    if (filters == null) return;
    setState(() {
      _setActiveFilters(filters.copyWith(
        totalTimeRanges: {...filters.totalTimeRanges}..remove(label),
        mealTimeCategories: {...filters.mealTimeCategories}..remove(label),
        mealCategories: {...filters.mealCategories}..remove(label),
        cuisines: {...filters.cuisines}..remove(label),
        days: {...filters.days}..remove(label),
      ));
    });
  }

  Set<String> _cuisinesFor(Recipes recipe) {
    final cuisines = (recipe.cuisine ?? '')
        .split(',')
        .map((cuisine) => cuisine.trim())
        .where((cuisine) => cuisine.isNotEmpty)
        .toSet();
    for (final cuisine in asanCuisines) {
      if (recipe.tags.any(
        (tag) => tag.trim().toLowerCase() == cuisine.toLowerCase(),
      )) {
        cuisines.add(cuisine);
      }
    }
    return cuisines;
  }

  String _primaryCuisine(Recipes recipe) {
    final cuisines = _cuisinesFor(recipe);
    return cuisines.isEmpty ? '' : cuisines.first;
  }

  List<String> _dishTypesFor(MealPlans entry) {
    final plannedType = entry.dishType?.trim();
    if (plannedType?.isNotEmpty == true) return [plannedType!];
    return entry.recipe.dishTypes.isNotEmpty
        ? entry.recipe.dishTypes
        : [if (entry.recipe.mealCategory?.trim().isNotEmpty == true) entry.recipe.mealCategory!.trim()];
  }

  String _primaryDishType(MealPlans entry) {
    final types = _dishTypesFor(entry);
    return types.isEmpty ? '' : types.first;
  }

  String _recipeNameGroupTitle(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return '#';
    final initial = trimmedName[0].toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(initial) ? initial : '#';
  }

  @override
  Widget build(BuildContext context) {
    final sortBy = _sortBy;
    final groups = _groupedEntriesForSelectedDate;
    final weekGroups = _groupedEntriesForSelectedWeek;
    final hasVisibleMealsInWeek = weekGroups.values.any((entries) => entries.isNotEmpty);
    var weekGroupTitles = weekGroups.keys.toList();
    if (sortBy == 'Day') {
      weekGroupTitles.sort((a, b) => _dateForWeekTitle(a).compareTo(_dateForWeekTitle(b)));
      if (!(_activeFilters?.sortAscending ?? true)) {
        weekGroupTitles = weekGroupTitles.reversed.toList();
      }
    } else {
      weekGroupTitles.sort((a, b) {
        final order = sortBy == 'Meal time'
            ? _mealTimeOrder.indexOf(a).compareTo(_mealTimeOrder.indexOf(b))
            : sortBy == 'Total time'
            ? _totalTimeGroupOrder(a).compareTo(_totalTimeGroupOrder(b))
            : a.toLowerCase().compareTo(b.toLowerCase());
        return (_activeFilters?.sortAscending ?? true) ? order : -order;
      });
    }
    final hasMealsOnDate = _entries.any((entry) => entry.isOnDate(_selectedDate));
    final hasMealsInWeek = _entries.any((entry) =>
        !DateUtils.dateOnly(entry.date).isBefore(_weekStart) &&
        !DateUtils.dateOnly(entry.date).isAfter(_weekStart.add(const Duration(days: 6))));
    final groupTitles = groups.keys.toList();
    groupTitles.sort((a, b) {
      final comparison = sortBy == 'Meal time'
          ? _mealTimeOrder.indexOf(a).compareTo(_mealTimeOrder.indexOf(b))
          : sortBy == 'Total time'
          ? _totalTimeGroupOrder(a).compareTo(_totalTimeGroupOrder(b))
          : a.toLowerCase().compareTo(b.toLowerCase());
      return (_activeFilters?.sortAscending ?? true) ? comparison : -comparison;
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AsanAppBar(
        screenTitle: 'Meal Plan',
        icon: const Icon(Symbols.add_rounded),
        onIconPressed: _addMeal,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            40 + AsanSpacing.md + 38 + AsanSpacing.sm +
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
                AsanSegmentedButton(
                  views: _rangeViews,
                  selectedIndex: _selectedRange,
                  onChanged: (index) =>
                      setState(() => _selectedRange = index),
                ),
                const SizedBox(height: AsanSpacing.md),
                Row(
                  children: [
                    FilledIconButton(
                      icon: const Icon(Symbols.add_shopping_cart_rounded, weight: 600),
                      onPressed: _addVisibleMealsToGroceries,
                    ),
                    const SizedBox(width: AsanSpacing.sm),
                    Expanded(
                      child: _DateNavigator(
                        label: _dateLabel,
                        onPrevious: () => _changeDay(_selectedRange == 0 ? -1 : -7),
                        onNext: () => _changeDay(_selectedRange == 0 ? 1 : 7),
                        onLabelTap: () async {
                          final selectedDate = await showDialog<DateTime>(
                            context: context,
                            builder: (dialogContext) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: AsanDatePicker(
                                initialDate: _selectedDate,
                                onDateSelected: (date) =>
                                    Navigator.of(dialogContext).pop(date),
                                onCancel: () =>
                                    Navigator.of(dialogContext).pop(),
                              ),
                            ),
                          );
                          if (selectedDate != null && mounted) {
                            setState(() => _selectedDate = selectedDate);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AsanSpacing.sm),
                    FilledIconButton(
                      icon: const Icon(Symbols.tune_rounded, weight: 600),
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
      body: _selectedRange == 1
          ? !hasVisibleMealsInWeek
              ? AsanEmptyState(
                  icon: hasMealsInWeek && _activeFilterLabels.isNotEmpty
                      ? Symbols.search_off_rounded
                      : Symbols.calendar_meal_2_rounded,
                  title: hasMealsInWeek && _activeFilterLabels.isNotEmpty
                      ? 'No meals match these filters'
                      : 'Nothing planned for $_dateLabel',
                  message: hasMealsInWeek && _activeFilterLabels.isNotEmpty
                      ? 'Try adjusting your filters.'
                      : 'When you add meals, they will show up here.',
                  actionLabel: hasMealsInWeek && _activeFilterLabels.isNotEmpty
                      ? null
                      : 'Add Meal',
                  onAction: hasMealsInWeek && _activeFilterLabels.isNotEmpty
                      ? null
                      : _addMeal,
                )
              : ListView(
              padding: const EdgeInsets.fromLTRB(AsanSpacing.lg, 0, AsanSpacing.lg, AsanSpacing.lg),
              children: [
                for (var i = 0; i < weekGroupTitles.length; i++) ...[
                  if (i > 0) ...[const SizedBox(height: AsanSpacing.md), const AsanDivider(), const SizedBox(height: AsanSpacing.md)],
                  _MealTimeSection(
                    title: weekGroupTitles[i],
                    entries: weekGroups[weekGroupTitles[i]]!,
                    showAdd: sortBy == 'Day' || sortBy == 'Meal time' || sortBy == 'Dish type',
                    showMealTimeTag: true,
                    showEmptyMessage: false,
                    onEdit: _editMeal,
                    onDelete: _deleteMeal,
                    onAdd: () => sortBy == 'Day'
                        ? _addMeal(initialDate: _dateForWeekTitle(weekGroupTitles[i]))
                        : sortBy == 'Meal time'
                            ? _addMeal(mealTime: weekGroupTitles[i])
                            : _addMeal(dishType: weekGroupTitles[i]),
                  ),
                ],
              ],
            )
          : groups.isEmpty
          ? AsanEmptyState(
              icon: hasMealsOnDate && _activeFilterLabels.isNotEmpty
                  ? Symbols.search_off_rounded
                  : Symbols.calendar_meal_2_rounded,
              title: hasMealsOnDate && _activeFilterLabels.isNotEmpty
                  ? 'No meals match these filters'
                  : 'Nothing planned for $_dateLabel',
              message: hasMealsOnDate && _activeFilterLabels.isNotEmpty
                  ? 'Try adjusting your filters.'
                  : 'When you add meals, they will show up here.',
              actionLabel: hasMealsOnDate && _activeFilterLabels.isNotEmpty
                  ? null
                  : 'Add Meal',
              onAction: hasMealsOnDate && _activeFilterLabels.isNotEmpty
                  ? null
                  : _addMeal,
            )
          : ListView(
        padding: const EdgeInsets.fromLTRB(
          AsanSpacing.lg,
          0,
          AsanSpacing.lg,
          AsanSpacing.lg,
        ),
        children: [
          for (var i = 0; i < groupTitles.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AsanSpacing.md),
              const AsanDivider(),
              const SizedBox(height: AsanSpacing.md),
            ],
            _MealTimeSection(
              title: groupTitles[i],
              entries: groups[groupTitles[i]]!,
              onEdit: _editMeal,
              onDelete: _deleteMeal,
              showAdd: sortBy == 'Meal time' || sortBy == 'Dish type',
              onAdd: () => sortBy == 'Meal time'
                  ? _addMeal(mealTime: groupTitles[i])
                  : _addMeal(dishType: groupTitles[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLabelTap;

  const _DateNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onLabelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.sm),
      decoration: BoxDecoration(
        color: AsanColorScheme.container,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            icon: const Icon(
              Symbols.chevron_left_rounded,
              size: 22,
              weight: 600,
            ),
            onPressed: onPrevious,
          ),
          InkWell(
            onTap: onLabelTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AsanTextTheme.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Symbols.arrow_drop_down_rounded,
                    size: 22,
                    color: AsanColorScheme.inactive,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            icon: const Icon(
              Symbols.chevron_right_rounded,
              size: 22,
              weight: 600,
            ),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _SwipeableMealCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SwipeableMealCard({required this.child, required this.onEdit, required this.onDelete});

  @override
  State<_SwipeableMealCard> createState() => _SwipeableMealCardState();
}

class _SwipeableMealCardState extends State<_SwipeableMealCard> {
  static const _actionsWidth = 96.0 + 2 * AsanSpacing.sm;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
          height: 88,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: _revealed ? -_actionsWidth : 0,
                right: _revealed ? 0 : -_actionsWidth,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx < 0 && !_revealed) setState(() => _revealed = true);
                    if (details.delta.dx > 0 && _revealed) setState(() => _revealed = false);
                  },
                  onHorizontalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < -250) setState(() => _revealed = true);
                    if ((details.primaryVelocity ?? 0) > 250) setState(() => _revealed = false);
                  },
                  child: Row(
                    children: [
                      SizedBox(width: constraints.maxWidth, child: widget.child),
                      const SizedBox(width: AsanSpacing.sm),
                      _action(Symbols.edit_rounded, AsanColorScheme.secondary, () {
                        setState(() => _revealed = false);
                        widget.onEdit();
                      }),
                      const SizedBox(width: AsanSpacing.sm),
                      _action(Symbols.delete_rounded,  AsanColorScheme.error, () {
                        setState(() => _revealed = false);
                        widget.onDelete();
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _action(IconData icon, Color color, VoidCallback onPressed) =>
      SizedBox(
        width: 48,
        height: 88,
        child: Center(
          child: TonalIconButton.square(
            color: color,
            icon: Icon(icon, size: 24, weight: 600),
            size: 48,
            borderRadius: BorderRadius.circular(8),
            onPressed: onPressed,
          ),
        ),
      );
}

class _MealTimeSection extends StatelessWidget {
  final String title;
  final List<MealPlans> entries;
  final VoidCallback onAdd;
  final bool showAdd;
  final bool showMealTimeTag;
  final bool showEmptyMessage;
  final ValueChanged<MealPlans> onEdit;
  final ValueChanged<MealPlans> onDelete;

  const _MealTimeSection({required this.title, required this.entries, required this.onAdd, required this.showAdd, required this.onEdit, required this.onDelete, this.showMealTimeTag = false, this.showEmptyMessage = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AsanTextTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showAdd) TonalIconButton.square(
              color: AsanColorScheme.secondary,
              icon: const Icon(Symbols.add_rounded, weight: 500, size: 16),
              size: 22,
              borderRadius: BorderRadius.circular(4),
              onPressed: onAdd,
            ),
          ],
        ),
        if (entries.isNotEmpty || showEmptyMessage)
          const SizedBox(height: AsanSpacing.md),
        if (entries.isEmpty && showEmptyMessage)
          Padding(
            padding: const EdgeInsets.only(bottom: AsanSpacing.sm),
            child: Text(
              'Nothing planned for $title yet.',
              style: AsanTextTheme.bodyMedium.copyWith(
                color: AsanColorScheme.inactive,
              ),
            ),
          )
        else
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: AsanSpacing.sm),
            _SwipeableMealCard(
              onEdit: () => onEdit(entries[i]),
              onDelete: () => onDelete(entries[i]),
              child: MealCard(
              recipeName: entries[i].recipe.name,
              imageBytes: entries[i].recipe.imageBytes,
              imageUrl: entries[i].recipe.imageUrl,
              mealCategory: entries[i].dishType?.trim().isNotEmpty == true
                  ? entries[i].dishType!
                  : entries[i].recipe.mealCategory?.trim().isNotEmpty == true
                  ? entries[i].recipe.mealCategory!
                  : '-',
              mealTime: entries[i].mealTime,
              showMealTimeTag: showMealTimeTag,
              totalTime: entries[i].recipe.formattedTotalTime,
              servings: entries[i].servings,
              onTap: () {
                final recipe = entries[i].recipe;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailsScreen(
                      recipe: recipe,
                      servingsOverride: entries[i].servings,
                      imageUrl: recipe.imageUrl,
                      ingredients: recipe.ingredients,
                      ingredientAmounts: recipe.ingredientAmounts,
                      ingredientUnits: recipe.ingredientUnits,
                      ingredientNotes: recipe.ingredientNotes,
                      instructions: recipe.instructions,
                    ),
                  ),
                );
              },
              ),
            ),
          ],
      ],
    );
  }
}

class _RecipePickerField extends StatelessWidget {
  final Recipes? selectedRecipe;
  final List<Recipes> recipes;
  final bool hasError;
  final ValueChanged<Recipes> onSelected;
  final Future<bool> Function(List<GroceryItem>)? onAddToGroceries;
  final VoidCallback? onViewGroceries;

  const _RecipePickerField({
    required this.selectedRecipe,
    required this.recipes,
    required this.hasError,
    required this.onSelected,
    this.onAddToGroceries,
    this.onViewGroceries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Recipe',
              style: AsanTextTheme.labelSmall.copyWith(
                color: AsanColorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AsanSpacing.xs),
            Text(
              '(Required)',
              style: AsanTextTheme.labelSmall.copyWith(
                color: AsanColorScheme.inactive,
              ),
            ),
          ],
        ),
        const SizedBox(height: AsanSpacing.sm),
        Material(
          color: hasError ? AsanColorScheme.surface : AsanColorScheme.container,
          borderRadius: BorderRadius.circular(AsanSpacing.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AsanSpacing.sm),
            onTap: () async {
              final recipe = await showModalBottomSheet<Recipes>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => FractionallySizedBox(
                  heightFactor: 0.92,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Navigator(
                      onGenerateRoute: (settings) => MaterialPageRoute<void>(
                        settings: settings,
                        builder: (_) => RecipesScreen(
                          incomingRecipes: recipes,
                          onAddToGroceries: onAddToGroceries == null
                              ? null
                              : (items) async {
                                  await onAddToGroceries!(items);
                                },
                          onViewGroceries: onViewGroceries == null
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  Navigator.of(context).pop();
                                  onViewGroceries!();
                                },
                          onRecipeSelected: (recipe) =>
                              Navigator.of(sheetContext).pop(recipe),
                          onPickerBack: () => Navigator.of(sheetContext).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              if (recipe != null) onSelected(recipe);
            },
            child: SizedBox(
              height: 38,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedRecipe?.name ?? 'Select a recipe',
                        style: AsanTextTheme.bodyMedium.copyWith(
                          color: selectedRecipe == null
                              ? AsanColorScheme.inactive
                              : AsanColorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Symbols.arrow_drop_down_rounded, size: 22, color: AsanColorScheme.inactive),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AsanSpacing.xs),
          Text(
            'Select a recipe.',
            style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _MealPlanForm extends StatefulWidget {
  final List<Recipes> recipes;
  final DateTime initialDate;
  final String? initialMealTime;
  final String? initialDishType;
  final Recipes? initialRecipe;
  final int? initialServings;
  final bool isEditing;
  final Future<bool> Function(List<GroceryItem>)? onAddToGroceries;
  final VoidCallback? onViewGroceries;

  const _MealPlanForm({
    super.key,
    required this.recipes,
    required this.initialDate,
    this.initialMealTime,
    this.initialDishType,
    this.initialRecipe,
    this.initialServings,
    this.isEditing = false,
    this.onAddToGroceries,
    this.onViewGroceries,
  });

  @override
  State<_MealPlanForm> createState() => _MealPlanFormState();
}

class _MealPlanFormState extends State<_MealPlanForm> {
  final _servingsController = TextEditingController();
  Recipes? _recipe;
  late final Set<DateTime> _dates;
  late final Set<String> _mealTimes;
  String? _dishType;
  bool _hasError = false;
  bool _servingsHasError = false;

  bool get hasChanges {
    if (widget.isEditing) {
      return !identical(_recipe, widget.initialRecipe) ||
          _dates.length != 1 ||
          !_dates.contains(DateUtils.dateOnly(widget.initialDate)) ||
          _mealTimes.length != 1 ||
          !_mealTimes.contains(widget.initialMealTime) ||
          _dishType != widget.initialDishType ||
          _servingsController.text != widget.initialServings.toString();
    }
    return _recipe != null ||
        _dates.length != 1 ||
        !_dates.contains(DateUtils.dateOnly(widget.initialDate)) ||
        _mealTimes.length != (widget.initialMealTime == null ? 0 : 1) ||
        (widget.initialMealTime != null && !_mealTimes.contains(widget.initialMealTime)) ||
        _dishType != widget.initialDishType ||
        _servingsController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _dates = {DateUtils.dateOnly(widget.initialDate)};
    _mealTimes = {if (widget.initialMealTime != null) widget.initialMealTime!};
    _dishType = widget.initialDishType;
    _recipe = widget.initialRecipe;
    if (widget.initialServings != null) {
      _servingsController.text = widget.initialServings.toString();
    }
  }

  @override
  void dispose() {
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dishTypes = uniqueStrings([...asanDishTypes, ...?_recipe?.dishTypes])
      ..removeWhere((type) =>
          type.toLowerCase() == 'breakfast' || type.toLowerCase() == 'brunch');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AsanSpacing.lg,
        AsanSpacing.lg,
        AsanSpacing.lg,
        AsanSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          _RecipePickerField(
            selectedRecipe: _recipe,
            recipes: widget.recipes,
            hasError: _hasError && _recipe == null,
            onAddToGroceries: widget.onAddToGroceries,
            onViewGroceries: widget.onViewGroceries,
            onSelected: (recipe) => setState(() {
              _recipe = recipe;
              _dishType = null;
              _servingsController.clear();
              _servingsHasError = false;
            }),
          ),
          const SizedBox(height: AsanSpacing.md),
          Row(children: [
            Text('Date', style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.secondary, fontWeight: FontWeight.bold)),
            const SizedBox(width: AsanSpacing.xs),
            Text('(Required)', style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.inactive)),
          ]),
          const SizedBox(height: AsanSpacing.sm),
          AsanDatePicker(
            variant: AsanDatePickerVariant.field,
            initialDate: _dates.last,
            selectedDates: _dates,
            onDateToggled: (value) => setState(() {
              final date = DateUtils.dateOnly(value);
              if (!_dates.add(date) && _dates.length > 1) _dates.remove(date);
            }),
          ),
          const SizedBox(height: AsanSpacing.md),
          Row(children: [
            Text('Meal Time', style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.secondary, fontWeight: FontWeight.bold)),
            const SizedBox(width: AsanSpacing.xs),
            Text('(Required)', style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.inactive)),
          ]),
          const SizedBox(height: AsanSpacing.sm),
          Wrap(
            spacing: AsanSpacing.sm,
            runSpacing: AsanSpacing.sm,
            children: asanMealTimes.map((mealTime) {
              final selected = _mealTimes.contains(mealTime);
              return AsanFilterChip(
                label: mealTime,
                isSelected: selected,
                onPressed: () => setState(
                  () => selected ? _mealTimes.remove(mealTime) : _mealTimes.add(mealTime),
                ),
              );
            }).toList(),
          ),
          if (_hasError && _mealTimes.isEmpty) ...[
            const SizedBox(height: AsanSpacing.xs),
            Text(
              'Select a meal time.',
              style: AsanTextTheme.labelSmall.copyWith(
                color: AsanColorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AsanSpacing.md),
          AsanDropdownMenu(
            label: 'Dish Type', items: dishTypes.toList(), value: _dishType,
            hintText: 'Select a dish type', required: true,
            hasError: _hasError && _dishType == null, errorText: 'Select a dish type.',
            onChanged: (value) => setState(() => _dishType = value),
          ),
          const SizedBox (height: AsanSpacing.md),
          AsanTextField(
            label: 'Servings',
            hintText: 'Enter number of servings',
            required: true,
            keyboardType: TextInputType.number,
            hasError: _servingsHasError,
            errorText: _servingsController.text.trim().isEmpty
                ? 'Serving size is required.'
                : 'Enter a whole number of at least 1.',
            controller: _servingsController,
            onChanged: (_) => setState(() => _servingsHasError = false),
          ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AsanSpacing.md),
          PrimaryButton(
            label: widget.isEditing ? 'Save Changes' : 'Add to Plan',
            height: 38,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    final servingsText = _servingsController.text.trim();
    final servings = servingsText.isEmpty ? null : int.tryParse(servingsText);
    setState(() {
      _hasError = true;
      _servingsHasError = servingsText.isEmpty || servings == null || servings <= 0;
    });
    if (_recipe == null || _mealTimes.isEmpty || _dishType == null || servings == null || servings <= 0 || _servingsHasError) return;
    Navigator.pop(
      context,
      [for (final date in _dates) for (final mealTime in _mealTimes) MealPlans(
        date: date,
        mealTime: mealTime,
        recipe: _recipe!,
        dishType: _dishType,
        servingsOverride: servings,
      )],
    );
  }
}
