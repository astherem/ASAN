import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';
import 'package:asan/models/grocery_item.dart';
import 'package:asan/models/pantry_item.dart';
import 'package:asan/models/filter_selection.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class GroceriesScreen extends StatefulWidget {
  final ValueChanged<int>? onItemCountChanged;
  final ValueChanged<PantryItem>? onItemChecked;

  const GroceriesScreen({
    super.key,
    this.onItemCountChanged,
    this.onItemChecked,
  });

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  final List<GroceryItem> _items = [];
  String _searchQuery = '';
  AsanFilterSelection? _activeFilters;
  late final ScrollController _contentScrollController;
  late final ScrollController _filterScrollController;
  bool _isContentScrolled = false;

  @override
  void initState() {
    super.initState();
    _contentScrollController = ScrollController()
      ..addListener(_handleContentScroll);
    _filterScrollController = ScrollController();
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
                onBackPressed: () async {
                  final formState = formKey.currentState;
                  if (formState == null || !formState.hasChanges) {
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }
                  final shouldDiscard = await AsanAlertDialog.show(context,
                    title: 'Discard Changes?',
                    content: 'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AsanAppBar(
        screenTitle: 'Groceries',
        forceElevated: _isContentScrolled,
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
      body: _groupedItems.isEmpty &&
              (_searchQuery.trim().isNotEmpty || _activeFilterLabels.isNotEmpty)
          ? AsanEmptyState(
              icon: Symbols.search_off_rounded,
              title: "No grocery items found",
              message: "No matches for '${_searchQuery.trim()}'."
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
        controller: _contentScrollController,
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
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
                  : filters!.foodGroups.contains(item.foodGroup)),
        )
        .toList();
    final sortBy = filters?.sortBy ?? 'Food group';
    items.sort((first, second) {
      final result = sortBy == 'Item name'
          ? first.name.toLowerCase().compareTo(second.name.toLowerCase())
          : (first.foodGroup ?? 'Uncategorized').compareTo(
              second.foodGroup ?? 'Uncategorized',
            );
      return (filters?.sortAscending ?? true) ? result : -result;
    });

    final groups = <String, List<GroceryItem>>{};
    for (final item in items) {
      final label = sortBy == 'Item name'
          ? (item.name.trim().isEmpty ? '#' : item.name.trim()[0].toUpperCase())
          : item.foodGroup ?? 'Uncategorized';
      (groups[label] ??= []).add(item);
    }
    return groups.entries.toList();
  }

  Widget _buildListTile(GroceryItem item) => AsanListTile(
    key: ValueKey(item),
    itemName: item.name,
    quantity: item.quantity,
    unit: item.unit,
    category: item.foodGroup ?? 'Uncategorized',
    purchasedDate: '',
    notes: item.notes,
    onChanged: (checked) {
      if (checked) _completeItem(item);
    },
    onTap: () => _showEditItemDialog(item),
  );

  void _completeItem(GroceryItem item) {
    final checkedDate = DateTime.now();
    setState(() => _items.remove(item));
    widget.onItemCountChanged?.call(_items.length);
    widget.onItemChecked?.call(
      PantryItem(
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        foodGroup: item.foodGroup,
        purchaseDate: checkedDate,
        notes: item.notes,
      ),
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
              onBackPressed: () async {
                final formState = formKey.currentState;
                if (formState == null || !formState.hasChanges) {
                  if (context.mounted) Navigator.pop(context);
                  return;
                }
                final shouldDiscard = await AsanAlertDialog.show(context,
                  title: 'Discard Changes?',
                  content: 'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
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
      if (index != -1) setState(() => _items[index] = updatedItem);
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
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;
  String? _foodGroup;
  bool _itemHasError = false;
  bool _foodGroupHasError = false;

  bool get hasChanges => widget.initialItem == null
      ? _itemController.text.isNotEmpty ||
            _quantityController.text.isNotEmpty ||
            _unitController.text.isNotEmpty ||
            _notesController.text.isNotEmpty ||
            _foodGroup != null
      : _itemController.text.trim() != widget.initialItem!.name ||
            _quantityController.text.trim() != widget.initialItem!.quantity ||
            _unitController.text.trim() != widget.initialItem!.unit ||
            _notesController.text.trim() != widget.initialItem!.notes ||
            _foodGroup != widget.initialItem!.foodGroup;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _itemController = TextEditingController(text: item?.name);
    _quantityController = TextEditingController(text: item?.quantity);
    _unitController = TextEditingController(text: item?.unit);
    _notesController = TextEditingController(text: item?.notes);
    _foodGroup = item?.foodGroup;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
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
            required: true,
          ),
          const SizedBox(height: AsanSpacing.md),
          AsanDropdownMenu(
            label: 'Food Group',
            items: asanFoodGroups,
            value: _foodGroup,
            hintText: 'Select a food group',
            hasError: _foodGroupHasError,
            required: true,
            onChanged: (value) {
              setState(() {
                _foodGroup = value;
                _foodGroupHasError = false;
              });
            },
          ),
          const SizedBox(height: AsanSpacing.md),
          Row(
            children: [
              Expanded(
                child: AsanTextField(
                  label: 'Quantity',
                  hintText: 'Enter quantity',
                  controller: _quantityController,
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
    final hasFoodGroup = _foodGroup != null;
    setState(() {
      _itemHasError = name.isEmpty;
      _foodGroupHasError = !hasFoodGroup;
    });
    if (name.isEmpty || !hasFoodGroup) return;

    Navigator.pop(
      context,
      GroceryItem(
        name: name,
        quantity: _quantityController.text.trim(),
        unit: _unitController.text.trim(),
        foodGroup: _foodGroup,
        notes: _notesController.text.trim(),
      ),
    );
  }
}
