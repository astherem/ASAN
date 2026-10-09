import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/selections.dart';
import 'package:asan/widgets/communication.dart';

// TEXT FIELD
class AsanTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool hasError;
  final String? errorText;
  final bool required;
  final bool expandsWithContent;
  final Widget? labelAction;
  final double horizontalPadding;
  final TextStyle? labelStyle;

  const AsanTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.hasError = false,
    this.errorText,
    this.required = false,
    this.expandsWithContent = false,
    this.labelAction,
    this.horizontalPadding = AsanSpacing.sm,
    this.labelStyle,
  });

  @override
  State<AsanTextField> createState() => _AsanTextFieldState();
}

class _AsanTextFieldState extends State<AsanTextField> {
  late TextEditingController _controller;
  late final FocusNode _focusNode;
  late bool _ownsController;
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _isObscured = widget.obscureText;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode()..addListener(_updateState);
    _controller.addListener(_updateState);
  }

  @override
  void didUpdateWidget(covariant AsanTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == oldWidget.controller) return;

    _controller.removeListener(_updateState);
    if (_ownsController) _controller.dispose();

    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _focusNode
      ..removeListener(_updateState)
      ..dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _focusNode.hasFocus;
    final hasBorder = isActive || widget.hasError;
    final textColor = _controller.text.isEmpty
        ? AsanColorScheme.inactive
        : AsanColorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: widget.labelStyle ??
                  AsanTextTheme.labelSmall.copyWith(
                    color: AsanColorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.required) ...[
              const SizedBox(width: AsanSpacing.xs),
              Text(
                '(Required)',
                style: AsanTextTheme.labelSmall.copyWith(
                  color: AsanColorScheme.inactive,
                ),
              ),
            ],
            if (widget.labelAction != null) ...[
              const Spacer(),
              widget.labelAction!,
            ],
          ],
        ),
        const SizedBox(height: AsanSpacing.sm),
        Container(
          constraints: widget.expandsWithContent
              ? const BoxConstraints(minHeight: 38)
              : const BoxConstraints.tightFor(height: 38),
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: AsanSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: hasBorder
                ? AsanColorScheme.surface
                : AsanColorScheme.container,
            borderRadius: BorderRadius.circular(AsanSpacing.sm),
            border: hasBorder
                ? Border.all(
                    color: isActive
                      ? AsanColorScheme.primary
                      : AsanColorScheme.error,
                  )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  autofillHints: widget.autofillHints,
                  obscureText: _isObscured,
                  minLines: widget.expandsWithContent ? 1 : 1,
                  maxLines: widget.expandsWithContent ? null : 1,
                  style: AsanTextTheme.bodyMedium.copyWith(color: textColor),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AsanTextTheme.bodyMedium.copyWith(
                      color: AsanColorScheme.inactive,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  cursorColor: AsanColorScheme.primary,
                  textAlignVertical: TextAlignVertical.center,
                ),
              ),
              if (widget.obscureText)
                IconButton(
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                  icon: Icon(
                    _isObscured ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
                    size: 20,
                    weight: 600,
                    color: _isObscured
                        ? AsanColorScheme.inactive
                        : AsanColorScheme.secondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 22),
                ),
            ],
          ),
        ),
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: AsanSpacing.xs),
          Text(
            widget.errorText!,
            style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.error),
          ),
        ],
      ],
    );
  }
}

// SEARCH BAR
class AsanSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final String initialQuery;

  const AsanSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.initialQuery = '',
  });

  @override
  State<AsanSearchBar> createState() => _AsanSearchBarState();
}

