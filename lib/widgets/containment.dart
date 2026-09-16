import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';

// LIST TILE
class AsanListTile extends StatefulWidget {
  final String itemName;
  final String quantity;
  final String unit;
  final String category;
  final String purchasedDate;
  final String notes;
  final VoidCallback? onTap;
  final bool isChecked;
  final ValueChanged<bool>? onChanged;

  const AsanListTile({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.purchasedDate,
    this.notes = '',
    this.onTap,
    this.isChecked = false,
    this.onChanged,
  });

  @override
  State<AsanListTile> createState() => _AsanListTileState();
}

class _AsanListTileState extends State<AsanListTile> {
  late bool _isChecked = widget.isChecked;

  void _toggleChecked(bool value) {
    setState(() {
      _isChecked = value;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isChecked
        ? AsanColorScheme.inactive
        : AsanColorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CheckboxButton(value: _isChecked, onChanged: _toggleChecked),
              const SizedBox(width: AsanSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.itemName,
                            style: AsanTextTheme.bodyMedium.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AsanSpacing.md),
                        Text(
                          '${widget.quantity} ${widget.unit}',
                          style: AsanTextTheme.bodyMedium.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    if (widget.category.isNotEmpty ||
                        widget.purchasedDate.isNotEmpty) ...[
                      const SizedBox(height: AsanSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.category,
                              style: AsanTextTheme.labelSmall.copyWith(
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AsanSpacing.md),
                          Text(
                            widget.purchasedDate,
                            style: AsanTextTheme.labelSmall.copyWith(
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.notes.isNotEmpty) ...[
                      const SizedBox(height: AsanSpacing.xs),
                      Text(
                        widget.notes,
                        style: AsanTextTheme.labelSmall.copyWith(
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// EXPANSION TILE
class AsanExpansionTile extends StatefulWidget {
  final String title;
  final int itemCount;
  final List<Widget> children;
  final bool initiallyExpanded;

  const AsanExpansionTile({
    super.key,
    required this.title,
    required this.itemCount,
    this.children = const [],
    this.initiallyExpanded = true,
  });

  @override
  State<AsanExpansionTile> createState() => _AsanExpansionTileState();
}

class _AsanExpansionTileState extends State<AsanExpansionTile> {
  late bool _isExpanded = widget.initiallyExpanded;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AsanSpacing.xs),
              child: SizedBox(
                height: 22,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              style: AsanTextTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AsanSpacing.xs),
                          Text(
                            '(${widget.itemCount} items)',
                            style: AsanTextTheme.bodyMedium.copyWith(
                              color: AsanColorScheme.inactive,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AsanSpacing.sm),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Symbols.keyboard_arrow_down_rounded,
                        size: 24,
                        weight: 600,
                        color: AsanColorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}

// RECIPE CARD

// DIVIDER
class AsanDivider extends StatelessWidget {
  final double thickness;
  final Color color;

  const AsanDivider({
    super.key,
    this.thickness = 1,
    this.color = AsanColorScheme.container,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(height: thickness, thickness: thickness, color: color);
  }
}
