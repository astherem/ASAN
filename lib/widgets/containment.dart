import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

// LIST TILE
class AsanListTile extends StatelessWidget {
  final String itemName;
  final String quantity;
  final String unit;
  final String category;
  final String purchasedDate;
  final bool isChecked;
  final ValueChanged<bool?>? onChanged;

  const AsanListTile({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.purchasedDate,
    this.isChecked = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              side: const BorderSide(
                color: AsanColorScheme.secondary,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
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
                        itemName,
                        style: AsanTextTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 22 / 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AsanSpacing.md),
                    Text(
                      '$quantity $unit',
                      style: AsanTextTheme.bodyMedium.copyWith(height: 22 / 16),
                    ),
                  ],
                ),
                const SizedBox(height: AsanSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: AsanTextTheme.labelSmall.copyWith(
                          height: 16 / 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AsanSpacing.md),
                    Text(
                      purchasedDate,
                      style: AsanTextTheme.labelSmall.copyWith(height: 16 / 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    this.initiallyExpanded = false,
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
    final tileChildren = widget.children.isEmpty
        ? <Widget>[
            const AsanListTile(
              itemName: 'ground pork',
              quantity: '1/4',
              unit: 'kg',
              category: 'meat',
              purchasedDate: 'bought August 10',
            ),
            const AsanListTile(
              itemName: 'broccoli',
              quantity: '2',
              unit: 'heads',
              category: 'vegetables',
              purchasedDate: 'bought August 10',
            ),
          ]
        : widget.children;

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
                                height: 22 / 16,
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
                              height: 22 / 16,
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
            children: tileChildren,
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
    return Divider(
      height: thickness,
      thickness: thickness,
      color: color,
    );
  }
}