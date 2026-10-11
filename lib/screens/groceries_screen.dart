import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';
import 'package:asan/models/grocery_item.dart';
import 'package:asan/models/pantry_item.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';
import 'package:uuid/uuid.dart';

class GroceriesScreen extends StatefulWidget {
  final List<GroceryItem> initialItems;
  final ValueChanged<List<GroceryItem>>? onItemsChanged;
  final ValueChanged<int>? onItemCountChanged;
  final ValueChanged<PantryItem>? onItemChecked;

  const GroceriesScreen({
    super.key,
    this.initialItems = const [],
    this.onItemsChanged,
    this.onItemCountChanged,
    this.onItemChecked,
  });

  @override
  State<GroceriesScreen> createState() => GroceriesScreenState();
}

class GroceriesScreenState extends State<GroceriesScreen> {
  final List<GroceryItem> _items = [];
  String _searchQuery = '';
  AsanFilterSelection? _activeFilters;
  late final ScrollController _filterScrollController;

  void _notifyItemsChanged() =>
      widget.onItemsChanged?.call(List.unmodifiable(_items));

  Future<bool> addItems(List<GroceryItem> items) async {
    if (items.isEmpty || !mounted) return false;
    String ingredientKey(GroceryItem item) =>
        '${item.name.trim().toLowerCase()}|${item.aisle?.trim().toLowerCase() ?? ''}';

    final seenIngredients = _items.map(ingredientKey).toSet();
    final duplicates = <GroceryItem>[];
    for (final item in items) {
      if (!seenIngredients.add(ingredientKey(item))) duplicates.add(item);
    }
    if (duplicates.isNotEmpty) {
      final names = duplicates.map((item) => item.name).toSet().join(', ');
      final addAnyway = await AsanAlertDialog.show(
        context,
        title: 'Already in Groceries',
        content:
            'You already have $names in Groceries. Add them again? Their quantities will be combined with the existing items.',
        cancelText: 'Cancel',
        destructiveText: 'Add',
        primaryAction: true,
      );
      if (addAnyway != true || !mounted) return false;
    }

    setState(() {
      for (final incoming in items) {
        final index = _items.indexWhere(
          (item) => ingredientKey(item) == ingredientKey(incoming),
        );
        if (index == -1) {
          _items.add(incoming);
          continue;
        }
        final current = _items[index];
        final sameUnit = current.unit.trim().toLowerCase() ==
            incoming.unit.trim().toLowerCase();
        final currentAmount = _parseQuantity(current.amount);
        final incomingAmount = _parseQuantity(incoming.amount);
        final amount =
            sameUnit && currentAmount != null && incomingAmount != null
            ? _formatQuantity(currentAmount + incomingAmount)
            : [
                current.amount,
                incoming.amount,
              ].where((value) => value.trim().isNotEmpty).join(' + ');
        _items[index] = GroceryItem(
          name: current.name,
          amount: amount,
          unit: current.unit.isNotEmpty ? current.unit : incoming.unit,
          aisle: current.aisle,
          notes: _mergeNotes(current.notes, incoming.notes),
          purchaseDate: current.purchaseDate,
        );
      }
    });
    widget.onItemCountChanged?.call(_items.length);
    _notifyItemsChanged();
    return true;
  }

  String _mergeNotes(String first, String second) {
    final notes = <String>[];
    final seen = <String>{};
    for (final value in [first, second]) {
      final note = value.trim();
      if (note.isNotEmpty && seen.add(note.toLowerCase())) notes.add(note);
    }
    return notes.join('; ');
  }

  double? _parseQuantity(String value) {
    final normalized = value.trim();
    final direct = double.tryParse(normalized);
    if (direct != null) return direct;

    // Recipe amounts commonly use fractions such as "1/2" or "1 1/2".
    final parts = normalized.split(RegExp(r'\s+'));
    var total = 0.0;
    var hasValue = false;
    for (final part in parts) {
      final fraction = part.split('/');
      if (fraction.length == 2) {
        final numerator = double.tryParse(fraction[0]);
        final denominator = double.tryParse(fraction[1]);
        if (numerator == null || denominator == null || denominator == 0) {
          return null;
        }
        total += numerator / denominator;
      } else {
        final number = double.tryParse(part);
        if (number == null) return null;
        total += number;
      }
      hasValue = true;
    }
    return hasValue ? total : null;
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();

    final whole = value.floor();
    final fractional = value - whole;
    const maxDenominator = 16;
    var numerator = 0;
    var denominator = 1;
    var smallestError = double.infinity;
    for (var candidateDenominator = 2;
        candidateDenominator <= maxDenominator;
        candidateDenominator++) {
      final candidateNumerator =
          (fractional * candidateDenominator).round();
      final error =
          (fractional - candidateNumerator / candidateDenominator).abs();
      if (error < smallestError) {
        numerator = candidateNumerator;
        denominator = candidateDenominator;
        smallestError = error;
      }
    }

    if (numerator == denominator) return (whole + 1).toString();
    if (numerator == 0) return whole.toString();
    final divisor = _greatestCommonDivisor(numerator, denominator);
    final fraction = '${numerator ~/ divisor}/${denominator ~/ divisor}';
    return whole == 0 ? fraction : '$whole $fraction';
  }

