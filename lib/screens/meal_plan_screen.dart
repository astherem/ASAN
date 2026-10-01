import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/meal_plans.dart';
import 'package:asan/models/recipes.dart';
import 'package:asan/models/filter_selection.dart';
import 'package:asan/screens/recipes_screen.dart';
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

  const MealPlanScreen({super.key, this.incomingEntries = const [], this.recipes = const []});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  static const _rangeViews = ['Day', 'Week'];
  static const _mealTimeOrder = ['Breakfast', 'Lunch', 'Dinner'];
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
  int _selectedRange = 0;
  DateTime _selectedDate = DateTime.now();
  AsanFilterSelection? _activeFilters;

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
        ),
      ),
    );
    if (selection != null && mounted) setState(() => _activeFilters = selection);
  }

  Future<void> _addMeal({String? mealTime}) async {
    if (widget.recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add or save a recipe before planning a meal.')),
      );
      return;
    }
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
              recipes: widget.recipes,
              initialDate: _selectedDate,
              initialMealTime: mealTime,
            ),
          ),
        ),
      ),
    );
    if (entries != null && mounted) setState(() => _entries.addAll(entries));
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
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  String _formatDate(DateTime date) =>
      '${_months[date.month - 1].substring(0, 3)} ${date.day}';

  String get _dateLabel {
    if (_selectedRange == 0) return _formattedDate;
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return '${_formatDate(_weekStart)} - ${_formatDate(weekEnd)}';
  }

  Map<String, List<MealPlans>> get _groupedEntriesForSelectedDate {
    final groups = <String, List<MealPlans>>{};
    final filters = _activeFilters;
    for (final entry in _entries) {
      if (!entry.isOnDate(_selectedDate)) continue;
      if (filters?.mealTimeCategories.isNotEmpty ?? false) {
        if (!filters!.mealTimeCategories.contains(entry.mealTime)) continue;
      }
      if (filters?.mealCategories.isNotEmpty ?? false) {
        if (!filters!.mealCategories.contains(entry.recipe.mealCategory)) continue;
      }
      (groups[entry.mealTime] ??= []).add(entry);
    }
    for (final entries in groups.values) {
      entries.sort((a, b) {
        final comparison = switch (filters?.sortBy) {
          'Recipe name' => a.recipe.name.toLowerCase().compareTo(b.recipe.name.toLowerCase()),
          'Meal category' => (a.recipe.mealCategory ?? '').compareTo(b.recipe.mealCategory ?? ''),
          _ => 0,
        };
        return (filters?.sortAscending ?? true) ? comparison : -comparison;
      });
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedEntriesForSelectedDate;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AsanAppBar(
        screenTitle: 'Meal Plan',
        icon: const Icon(Symbols.add_rounded),
        onIconPressed: _addMeal,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            38 + AsanSpacing.sm + 40 + AsanSpacing.md + AsanSpacing.lg,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.sm, bottom: AsanSpacing.lg),
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
                      onPressed: () {
                        // TODO: add every meal on _selectedDate to
                        // groceries once that flow exists.
                      },
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
                      onPressed: _showFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: groups.isEmpty
          ? AsanEmptyState(
              icon: Symbols.calendar_meal_2_rounded,
              title: 'Nothing planned for $_dateLabel',
              message: 'When you add meals, they will show up here.',
              actionLabel: 'Add Meal',
              onAction: _addMeal,
            )
          : ListView(
        padding: const EdgeInsets.fromLTRB(
          AsanSpacing.lg,
          0,
          AsanSpacing.lg,
          AsanSpacing.md,
        ),
        children: [
          for (var i = 0; i < _mealTimeOrder.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AsanSpacing.md),
              const AsanDivider(),
              const SizedBox(height: AsanSpacing.md),
            ],
            _MealTimeSection(
              title: _mealTimeOrder[i],
              entries: groups[_mealTimeOrder[i]] ?? const [],
              onAdd: () => _addMeal(mealTime: _mealTimeOrder[i]),
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

class _MealTimeSection extends StatelessWidget {
  final String title;
  final List<MealPlans> entries;
  final VoidCallback onAdd;

  const _MealTimeSection({required this.title, required this.entries, required this.onAdd});

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
            TonalIconButton.square(
              color: AsanColorScheme.secondary,
              icon: const Icon(Symbols.add_rounded, weight: 600, size: 16),
              size: 22,
              borderRadius: BorderRadius.circular(4),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: AsanSpacing.md),
        if (entries.isEmpty)
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
            MealCard(
              recipeName: entries[i].recipe.name,
              mealCategory: entries[i].dishType?.trim().isNotEmpty == true
                  ? entries[i].dishType!
                  : entries[i].recipe.mealCategory?.trim().isNotEmpty == true
                  ? entries[i].recipe.mealCategory!
                  : '-',
              totalTime: entries[i].recipe.formattedTotalTime,
              servings: entries[i].servings,
              onTap: () {
                // TODO: navigate to RecipeDetailsScreen for entries[i].recipe.
              },
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

  const _RecipePickerField({
    required this.selectedRecipe,
    required this.recipes,
    required this.hasError,
    required this.onSelected,
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
                    child: RecipesScreen(
                      incomingRecipes: recipes,
                      onRecipeSelected: (recipe) =>
                          Navigator.of(sheetContext).pop(recipe),
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

  const _MealPlanForm({
    super.key,
    required this.recipes,
    required this.initialDate,
    this.initialMealTime,
  });

  @override
  State<_MealPlanForm> createState() => _MealPlanFormState();
}

class _MealPlanFormState extends State<_MealPlanForm> {
  final _servingsController = TextEditingController();
  Recipes? _recipe;
  late final Set<DateTime> _dates;
  late String? _mealTime;
  String? _dishType;
  bool _hasError = false;
  bool _servingsHasError = false;

  bool get hasChanges => _recipe != null ||
      _dates.length != 1 || !_dates.contains(DateUtils.dateOnly(widget.initialDate)) ||
      _mealTime != widget.initialMealTime ||
      _dishType != null ||
      _servingsController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _dates = {DateUtils.dateOnly(widget.initialDate)};
    _mealTime = widget.initialMealTime;
  }

  @override
  void dispose() {
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dishTypes = <String>{...asanDishTypes, ...?_recipe?.dishTypes};
    return Padding(
      padding: const EdgeInsets.all(AsanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecipePickerField(
            selectedRecipe: _recipe,
            recipes: widget.recipes,
            hasError: _hasError && _recipe == null,
            onSelected: (recipe) => setState(() {
              _recipe = recipe;
              _dishType = null;
              _servingsController.text = '${recipe.servings > 0 ? recipe.servings : 1}';
              _servingsHasError = false;
            }),
          ),
          const SizedBox(height: AsanSpacing.md),
          Text('Dates', style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.secondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: AsanSpacing.sm),
          Wrap(spacing: AsanSpacing.sm, runSpacing: AsanSpacing.sm, children: [
            for (final date in _dates)
              InputChip(label: Text('${date.month}/${date.day}/${date.year}'), onDeleted: _dates.length > 1 ? () => setState(() => _dates.remove(date)) : null),
            ActionChip(label: const Text('Add date'), onPressed: _addDate),
          ]),
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
              final selected = _mealTime == mealTime;
              return AsanFilterChip(
                label: mealTime,
                isSelected: selected,
                onPressed: () => setState(
                  () => _mealTime = selected ? null : mealTime,
                ),
              );
            }).toList(),
          ),
          if (_hasError && _mealTime == null) ...[
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
          const Spacer(),
          PrimaryButton(
            label: 'Add to Plan',
            height: 38,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _addDate() async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: AsanDatePicker(
          initialDate: _dates.last,
          onDateSelected: (value) => Navigator.of(dialogContext).pop(DateUtils.dateOnly(value)),
          onCancel: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
    if (date != null && mounted) setState(() => _dates.add(date));
  }

  void _submit() {
    final servings = int.tryParse(_servingsController.text.trim());
    setState(() {
      _hasError = true;
      _servingsHasError = servings == null || servings <= 0;
    });
    if (_recipe == null || _mealTime == null || _dishType == null || _servingsHasError) return;
    Navigator.pop(
      context,
      [for (final date in _dates) MealPlans(
        date: date,
        mealTime: _mealTime!,
        recipe: _recipe!,
        dishType: _dishType,
        servingsOverride: servings,
      )],
    );
  }
}
