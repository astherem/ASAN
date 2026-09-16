import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/models/pantry_item.dart';

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
  late final ScrollController _contentScrollController;
  late final ScrollController _filterScrollController;
  bool _isContentScrolled = false;
  int _receivedItemCount = 0;

  @override
  void initState() {
    super.initState();
    _contentScrollController = ScrollController()
      ..addListener(_handleContentScroll);
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
              appBar: FullScreenDialogHeader(
                screenTitle: 'Add Pantry Item',
                onBackPressed: () async {
                  final formState = formKey.currentState;
                  if (formState == null || !formState.hasChanges) {
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }

                  final shouldDiscard = await AsanAlertDialog.show(context);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AsanAppBar(
        screenTitle: 'Pantry',
        forceElevated: _isContentScrolled,
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
      body: ListView.separated(
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

    final groups = <String, List<PantryItem>>{};
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

  Widget _buildListTile(PantryItem item) => AsanListTile(
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

  Future<void> _showEditItemDialog(PantryItem item) async {
    final formKey = GlobalKey<_AddPantryItemFormState>();
    final updatedItem = await showDialog<PantryItem>(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: SafeArea(
          child: Scaffold(
            appBar: FullScreenDialogHeader(
              screenTitle: 'Edit ${item.name}',
              onBackPressed: () async {
                final formState = formKey.currentState;
                if (formState == null || !formState.hasChanges) {
                  if (context.mounted) Navigator.pop(context);
                  return;
                }

                final shouldDiscard = await AsanAlertDialog.show(context);
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
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;
  String? _foodGroup;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  bool _itemHasError = false;
  bool _foodGroupHasError = false;

  bool get hasChanges => widget.initialItem == null
      ? _itemController.text.isNotEmpty ||
            _quantityController.text.isNotEmpty ||
            _unitController.text.isNotEmpty ||
            _notesController.text.isNotEmpty ||
            _foodGroup != null ||
            _purchaseDate != null ||
            _expiryDate != null
      : _itemController.text.trim() != widget.initialItem!.name ||
            _quantityController.text.trim() != widget.initialItem!.quantity ||
            _unitController.text.trim() != widget.initialItem!.unit ||
            _notesController.text.trim() != widget.initialItem!.notes ||
            _foodGroup != widget.initialItem!.foodGroup ||
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
    _quantityController = TextEditingController(text: item?.quantity);
    _unitController = TextEditingController(text: item?.unit);
    _notesController = TextEditingController(text: item?.notes);
    _foodGroup = item?.foodGroup;
    _purchaseDate = item?.purchaseDate;
    _expiryDate = item?.expiryDate;
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
    final hasFoodGroup = _foodGroup != null;
    setState(() {
      _itemHasError = name.isEmpty;
      _foodGroupHasError = !hasFoodGroup;
    });
    if (name.isEmpty || !hasFoodGroup) return;

    Navigator.pop(
      context,
      PantryItem(
        name: name,
        quantity: _quantityController.text.trim(),
        unit: _unitController.text.trim(),
        foodGroup: _foodGroup,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        notes: _notesController.text.trim(),
        consumed: widget.initialItem?.consumed ?? false,
        consumedDate: widget.initialItem?.consumedDate,
      ),
    );
  }
}
