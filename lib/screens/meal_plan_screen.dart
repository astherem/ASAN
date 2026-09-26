import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/meal_plans.dart';
import 'package:asan/models/filter_selection.dart';
import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class MealPlanScreen extends StatefulWidget {
  final List<MealPlans> incomingEntries;

  const MealPlanScreen({super.key, this.incomingEntries = const []});

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
        onIconPressed: () {
          // TODO: open add-to-meal-plan flow (pick a recipe + meal time
          // for _selectedDate, then setState(() => _entries.add(...))).
        },
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
              onAction: () {
                // TODO: open the add-to-meal-plan flow for _selectedDate.
              },
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

  const _MealTimeSection({required this.title, required this.entries});

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
              onPressed: () {
                // TODO: Add a new meal plan for this meal time.
              },
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
              mealCategory: entries[i].recipe.mealCategory?.trim().isNotEmpty == true
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
