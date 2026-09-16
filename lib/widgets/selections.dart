import 'package:flutter/material.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';

const asanFoodGroups = [
  'Beverages',
  'Bread & Bakery',
  'Cans & Jars',
  'Condiments & Sauces',
  'Dairy',
  'Deli',
  'Frozen Foods',
  'Fruit',
  'Grains & Cereals',
  'Herbs & Spices',
  'Meat',
  'Oils & Vinegars',
  'Poultry',
  'Seafood',
  'Snacks',
  'Spices & Seasonings',
  'Soups & Broths',
  'Vegetables',
  'Other',
];

// DROPDOWN MENU
double dropdownSheetInitialSize(
  BuildContext context, {
  required int itemCount,
  required bool showSearch,
}) {
  const minimumSize = 0.5;
  const maximumSize = 0.9;
  const itemHeight = 38.0;
  const itemGap = 8.0;
  const fixedHeight = 106.0;
  final contentHeight =
      fixedHeight +
      (showSearch ? 70 : 0) +
      itemCount * itemHeight +
      (itemCount > 0 ? (itemCount - 1) * itemGap : 0);
  final availableHeight = MediaQuery.sizeOf(context).height;
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

  return ((contentHeight + bottomInset) / availableHeight)
      .clamp(minimumSize, maximumSize)
      .toDouble();
}

class AsanDropdownMenu extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? value;
  final String? hintText;
  final ValueChanged<String?>? onChanged;
  final bool hasError;

  const AsanDropdownMenu({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.hintText,
    this.onChanged,
    this.hasError = false,
  });

  @override
  State<AsanDropdownMenu> createState() => _AsanDropdownMenuState();
}

class _AsanDropdownMenuState extends State<AsanDropdownMenu> {
  bool _isOpen = false;

  Future<void> _openList() async {
    setState(() => _isOpen = true);
    final selectedValue = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AsanColorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: dropdownSheetInitialSize(
          context,
          itemCount: widget.items.length,
          showSearch: true,
        ),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AsanDropdownList(
          title: widget.label == 'Food Group'
              ? 'Select Food Group'
              : widget.label,
          items: widget.items,
          selectedValue: widget.value,
          scrollController: scrollController,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _isOpen = false);
    if (selectedValue != null) widget.onChanged?.call(selectedValue);
  }

