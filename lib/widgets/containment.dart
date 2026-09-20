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
  final Widget? titleWidget;
  final int? itemCount;
  final List<Widget> children;
  final bool initiallyExpanded;

  const AsanExpansionTile({
    super.key,
    this.title = '',
    this.titleWidget,
    this.itemCount,
    this.children = const [],
    this.initiallyExpanded = true,
  }) : assert(
         title != '' || titleWidget != null,
         'Provide either title or titleWidget',
       );

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
    final chevron = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _toggleExpanded,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(
              Symbols.keyboard_arrow_down_rounded,
              size: 24,
              weight: 600,
              color: AsanColorScheme.secondary,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.titleWidget != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AsanSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: widget.titleWidget!),
                const SizedBox(width: AsanSpacing.sm),
                chevron,
              ],
            ),
          )
        else
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
                            if (widget.itemCount != null) ...[
                              const SizedBox(width: AsanSpacing.xs),
                              Text(
                                '(${widget.itemCount} items)',
                                style: AsanTextTheme.bodyMedium.copyWith(
                                  color: AsanColorScheme.inactive,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
class RecipeCard extends StatelessWidget {
  final String recipeName;
  final String mealCategory;
  final String? imageUrl;
  final String totalTime;
  final bool isSaved;
  final bool showBookmark;
  final VoidCallback? onIconPressed;
  final VoidCallback? onTap;

  const RecipeCard({
    super.key,
    required this.recipeName,
    required this.mealCategory,
    this.imageUrl,
    required this.totalTime,
    this.isSaved = false,
    this.showBookmark = true,
    this.onIconPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl == null || imageUrl!.isEmpty)
                        Container(
                          color: AsanColorScheme.container,
                          child: const Icon(
                            Symbols.restaurant_rounded,
                            size: 36,
                            color: AsanColorScheme.inactive,
                          ),
                        )
                      else
                        Image.network(imageUrl!, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(AsanSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (showBookmark)
                              TonalIconButton.round(
                                icon: Icon(
                                  Symbols.bookmark_rounded,
                                  weight: 600,
                                  fill: isSaved ? 1 : 0,
                                  color: isSaved
                                      ? AsanColorScheme.primary
                                      : AsanColorScheme.secondary,
                                ),
                                onPressed: onIconPressed,
                              ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AsanColorScheme.surface,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Symbols.schedule_rounded,
                                      size: 16,
                                      weight: 600,
                                      color: AsanColorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      totalTime,
                                      style: AsanTextTheme.labelSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AsanSpacing.sm),
            Text(
              recipeName,
              style: AsanTextTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AsanSpacing.xs),
            Text(
              mealCategory,
              style: AsanTextTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
