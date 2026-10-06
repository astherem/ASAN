import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';
import 'package:asan/models/pantry_item.dart';
import 'package:asan/models/filters.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class PantryScreen extends StatefulWidget {
  final List<PantryItem> incomingItems;

  const PantryScreen({super.key, this.incomingItems = const []});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final List<PantryItem> _items = [];
  String _searchQuery = '';
  AsanFilterSelection? _activeFilters;
  late final ScrollController _filterScrollController;
  int _receivedItemCount = 0;

  @override
  void initState() {
    super.initState();
    _filterScrollController = ScrollController();
    _items.addAll(widget.incomingItems);
    _receivedItemCount = widget.incomingItems.length;
  }

  @override
  void didUpdateWidget(covariant PantryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.incomingItems.length > _receivedItemCount) {
      _items.addAll(widget.incomingItems.skip(_receivedItemCount));
      _receivedItemCount = widget.incomingItems.length;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
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
          menuType: AsanFilterMenuType.pantry,
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

  Future<void> _showAddPantryItemDialog(BuildContext context) async {
    final formKey = GlobalKey<_AddPantryItemFormState>();

    final item = await showDialog<PantryItem>(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Scaffold(
      resizeToAvoidBottomInset: false,
              appBar: FullScreenDialogHeader(
                screenTitle: 'Add Pantry Item',
                bottomPadding: AsanSpacing.xs,
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
              body: AddPantryItemForm(key: formKey),
            ),
          ),
        );
      },
    );
    if (item != null && mounted) {
      setState(() => _items.add(item));
      AsanSnackBar.show(
        context,
        message: '${item.name} added to Pantry',
        actionLabel: 'Undo',
        onAction: () {
          if (mounted) setState(() => _items.remove(item));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AsanAppBar(
        screenTitle: 'Pantry',
        icon: const Icon(Symbols.add_rounded),
        onIconPressed: () {
          _showAddPantryItemDialog(context);
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
                        hintText: 'Search pantry...',
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
              title: _searchQuery.trim().isNotEmpty
                  ? 'No pantry items found'
                  : 'No pantry items match these filters',
              message: _searchQuery.trim().isNotEmpty
                  ? 'No pantry items match "${_searchQuery.trim()}".'
                  : 'Try removing or changing a filter.',
            )
          : _items.isEmpty
          ? AsanEmptyState(
              icon: Symbols.grocery_rounded,
              title: 'Your pantry is empty',
              message: 'When you add pantry items, they will show up here.',
              actionLabel: 'Add Pantry Item',
              onAction: () => _showAddPantryItemDialog(context),
            )
          : ListView.separated(
        padding: const EdgeInsets.all(AsanSpacing.lg).copyWith(top: 0),
        itemCount: _groupedItems.length,
        itemBuilder: (context, index) {
          final group = _groupedItems[index];
          return AsanExpansionTile(
            key: ValueKey(group.key),
            title: _formatGroupTitle(group.key),
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

  List<MapEntry<String, List<PantryItem>>> get _groupedItems {
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
            : filters!.foodGroups.contains(item.aisle),
        )
        .toList();
    final sortBy = filters?.sortBy ?? 'Expiration date';
    items.sort((first, second) {
      final result = switch (sortBy) {
        'Aisle' => (first.aisle ?? 'Uncategorized').toLowerCase().compareTo(
          (second.aisle ?? 'Uncategorized').toLowerCase(),
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

    final groups = <String, List<PantryItem>>{};
    for (final item in items) {
      final label = item.consumed
          ? 'Consumed'
          : switch (sortBy) {
              'Aisle' => _formatGroupTitle(item.aisle ?? 'Uncategorized'),
              'Item name' =>
                item.name.trim().isEmpty
                    ? '#'
                    : item.name.trim()[0].toUpperCase(),
              'Purchase date' =>
                item.purchaseDate == null
                    ? 'no purchase date'
                    : _formatDate(item.purchaseDate!),
              _ =>
                item.expiryDate == null
                    ? 'no expiration date'
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

  String _formatGroupTitle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  Widget _buildListTile(PantryItem item) => AsanListTile(
    key: ValueKey(item),
    itemName: item.name,
    amount: item.amount,
    unit: item.unit,
    category: item.consumed
      ? item.aisle ?? 'Uncategorized'
      : _activeSort == 'Aisle'
        ? item.expiryDate == null
            ? 'no expiration date'
            : 'expires ${_formatDate(item.expiryDate)}'
        : item.aisle ?? 'Uncategorized',
    purchasedDate: item.consumed
        ? 'consumed ${_formatConsumedDate(item.consumedDate)}'
        : item.purchaseDate == null
        ? 'no purchase date'
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
        AsanSnackBar.show(
          context,
          message: checked
              ? '${item.name} marked as consumed'
              : '${item.name} marked as not consumed',
          actionLabel: 'Undo',
          onAction: () {
            if (!mounted || index >= _items.length) return;
            setState(() => _items[index] = item.copyWith(
              consumed: !checked,
              consumedDate: item.consumedDate,
            ));
          },
        );
      }
    },
    onTap: () => _showEditItemDialog(item),
  );

  Future<void> _showEditItemDialog(PantryItem item) async {
    final formKey = GlobalKey<_AddPantryItemFormState>();
    final updatedItem = await showDialog<PantryItem>(
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
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                icon: const Icon(
                  Symbols.delete_rounded,
                  fill: 1,
                  size: 28,
                  color: AsanColorScheme.error,
                ),
                onPressed: () async {
                  final confirmed = await AsanAlertDialog.show(
                    context,
                    title: 'Delete Pantry Item?',
                    content: 'This item will be permanently removed from your pantry. Are you sure you want to delete it?',
                    cancelText: 'Cancel',
                    destructiveText: 'Delete Item',
                  );
                  if (confirmed == true && context.mounted) {
                    Navigator.pop(context);
                    setState(() => _items.remove(item));
                  }
                },
              ),
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
            body: AddPantryItemForm(
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

  String get _activeSort => _activeFilters?.sortBy ?? 'Expiration date';

  String _expirationStatus(PantryItem item) {
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

class AddPantryItemForm extends StatefulWidget {
  final PantryItem? initialItem;
  final String submitLabel;

  const AddPantryItemForm({
    super.key,
    this.initialItem,
    this.submitLabel = 'Add to Pantry',
  });

  @override
  State<AddPantryItemForm> createState() => _AddPantryItemFormState();
}

class _AddPantryItemFormState extends State<AddPantryItemForm> {
  late final TextEditingController _itemController;
  late final TextEditingController _amountController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;
  String? _aisle;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  bool _itemHasError = false;
  bool _aisleHasError = false;

  bool get hasChanges => widget.initialItem == null
      ? _itemController.text.isNotEmpty ||
            _amountController.text.isNotEmpty ||
            _unitController.text.isNotEmpty ||
            _notesController.text.isNotEmpty ||
            _aisle != null ||
            _purchaseDate != null ||
            _expiryDate != null
      : _itemController.text.trim() != widget.initialItem!.name ||
            _amountController.text.trim() != widget.initialItem!.amount ||
            _unitController.text.trim() != widget.initialItem!.unit ||
            _notesController.text.trim() != widget.initialItem!.notes ||
            _aisle != widget.initialItem!.aisle ||
            _purchaseDate != widget.initialItem!.purchaseDate ||
            _expiryDate != widget.initialItem!.expiryDate;

  String _formatDate(DateTime date) {
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

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _itemController = TextEditingController(text: item?.name);
    _amountController = TextEditingController(text: item?.amount);
    _unitController = TextEditingController(text: item?.unit);
    _notesController = TextEditingController(text: item?.notes);
    _aisle = item?.aisle;
    _purchaseDate = item?.purchaseDate;
    _expiryDate = item?.expiryDate;
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
    final todayHint = _formatDate(DateTime.now());

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
            errorText: 'Aisle is required.',
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
          Row(
            children: [
              Expanded(
                child: AsanDateField(
                  label: 'Purchase Date',
                  initialDate: _purchaseDate,
                  hintText: todayHint,
                  onChanged: (date) => _purchaseDate = date,
                ),
              ),
              const SizedBox(width: AsanSpacing.md),
              Expanded(
                child: AsanDateField(
                  label: 'Expiry Date',
                  initialDate: _expiryDate,
                  hintText: todayHint,
                  onChanged: (date) => _expiryDate = date,
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
      PantryItem(
        name: name,
        amount: _amountController.text.trim(),
        unit: _unitController.text.trim(),
        aisle: _aisle,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        notes: _notesController.text.trim(),
        consumed: widget.initialItem?.consumed ?? false,
        consumedDate: widget.initialItem?.consumedDate,
      ),
    );
  }
}