  @override
  Widget build(BuildContext context) {
    final hasBorder = _isOpen || widget.hasError;
    final textColor = widget.value == null
        ? AsanColorScheme.inactive
        : AsanColorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: AsanTextTheme.labelSmall.copyWith(
            color: AsanColorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: hasBorder
                ? AsanColorScheme.surface
                : AsanColorScheme.container,
            borderRadius: BorderRadius.circular(8),
            border: hasBorder
                ? Border.all(
                    color: widget.hasError
                        ? AsanColorScheme.error
                        : AsanColorScheme.primary,
                  )
                : null,
          ),
          child: InkWell(
            onTap: _openList,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value ?? widget.hintText ?? '',
                      style: AsanTextTheme.bodyMedium.copyWith(
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 24,
                    color: AsanColorScheme.inactive,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AsanDropdownList extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedValue;
  final String searchHint;
  final bool showSearch;
  final ScrollController? scrollController;

  const AsanDropdownList({
    super.key,
    required this.title,
    required this.items,
    this.selectedValue,
    this.searchHint = 'Search food group...',
    this.showSearch = true,
    this.scrollController,
  });

  @override
  State<AsanDropdownList> createState() => _AsanDropdownListState();
}

class _AsanDropdownListState extends State<AsanDropdownList> {
  String _searchQuery = '';
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final selectedIndex = widget.items.indexOf(widget.selectedValue ?? '');
    _scrollController = ScrollController(
      initialScrollOffset: selectedIndex < 0
          ? 0
          : selectedIndex * (38 + AsanSpacing.sm),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final filteredItems = widget.items
        .where((item) => item.toLowerCase().contains(query))
        .toList();

    return SafeArea(
      top: false,
      child: SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AsanColorScheme.inactive,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AsanSpacing.lg, AsanSpacing.sm, AsanSpacing.lg, AsanSpacing.md),
                child: Column(
                  children: [
                    SizedBox(
                      height: 22,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 22, height: 22),
                          Text(
                            widget.title,
                            style: AsanTextTheme.bodyMedium.copyWith(
                              height: 22 / 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 24, weight: 600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AsanSpacing.md),
                    if (widget.showSearch) ...[
                      AsanSearchBar(
                        hintText: widget.searchHint,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: AsanSpacing.md),
                    ],
                    Expanded(
                      child: ListView.separated(
                        controller:
                            widget.scrollController ?? _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AsanSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = item == widget.selectedValue;
                          return _DropdownListItem(
                            label: item,
                            isSelected: isSelected,
                            onPressed: () => Navigator.pop(context, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownListItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _DropdownListItem({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AsanColorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 38,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Icon(
                    isSelected ? Icons.check_rounded : null,
                    size: 18,
                    color: AsanColorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AsanTextTheme.bodyMedium.copyWith(
                    height: 22 / 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FILTER MENU
double filterSheetInitialSize(BuildContext context) {
  const contentHeight = 820.0;
  final availableHeight = MediaQuery.sizeOf(context).height;
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  return ((contentHeight + bottomInset) / availableHeight)
      .clamp(0.5, 0.9)
      .toDouble();
}

class AsanFilterSelection {
  final String sortBy;
  final bool sortAscending;
  final Set<String> purchaseStatuses;
  final Set<String> expirationStatuses;
  final Set<String> foodGroups;

  const AsanFilterSelection({
    required this.sortBy,
    required this.sortAscending,
    required this.purchaseStatuses,
    required this.expirationStatuses,
    required this.foodGroups,
  });

  AsanFilterSelection copyWith({
    String? sortBy,
    bool? sortAscending,
    Set<String>? purchaseStatuses,
    Set<String>? expirationStatuses,
    Set<String>? foodGroups,
  }) {
    return AsanFilterSelection(
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      purchaseStatuses: purchaseStatuses ?? this.purchaseStatuses,
      expirationStatuses: expirationStatuses ?? this.expirationStatuses,
      foodGroups: foodGroups ?? this.foodGroups,
    );
  }
}

enum AsanFilterMenuType { pantry, groceries }

class AsanFilterList extends StatefulWidget {
  final ScrollController? scrollController;
  final AsanFilterMenuType menuType;

  const AsanFilterList({
    super.key,
    this.scrollController,
    required this.menuType,
  });

  @override
  State<AsanFilterList> createState() => _AsanFilterListState();
}

class _AsanFilterListState extends State<AsanFilterList> {
  String get _defaultSortBy => widget.menuType == AsanFilterMenuType.pantry
      ? 'Expiration date'
      : 'Food group';

  List<String> get _sortOptions => widget.menuType == AsanFilterMenuType.pantry
      ? const [
          'Expiration date',
          'Food group',
          'Item name',
          'Purchase date',
          'Date added',
        ]
      : const ['Food group', 'Item name', 'Date added'];

  String get _statusTitle => widget.menuType == AsanFilterMenuType.pantry
      ? 'Expiration Status'
      : 'Purchase Status';

  String get _defaultStatus => widget.menuType == AsanFilterMenuType.pantry
      ? 'Expiring soon'
      : 'Not purchased';

  List<String> get _statusOptions =>
      widget.menuType == AsanFilterMenuType.pantry
      ? const ['Expiring soon', 'Not expired', 'Expired']
      : const ['Not purchased', 'Purchased'];

  bool _sortAscending = true;
  String _sortBy = '';
  final Set<String> _statuses = {};
  final Set<String> _foodGroups = {};

  void _reset() {
    setState(() {
      _sortBy = _defaultSortBy;
      _sortAscending = true;
      _statuses
        ..clear()
        ..add(_defaultStatus);
      _foodGroups.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _sortBy = _defaultSortBy;
    _statuses.add(_defaultStatus);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AsanColorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AsanColorScheme.inactive,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.lg, vertical: AsanSpacing.md),
              child: _SheetHeader(
                title: 'Select Filters',
                onClose: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.lg),
                child: Column(
                  children: [
                    _FilterSection(
                      title: 'Sort By',
                      options: _sortOptions,
                      selected: _sortBy,
                      ascending: _sortAscending,
                      onDirectionChanged: () =>
                          setState(() => _sortAscending = !_sortAscending),
                      onSelected: (value) => setState(() => _sortBy = value),
                    ),
                    const SizedBox(height: AsanSpacing.md),
                    const AsanDivider(),
                    const SizedBox(height: AsanSpacing.md),
                    _FilterSection(
                      title: _statusTitle,
                      options: _statusOptions,
                      selected: '',
                      selectedValues: _statuses,
                      isCheckbox: true,
                      onSelected: (value) => setState(() {
                        _statuses.contains(value)
                            ? _statuses.remove(value)
                            : _statuses.add(value);
                      }),
                    ),
                    const SizedBox(height: AsanSpacing.md),
                    const AsanDivider(),
                    const SizedBox(height: AsanSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Food Group',
                        style: AsanTextTheme.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 16 / 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: AsanSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: AsanSpacing.sm,
                        runSpacing: AsanSpacing.sm,
                        children: asanFoodGroups.map((group) {
                          final selected = _foodGroups.contains(group);
                          return AsanFilterChip(
                            label: group,
                            isSelected: selected,
                            onPressed: () => setState(() {
                              selected
                                  ? _foodGroups.remove(group)
                                  : _foodGroups.add(group);
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: AsanOutlinedButton(
                      label: 'Reset',
                      onPressed: _reset,
                      height: 38,
                    ),
                  ),
                  const SizedBox(width: AsanSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply',
                      height: 38,
                      onPressed: () => Navigator.pop(
                        context,
                        AsanFilterSelection(
                          sortBy: _sortBy,
                          sortAscending: _sortAscending,
                          purchaseStatuses:
                              widget.menuType == AsanFilterMenuType.groceries
                              ? Set.unmodifiable(_statuses)
                              : const {},
                          expirationStatuses:
                              widget.menuType == AsanFilterMenuType.pantry
                              ? Set.unmodifiable(_statuses)
                              : const {},
                          foodGroups: Set.unmodifiable(_foodGroups),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 22),
          Text(
            title,
            style: AsanTextTheme.bodyMedium.copyWith(
              height: 22 / 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 24, weight: 600),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final Set<String>? selectedValues;
  final ValueChanged<String> onSelected;
  final bool ascending;
  final VoidCallback? onDirectionChanged;
  final bool isCheckbox;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selected,
    this.selectedValues,
    required this.onSelected,
    this.ascending = true,
    this.onDirectionChanged,
    this.isCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AsanTextTheme.labelSmall.copyWith(
            height: 16 / 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        ...options.indexed.map(
          (entry) => Padding(
            padding: EdgeInsets.only(top: entry.$1 == 0 ? 0 : AsanSpacing.sm),
            child: InkWell(
              onTap: () => onSelected(entry.$2),
              child: SizedBox(
                height: 30,
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color:
                            (selectedValues?.contains(entry.$2) ??
                                entry.$2 == selected)
                            ? AsanColorScheme.secondary
                            : Colors.transparent,
                        shape: isCheckbox
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius: isCheckbox
                            ? BorderRadius.circular(4)
                            : null,
                        border:
                            (selectedValues?.contains(entry.$2) ??
                                entry.$2 == selected)
                            ? null
                            : Border.all(color: AsanColorScheme.inactive),
                      ),
                      child:
                          (selectedValues?.contains(entry.$2) ??
                              entry.$2 == selected)
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: AsanColorScheme.surface,
                            )
                          : null,
                    ),
                    const SizedBox(width: AsanSpacing.md),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: AsanTextTheme.bodyMedium.copyWith(
                          height: 22 / 16,
                          color:
                              (selectedValues?.contains(entry.$2) ??
                                  entry.$2 == selected)
                              ? AsanColorScheme.secondary
                              : AsanColorScheme.inactive,
                          fontWeight:
                              (selectedValues?.contains(entry.$2) ??
                                  entry.$2 == selected)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (entry.$2 == selected && onDirectionChanged != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 22,
                          height: 22,
                        ),
                        onPressed: onDirectionChanged,
                        icon: IconTheme(
                          data: const IconThemeData(
                            size: 24,
                            color: AsanColorScheme.secondary,
                          ),
                          child: ascending
                              ? const Icon(Icons.arrow_upward_rounded)
                              : const Icon(Icons.arrow_downward_rounded),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// DATE PICKER
class AsanDateField extends StatefulWidget {
  final String label;
  final String? hintText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;
  final bool hasError;

  const AsanDateField({
    super.key,
    required this.label,
    this.hintText,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.hasError = false,
  });

  @override
  State<AsanDateField> createState() => _AsanDateFieldState();
}

class _AsanDateFieldState extends State<AsanDateField> {
  static const _months = [
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

  DateTime? _selectedDate;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _openPicker() async {
    setState(() => _isActive = true);

    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: AsanDatePicker(
          initialDate: _selectedDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDateSelected: (date) => Navigator.of(dialogContext).pop(date),
          onCancel: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _isActive = false;
      if (selectedDate != null) {
        _selectedDate = selectedDate;
      }
    });
    if (selectedDate != null) {
      widget.onChanged?.call(selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasBorder = _isActive || widget.hasError;
    final hasValue = _selectedDate != null;
    final iconColor = widget.hasError
        ? AsanColorScheme.inactive
        : (_isActive ? AsanColorScheme.primary : AsanColorScheme.inactive);

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            style: AsanTextTheme.labelSmall.copyWith(
              height: 16 / 12,
              color: AsanColorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: hasBorder
                ? AsanColorScheme.surface
                : AsanColorScheme.container,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _openPicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: hasBorder
                      ? Border.all(
                          color: widget.hasError
                              ? AsanColorScheme.error
                              : AsanColorScheme.primary,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? widget.hintText ?? ''
                            : _formatDate(_selectedDate!),
                        style: AsanTextTheme.bodyMedium.copyWith(
                          height: 22 / 16,
                          color: hasValue
                              ? AsanColorScheme.onSurface
                              : AsanColorScheme.inactive,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(size: 16, color: iconColor),
                          child: const Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AsanDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateSelected;
  final VoidCallback? onCancel;

  const AsanDatePicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.onCancel,
  });

  @override
  State<AsanDatePicker> createState() => _AsanDatePickerState();
}

class _AsanDatePickerState extends State<AsanDatePicker> {
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

  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  DateTime get _firstDate =>
      DateUtils.dateOnly(widget.firstDate ?? DateTime(1900));

  DateTime get _lastDate =>
      DateUtils.dateOnly(widget.lastDate ?? DateTime(2100, 12, 31));

  @override
  void initState() {
    super.initState();
    final initialDate = DateUtils.dateOnly(
      widget.initialDate ?? DateTime.now(),
    );
    _selectedDate = _clampDate(initialDate);
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  DateTime _clampDate(DateTime date) {
    if (date.isBefore(_firstDate)) return _firstDate;
    if (date.isAfter(_lastDate)) return _lastDate;
    return date;
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final firstMonth = DateTime(_firstDate.year, _firstDate.month);
    final lastMonth = DateTime(_lastDate.year, _lastDate.month);

    if (nextMonth.isBefore(firstMonth) || nextMonth.isAfter(lastMonth)) return;
    setState(() => _visibleMonth = nextMonth);
  }

  void _selectDate(DateTime date) {
    if (date.isBefore(_firstDate) || date.isAfter(_lastDate)) return;
    setState(() => _selectedDate = date);
  }

  Future<void> _selectMonth() async {
    final monthName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AsanColorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: dropdownSheetInitialSize(
          context,
          itemCount: _months.length,
          showSearch: false,
        ),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, _) => AsanDropdownList(
          title: 'Select Month',
          items: _months,
          selectedValue: _months[_visibleMonth.month - 1],
          showSearch: false,
        ),
      ),
    );

    if (monthName == null || !mounted) return;
    final month = _months.indexOf(monthName) + 1;
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, month));
  }

  Future<void> _selectYear() async {
    final years = [
      for (var year = _firstDate.year; year <= _lastDate.year; year++) '$year',
    ];
    final yearValue = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AsanColorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: dropdownSheetInitialSize(
          context,
          itemCount: years.length,
          showSearch: false,
        ),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, _) => AsanDropdownList(
          title: 'Select Year',
          items: years,
          selectedValue: '${_visibleMonth.year}',
          showSearch: false,
        ),
      ),
    );

    if (yearValue == null || !mounted) return;
    setState(() {
      _visibleMonth = DateTime(int.parse(yearValue), _visibleMonth.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 342,
      height: 419,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AsanColorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 38,
            child: Row(
              children: [
                _NavigationButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _changeMonth(-1),
                ),
                const Spacer(),
                _MonthSelector(
                  label: _months[_visibleMonth.month - 1].substring(0, 3),
                  onPressed: _selectMonth,
                ),
                const SizedBox(width: 8),
                _MonthSelector(
                  label: '${_visibleMonth.year}',
                  onPressed: _selectYear,
                ),
                const Spacer(),
                _NavigationButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CalendarGrid(
            month: _visibleMonth,
            selectedDate: _selectedDate,
            firstDate: _firstDate,
            lastDate: _lastDate,
            onDateSelected: _selectDate,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(label: 'Cancel', onPressed: widget.onCancel),
              const SizedBox(width: 16),
              _ActionButton(
                label: 'Select',
                color: AsanColorScheme.primary,
                onPressed: () => widget.onDateSelected?.call(_selectedDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const _NavigationButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: IconTheme(
          data: const IconThemeData(size: 24, color: AsanColorScheme.secondary),
          child: icon,
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MonthSelector({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 87,
      height: 38,
      child: Material(
        color: AsanColorScheme.container,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AsanTextTheme.bodyMedium.copyWith(
                      color: AsanColorScheme.secondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 24,
                  color: AsanColorScheme.inactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.month,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday % 7;
    final dates = <DateTime?>[];

    for (var i = 0; i < leadingEmpty; i++) {
      dates.add(null);
    }

    for (var day = 1; day <= daysInMonth; day++) {
      dates.add(DateTime(month.year, month.month, day));
    }

    while (dates.length < 42) {
      dates.add(null);
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final rows = <Widget>[];
    for (var row = 0; row < 6; row++) {
      final rowDates = dates.skip(row * 7).take(7);
      rows.add(
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rowDates.map((date) {
              if (date == null) {
                return const SizedBox(width: 40, height: 40);
              }

              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final isToday = DateUtils.isSameDay(date, today);
              final isOutsideRange =
                  date.isBefore(firstDate) || date.isAfter(lastDate);

              return InkWell(
                onTap: isOutsideRange ? null : () => onDateSelected(date),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AsanColorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: AsanTextTheme.bodyMedium.copyWith(
                      color: isSelected
                          ? AsanColorScheme.onPrimary
                          : isToday
                          ? AsanColorScheme.primary
                          : isOutsideRange
                          ? AsanColorScheme.inactive
                          : AsanColorScheme.secondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                .map(
                  (day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: AsanTextTheme.labelSmall.copyWith(
                          color: AsanColorScheme.inactive,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const SizedBox(height: 1),
              rows[index],
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    this.color = AsanColorScheme.secondary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          label,
          style: AsanTextTheme.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