  int _greatestCommonDivisor(int first, int second) {
    var a = first;
    var b = second;
    while (b != 0) {
      final remainder = a % b;
      a = b;
      b = remainder;
    }
    return a;
  }

  @override
  void initState() {
    super.initState();
    _filterScrollController = ScrollController();
    _items.addAll(widget.initialItems);
    _notifyItemsChanged();
  }

  @override
  void didUpdateWidget(covariant GroceriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.initialItems, widget.initialItems)) return;

    // The parent owns the persisted/synced collection and can replace it after
    // this screen has already been created (for example, after cloud sync).
    _items
      ..clear()
      ..addAll(widget.initialItems);
    final itemCount = _items.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onItemCountChanged?.call(itemCount);
    });
    _notifyItemsChanged();
  }

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
  }

  List<String> get _activeFilterLabels => [
    ...?_activeFilters?.purchaseStatuses,
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
          menuType: AsanFilterMenuType.groceries,
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
        foodGroups: {...filters.foodGroups}..remove(label),
      );
    });
  }

  Future<void> _showAddGroceryItemDialog(BuildContext context) async {
    final formKey = GlobalKey<_AddGroceryItemFormState>();

    final item = await showDialog<GroceryItem>(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: FullScreenDialogHeader(
                screenTitle: 'Add Grocery Item',
                bottomPadding: AsanSpacing.xs,
                onBackPressed: () async {
                  final formState = formKey.currentState;
                  if (formState == null || !formState.hasChanges) {
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }
                  final shouldDiscard = await AsanAlertDialog.show(
                    context,
                    title: 'Discard Changes?',
                    content:
                        'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
                    cancelText: 'Cancel',
                    destructiveText: 'Discard',
                  );
                  if (shouldDiscard == true && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              body: AddGroceryItemForm(key: formKey),
            ),
          ),
        );
      },
    );
    if (item != null && mounted) {
      setState(() => _items.add(item));
      widget.onItemCountChanged?.call(_items.length);
      _notifyItemsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AsanAppBar(
        screenTitle: 'Groceries',
        icon: const Icon(Symbols.add_rounded),
        onIconPressed: () {
          _showAddGroceryItemDialog(context);
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
                        hintText: 'Search groceries...',
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
      body:
          _groupedItems.isEmpty &&
              (_searchQuery.trim().isNotEmpty || _activeFilterLabels.isNotEmpty)
          ? AsanEmptyState(
              icon: Symbols.search_off_rounded,
              title: _searchQuery.trim().isNotEmpty
                  ? 'No grocery items found'
                  : 'No grocery items match these filters',
              message: _searchQuery.trim().isNotEmpty
                  ? 'No grocery items match "${_searchQuery.trim()}".'
                  : 'Try removing or changing a filter.',
            )
          : _items.isEmpty
          ? AsanEmptyState(
              icon: Symbols.receipt_long_rounded,
              title: 'Your grocery list is empty',
              message: 'When you add grocery items, they will show up here.',
              actionLabel: 'Add Grocery Item',
              onAction: () => _showAddGroceryItemDialog(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
              itemCount: _groupedItems.length,
              itemBuilder: (context, index) {
                final group = _groupedItems[index];
                return AsanExpansionTile(
                  key: ValueKey(group.key),
                  title: group.key,
                  itemCount: group.value.length,
                  children: [
                    for (var i = 0; i < group.value.length; i++) ...[
                      const SizedBox(height: AsanSpacing.xs),
                      if (i > 0) const SizedBox(height: AsanSpacing.xs),
                      _buildListTile(group.value[i]),
                    ],
                  ],
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
    );
  }

  List<MapEntry<String, List<GroceryItem>>> get _groupedItems {
    final query = _searchQuery.trim().toLowerCase();
    final filters = _activeFilters;
    final items = _items
        .where(
          (item) =>
              (query.isEmpty || item.name.toLowerCase().contains(query)) &&
              (filters?.foodGroups.isEmpty ?? true
                  ? true
                  : filters!.foodGroups.contains(item.aisle)),
        )
        .toList();
    final sortBy = filters?.sortBy ?? 'Aisle';
    items.sort((first, second) {
      final result = sortBy == 'Item name'
          ? first.name.toLowerCase().compareTo(second.name.toLowerCase())
          : (first.aisle ?? 'Uncategorized').toLowerCase().compareTo(
              (second.aisle ?? 'Uncategorized').toLowerCase(),
            );
      return (filters?.sortAscending ?? true) ? result : -result;
    });

    final groups = <String, List<GroceryItem>>{};
    for (final item in items) {
      final label = sortBy == 'Item name'
          ? (item.name.trim().isEmpty ? '#' : item.name.trim()[0].toUpperCase())
          : _formatGroupTitle(item.aisle ?? 'Uncategorized');
      (groups[label] ??= []).add(item);
    }
    return groups.entries.toList();
  }

  String _formatGroupTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  Widget _buildListTile(GroceryItem item) => AsanSwipeableActions(
    onEdit: () => _showEditItemDialog(item),
    onDelete: () => _deleteItem(item),
    child: AsanListTile(
    key: ValueKey(item),
    itemName: item.name,
    amount: item.amount,
    unit: item.unit,
    category: _activeFilters?.sortBy == 'Item name'
        ? item.aisle ?? 'Uncategorized'
        : '',
    purchasedDate: '',
    notes: item.notes,
    onChanged: (checked) {
      if (checked) _completeItem(item);
    },
    onTap: () => _showEditItemDialog(item),
    ),
  );

  Future<void> _deleteItem(GroceryItem item) async {
    final confirmed = await AsanAlertDialog.show(
      context,
      title: 'Delete Grocery Item?',
      content: 'This item will be permanently removed from your groceries. Are you sure you want to delete it?',
      cancelText: 'Cancel',
      destructiveText: 'Delete Item',
    );
    if (confirmed == true && mounted) {
      setState(() => _items.remove(item));
      widget.onItemCountChanged?.call(_items.length);
      _notifyItemsChanged();
    }
  }

  void _completeItem(GroceryItem item) {
    final checkedDate = DateTime.now();
    setState(() => _items.remove(item));
    widget.onItemCountChanged?.call(_items.length);
    _notifyItemsChanged();
    widget.onItemChecked?.call(
      PantryItem(
        id: const Uuid().v4(),
        updatedAt: DateTime.now().toUtc(),
        name: item.name,
        amount: item.amount,
        unit: item.unit,
        aisle: item.aisle,
        purchaseDate: checkedDate,
        notes: item.notes,
      ),
    );
    AsanSnackBar.show(
      context,
      message: '${item.name} added to Pantry',
      actionLabel: 'Undo',
      onAction: () {
        setState(() => _items.add(item));
        widget.onItemCountChanged?.call(_items.length);
        _notifyItemsChanged();
      },
    );
  }

  Future<void> _showEditItemDialog(GroceryItem item) async {
    final formKey = GlobalKey<_AddGroceryItemFormState>();
    final updatedItem = await showDialog<GroceryItem>(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: FullScreenDialogHeader(
              screenTitle: 'Edit ${item.name}',
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                icon: const Icon(
                  Symbols.delete_rounded,
                  fill: 1,
                  size: 28,
                  color: AsanColorScheme.error,
                ),
                onPressed: () async {
                  final confirmed = await AsanAlertDialog.show(
                    context,
                    title: 'Delete Grocery Item?',
                    content:
                        'This item will be permanently removed from your groceries. Are you sure you want to delete it?',
                    cancelText: 'Cancel',
                    destructiveText: 'Delete Item',
                  );
                  if (confirmed == true && context.mounted) {
                    Navigator.pop(context);
                    setState(() => _items.remove(item));
                    widget.onItemCountChanged?.call(_items.length);
                    _notifyItemsChanged();
                  }
                },
              ),
              onBackPressed: () async {
                final formState = formKey.currentState;
                if (formState == null || !formState.hasChanges) {
                  if (context.mounted) Navigator.pop(context);
                  return;
                }
                final shouldDiscard = await AsanAlertDialog.show(
                  context,
                  title: 'Discard Changes?',
                  content:
                      'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
                  cancelText: 'Cancel',
                  destructiveText: 'Discard',
                );
                if (shouldDiscard == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            body: AddGroceryItemForm(
              key: formKey,
              initialItem: item,
              submitLabel: 'Save',
            ),
          ),
        ),
      ),
    );
    if (updatedItem != null && mounted) {
      final index = _items.indexOf(item);
      if (index != -1) {
        final duplicate = _items.asMap().entries.any((entry) =>
            entry.key != index &&
            entry.value.name.trim().toLowerCase() ==
                updatedItem.name.trim().toLowerCase() &&
            (entry.value.aisle ?? '').trim().toLowerCase() ==
                (updatedItem.aisle ?? '').trim().toLowerCase());
        if (duplicate) {
          AsanSnackBar.show(context, message: 'An item with this name and aisle already exists.');
          return;
        }
        setState(() => _items[index] = updatedItem);
        _notifyItemsChanged();
      }
    }
  }
}

class AddGroceryItemForm extends StatefulWidget {
  final GroceryItem? initialItem;
  final String submitLabel;

  const AddGroceryItemForm({
    super.key,
    this.initialItem,
    this.submitLabel = 'Add to Groceries',
  });

  @override
  State<AddGroceryItemForm> createState() => _AddGroceryItemFormState();
}

class _AddGroceryItemFormState extends State<AddGroceryItemForm> {
  late final TextEditingController _itemController;
  late final TextEditingController _amountController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;
  String? _aisle;
  bool _itemHasError = false;
  bool _aisleHasError = false;

  bool get hasChanges => widget.initialItem == null
      ? _itemController.text.isNotEmpty ||
            _amountController.text.isNotEmpty ||
            _unitController.text.isNotEmpty ||
            _notesController.text.isNotEmpty ||
            _aisle != null
      : _itemController.text.trim() != widget.initialItem!.name ||
            _amountController.text.trim() != widget.initialItem!.amount ||
            _unitController.text.trim() != widget.initialItem!.unit ||
            _notesController.text.trim() != widget.initialItem!.notes ||
            _aisle != widget.initialItem!.aisle;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _itemController = TextEditingController(text: item?.name);
    _amountController = TextEditingController(text: item?.amount);
    _unitController = TextEditingController(text: item?.unit);
    _notesController = TextEditingController(text: item?.notes);
    _aisle = item?.aisle;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AsanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AsanTextField(
            label: 'Item Name',
            hintText: 'Enter item name',
            controller: _itemController,
            hasError: _itemHasError,
            errorText: 'Item name is required.',
            required: true,
            onChanged: (_) {
              if (_itemHasError) setState(() => _itemHasError = false);
            },
          ),
          const SizedBox(height: AsanSpacing.md),
          AsanDropdownMenu(
            label: 'Aisle',
            items: asanAisles,
            value: _aisle,
            hintText: 'Select an aisle',
            hasError: _aisleHasError,
            errorText: 'Select an aisle.',
            required: true,
            onChanged: (value) {
              setState(() {
                _aisle = value;
                _aisleHasError = false;
              });
            },
          ),
          const SizedBox(height: AsanSpacing.md),
          Row(
            children: [
              Expanded(
                child: AsanTextField(
                  label: 'Amount',
                  hintText: 'Enter amount',
                  controller: _amountController,
                ),
              ),
              const SizedBox(width: AsanSpacing.md),
              Expanded(
                child: AsanTextField(
                  label: 'Unit',
                  hintText: 'Enter unit',
                  controller: _unitController,
                ),
              ),
            ],
          ),
          const SizedBox(height: AsanSpacing.md),
          AsanTextField(
            label: 'Notes',
            hintText: 'Add notes',
            controller: _notesController,
          ),
          const Spacer(),
          PrimaryButton(
            label: widget.submitLabel,
            height: 38,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _itemController.text.trim();
    final hasAisle = _aisle != null;
    setState(() {
      _itemHasError = name.isEmpty;
      _aisleHasError = !hasAisle;
    });
    if (name.isEmpty || !hasAisle) return;

    Navigator.pop(
      context,
      GroceryItem(
        name: name,
        amount: _amountController.text.trim(),
        unit: _unitController.text.trim(),
        aisle: _aisle,
        notes: _notesController.text.trim(),
      ),
    );
  }
}