class _AsanSearchBarState extends State<AsanSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool get _isActive => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();

    _controller.text = widget.initialQuery;

    _focusNode.addListener(_updateState);
    _controller.addListener(_updateState);
  }

  @override
  void didUpdateWidget(covariant AsanSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        _controller.text != widget.initialQuery) {
      _controller.value = TextEditingValue(
        text: widget.initialQuery,
        selection: TextSelection.collapsed(offset: widget.initialQuery.length),
      );
    }
  }

  void _updateState() {
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(AsanSpacing.sm),
      decoration: BoxDecoration(
        color: isActive ? AsanColorScheme.surface : AsanColorScheme.container,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: AsanColorScheme.primary) : null,
      ),
      child: Row(
        children: [
          IconTheme(
            data: IconThemeData(
              size: 22,
              color: isActive
                  ? AsanColorScheme.primary
                  : AsanColorScheme.inactive,
            ),
            child: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: AsanSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: AsanTextTheme.bodyMedium.copyWith(
                color: AsanColorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AsanTextTheme.bodyMedium.copyWith(
                  color: AsanColorScheme.inactive,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),

          if (_controller.text.isNotEmpty) ...[
            const SizedBox(width: AsanSpacing.sm),

            SizedBox(
              width: 22,
              height: 22,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: IconTheme(
                  data: IconThemeData(
                    size: 22,
                    color: isActive
                        ? AsanColorScheme.primary
                        : AsanColorScheme.inactive,
                  ),
                  child: const Icon(Symbols.close_rounded),
                ),
                onPressed: _clearSearch,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// IMAGE PICKER
class AsanImagePicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const AsanImagePicker({
    super.key,
    required this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: AsanColorScheme.container,
                  child: imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Symbols.add_photo_alternate_rounded,
                              size: 72,
                              color: AsanColorScheme.inactive,
                            ),
                            const SizedBox(height: AsanSpacing.sm),
                            Text(
                              'Add Recipe Image',
                              style: AsanTextTheme.labelSmall.copyWith(
                                color: AsanColorScheme.inactive,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Image.memory(imageBytes!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          if (imageBytes != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: TonalIconButton.round(
                size: 42,
                icon: const Icon(Symbols.edit_rounded, size: 20),
                onPressed: onTap,
              ),
            ),
        ],
      ),
    );
  }
}

// DROPDOWN MENU
List<String> uniqueStrings(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
      result.add(trimmed);
    }
  }
  return result;
}

double dropdownSheetInitialSize(
  BuildContext context, {
  required int itemCount,
  required bool showSearch,
}) {
  const minimumSize = 0.5;
  const maximumSize = 0.9;
  const itemHeight = 38.0;
  const itemGap = 8.0;
  const fixedHeight = 122.0;
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
  final String? searchHint;
  final ValueChanged<String?>? onChanged;
  final bool hasError;
  final String? errorText;
  final bool required;
  final Color? labelColor;

  const AsanDropdownMenu({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.hintText,
    this.searchHint,
    this.onChanged,
    this.hasError = false,
    this.errorText,
    this.required = false,
    this.labelColor,
  });

  @override
  State<AsanDropdownMenu> createState() => _AsanDropdownMenuState();
}

class _AsanDropdownMenuState extends State<AsanDropdownMenu> {
  bool _isOpen = false;

  Future<void> _openList() async {
    setState(() => _isOpen = true);
    final items = uniqueStrings(widget.items);
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
          itemCount: items.length,
          showSearch: true,
        ),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AsanDropdownList(
          title: widget.label == 'Food Group'
              ? 'Select Food Group'
              : widget.label == 'Aisle'
              ? 'Select Aisle'
              : widget.label == 'Dish Type'
              ? 'Select Dish Type'
              : widget.label,
          items: items,
          selectedValue: widget.value,
          searchHint: widget.searchHint ?? 'Search ${widget.label.toLowerCase()}...',
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
          Row(
            children: [
              Text(
                widget.label,
                style: AsanTextTheme.labelSmall.copyWith(
                  color: widget.labelColor ?? AsanColorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.required) ...[
                const SizedBox(width: AsanSpacing.xs),
                Text(
                  '(Required)',
                  style: AsanTextTheme.labelSmall.copyWith(
                    color: AsanColorScheme.inactive,
                  ),
                ),
              ],
            ],
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
                      color: _isOpen
                          ? AsanColorScheme.primary
                          : AsanColorScheme.error,
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
                      Symbols.arrow_drop_down_rounded,
                      size: 24,
                      color: AsanColorScheme.inactive,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: AsanSpacing.xs),
          Text(
            widget.errorText!,
            style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.error),
          ),
        ],
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
    if (widget.scrollController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = widget.scrollController!;
        final selectedIndex = widget.items.indexOf(widget.selectedValue ?? '');
        if (!controller.hasClients || selectedIndex < 0) return;

        final offset = selectedIndex * (38 + AsanSpacing.sm);
        controller.jumpTo(
          offset.clamp(0, controller.position.maxScrollExtent).toDouble(),
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final filteredItems = uniqueStrings(widget.items)
        .where((item) => item.toLowerCase().contains(query))
        .toList();

    return SafeArea(
      top: false,
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
            padding: const EdgeInsets.symmetric(
              horizontal: AsanSpacing.lg,
              vertical: AsanSpacing.md,
            ),
            child: AsanSheetHeader(
              title: widget.title,
              onClose: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AsanSpacing.lg,
                0,
                AsanSpacing.lg,
                AsanSpacing.md,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AsanSpacing.sm),
                  if (widget.showSearch) ...[
                    AsanSearchBar(
                      hintText: widget.searchHint,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: AsanSpacing.md),
                  ],
                  Expanded(
                    child: filteredItems.isEmpty
                        ? AsanEmptyState(
                            icon: Symbols.search_off_rounded,
                            title: _searchQuery.trim().isEmpty
                                ? 'No options available'
                                : 'No results found',
                            message: _searchQuery.trim().isEmpty
                                ? 'There are no options to choose from.'
                                : 'Try a different search.',
                          )
                        : ListView.separated(
                            controller:
                                widget.scrollController ?? _scrollController,
                            padding: EdgeInsets.zero,
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AsanSpacing.sm),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isSelected =
                                  item == widget.selectedValue;
                              return _DropdownListItem(
                                label: item,
                                isSelected: isSelected,
                                onPressed: () =>
                                    Navigator.pop(context, item),
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
                    isSelected ? Symbols.check_rounded : null,
                    size: 18,
                    color: AsanColorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AsanTextTheme.bodyMedium.copyWith(
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

// DATE FIELD
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
                        child: const Icon(Symbols.calendar_today_rounded),
                      ),
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


