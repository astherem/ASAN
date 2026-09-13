import 'package:flutter/material.dart';

import 'package:asan/styles/theme.dart';
import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';

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
            height: 16 / 12,
            color: AsanColorScheme.secondary,
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
                        height: 22 / 16,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 28,
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
    this.searchHint = 'search food group...',
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                              icon: const Icon(Icons.close_rounded, size: 22),
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
  const contentHeight = 700.0;
  final availableHeight = MediaQuery.sizeOf(context).height;
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
  return ((contentHeight + bottomInset) / availableHeight)
      .clamp(0.5, 0.9)
      .toDouble();  
}

class AsanFilterSelection {
  final String sortBy;
  final bool sortAscending;
  final String purchaseStatus;
  final Set<String> foodGroups;

  const AsanFilterSelection({
    required this.sortBy,
    required this.sortAscending,
    required this.purchaseStatus,
    required this.foodGroups,
  });
}

class AsanFilterList extends StatefulWidget {
  final ScrollController? scrollController;

  const AsanFilterList({super.key, this.scrollController});

  @override
  State<AsanFilterList> createState() => _AsanFilterListState();
}

class _AsanFilterListState extends State<AsanFilterList> {
  String _sortBy = 'Food group';
  bool _sortAscending = true;
  String _purchaseStatus = 'Unpurchased';
  final Set<String> _foodGroups = {'Cans & Jars', 'Grains & Cereals', 'Meat'};

  static const _groups = [
    'Beverages',
    'Bread & Bakery',
    'Cans & Jars',
    'Condiments & Sauces',
    'Dairy',
    'Deli',
    'Fruit',
    'Grains & Cereals',
    'Herbs & Spices',
    'Meat',
  ];

  void _reset() {
    setState(() {
      _sortBy = 'Food group';
      _sortAscending = true;
      _purchaseStatus = 'Unpurchased';
      _foodGroups.clear();
    });
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
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    _SheetHeader(
                      title: 'Select Filters',
                      onClose: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: AsanSpacing.md),
                    _FilterSection(
                      title: 'Sort By',
                      options: const ['Food group', 'Item name', 'Date added'],
                      selected: _sortBy,
                      ascending: _sortAscending,
                      onDirectionChanged: () =>
                          setState(() => _sortAscending = !_sortAscending),
                      onSelected: (value) => setState(() => _sortBy = value),
          ),
                    const AsanDivider(),
                    _FilterSection(
                      title: 'Purchase Status',
                      options: const ['Unpurchased', 'Purchased'],
                      selected: _purchaseStatus,
                      isCheckbox: true,
                      onSelected: (value) =>
                          setState(() => _purchaseStatus = value),
                    ),
                    const AsanDivider(),
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
                        children: _groups.map((group) {
                          final selected = _foodGroups.contains(group);
                          return InkWell(
                            onTap: () => setState(() {
                              selected
                                  ? _foodGroups.remove(group)
                                  : _foodGroups.add(group);
                            }),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AsanColorScheme.secondary
                                    : AsanColorScheme.container,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    group,
                                    style: AsanTextTheme.bodyMedium.copyWith(
                                      color: selected
                                          ? AsanColorScheme.surface
                                          : AsanColorScheme.inactive,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (selected) ...[
                                    const SizedBox(width: AsanSpacing.xs),
                                    const Icon(
                                      Icons.close_rounded,
                                      size: 22,
                                      color: AsanColorScheme.surface,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                          purchaseStatus: _purchaseStatus,
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
            icon: const Icon(Icons.close_rounded, size: 22),
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
  final ValueChanged<String> onSelected;
  final bool ascending;
  final VoidCallback? onDirectionChanged;
  final bool isCheckbox;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selected,
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
        ...options.map(
          (option) => InkWell(
            onTap: () => onSelected(option),
            child: SizedBox(
              height: 30,
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: option == selected
                          ? AsanColorScheme.secondary
                          : Colors.transparent,
                      shape: isCheckbox ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: isCheckbox
                          ? BorderRadius.circular(4)
                          : null,
                      border: option == selected
                          ? null
                          : Border.all(color: AsanColorScheme.inactive),
                    ),
                    child: option == selected
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
                      option,
                      style: AsanTextTheme.bodyMedium.copyWith(
                        height: 22 / 16,
                        color: option == selected
                            ? AsanColorScheme.secondary
                            : AsanColorScheme.inactive,
                        fontWeight: option == selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (option == selected && onDirectionChanged != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 22,
                        height: 22,
                      ),
                      onPressed: onDirectionChanged,
                      icon: IconTheme(
                        data: const IconThemeData(
                          size: 22,
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
                          data: IconThemeData(size: 14, color: iconColor),
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
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: IconTheme(
          data: const IconThemeData(size: 22, color: AsanColorScheme.secondary),
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: AsanTextTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AsanColorScheme.secondary,
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
    final cells = <Widget>[];

    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox(width: 32, height: 32));
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected =
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isOutsideRange = date.isBefore(firstDate) || date.isAfter(lastDate);

      cells.add(
        InkWell(
          onTap: isOutsideRange ? null : () => onDateSelected(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? AsanColorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: AsanTextTheme.bodyMedium.copyWith(
                color: isSelected
                    ? AsanColorScheme.onPrimary
                    : isOutsideRange
                    ? AsanColorScheme.inactive
                    : AsanColorScheme.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            7,
            (index) => SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                  style: AsanTextTheme.labelSmall.copyWith(
                    color: AsanColorScheme.inactive,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 0, runSpacing: 0, children: cells),
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
