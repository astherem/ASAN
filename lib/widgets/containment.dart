import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';

// LIST TILE
class AsanListTile extends StatefulWidget {
  final String itemName;
  final String amount;
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
    required this.amount,
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
                          '${widget.amount} ${widget.unit}',
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
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AsanSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: widget.titleWidget!),
                  const SizedBox(width: AsanSpacing.sm),
                  Transform.translate(
                    // Center the chevron on the title label, not the whole field.
                    offset: const Offset(0, -8),
                    child: chevron,
                  ),
                ],
              ),
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
  final Uint8List? imageBytes;
  final String totalTime;
  final bool isSaved;
  final bool showBookmark;
  final VoidCallback? onIconPressed;
  final VoidCallback? onTap;
  final VoidCallback? onViewPressed;

  const RecipeCard({
    super.key,
    required this.recipeName,
    required this.mealCategory,
    this.imageUrl,
    this.imageBytes,
    required this.totalTime,
    this.isSaved = false,
    this.showBookmark = true,
    this.onIconPressed,
    this.onTap,
    this.onViewPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.expand(
          child: Column(
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
                        if (imageBytes != null)
                          Image.memory(imageBytes!, fit: BoxFit.cover)
                        else if (imageUrl == null || imageUrl!.isEmpty)
                          Container(
                            color: AsanColorScheme.container,
                            child: const Icon(
                              Symbols.restaurant_rounded,
                              size: 36,
                              color: AsanColorScheme.inactive,
                            ),
                          )
                        else
                          Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AsanColorScheme.container,
                                  child: const Icon(
                                    Symbols.restaurant_rounded,
                                    size: 36,
                                    color: AsanColorScheme.inactive,
                                  ),
                                ),
                          ),
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
                                    horizontal: AsanSpacing.sm,
                                    vertical: AsanSpacing.xs,
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
                                        style: AsanTextTheme.labelSmall
                                            .copyWith(
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
                mealCategory.trim().isEmpty
                    ? ''
                    : '${mealCategory.trim()[0].toUpperCase()}${mealCategory.trim().substring(1).toLowerCase()}',
                style: AsanTextTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (onViewPressed != null)
                AsanTextButton(
                  label: 'View',
                  onPressed: onViewPressed,
                  padding: const EdgeInsets.symmetric(vertical: AsanSpacing.sm),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// DIVIDER
class AsanDivider extends StatelessWidget {
  final double thickness;
  final Color? color;
  final bool vertical;

  const AsanDivider({
    super.key,
    this.thickness = 1,
    this.color,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return VerticalDivider(
        width: thickness,
        thickness: thickness,
        color: color ?? AsanColorScheme.container,
      );
    }
    return Divider(
      height: thickness,
      thickness: thickness,
      color: color ?? AsanColorScheme.container,
    );
  }
}

// MEAL CARD
class MealCard extends StatelessWidget {
  final String recipeName;
  final String mealCategory;
  final String? mealTime;
  final bool showMealTimeTag;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String totalTime;
  final int servings;
  final VoidCallback? onTap;

  const MealCard({
    super.key,
    required this.recipeName,
    required this.mealCategory,
    this.mealTime,
    this.showMealTimeTag = false,
    this.imageUrl,
    this.imageBytes,
    required this.totalTime,
    required this.servings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageBytes != null
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : imageUrl == null || imageUrl!.isEmpty
                      ? Container(
                          color: AsanColorScheme.container,
                          child: const Icon(
                            Symbols.restaurant_rounded,
                            size: 24,
                            color: AsanColorScheme.inactive,
                          ),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.prefer,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AsanColorScheme.container,
                                child: const Icon(
                                  Symbols.restaurant_rounded,
                                  size: 24,
                                  color: AsanColorScheme.inactive,
                                ),
                              ),
                        ),
                ),
              ),
              const SizedBox(width: AsanSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AsanSpacing.xs,
                  children: [
                    Text(
                      recipeName,
                      style: AsanTextTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 22 / 16,
                        color: AsanColorScheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (showMealTimeTag && mealTime?.trim().isNotEmpty == true) ...[
                          Flexible(
                            child: AsanTag(
                              label: mealTime!,
                              textColor: AsanColorScheme.secondary,
                              color: switch (mealTime!.toLowerCase()) {
                                'breakfast' => AsanColorScheme.yellow,
                                'brunch' => AsanColorScheme.orange,
                                'lunch' => AsanColorScheme.blue,
                                'snack' => AsanColorScheme.pink,
                                'dinner' => AsanColorScheme.purple,
                                _ => AsanColorScheme.container,
                              },
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            mealCategory,
                            style: AsanTextTheme.labelSmall.copyWith(height: 16 / 12, color: AsanColorScheme.secondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Symbols.schedule_rounded,
                          size: 16,
                          weight: 600,
                          color: AsanColorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            totalTime,
                            style: AsanTextTheme.labelSmall.copyWith(
                              height: 16 / 12,
                              color: AsanColorScheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AsanSpacing.sm),
                        const Icon(
                          Symbols.group_rounded,
                          size: 16,
                          weight: 600,
                          color: AsanColorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$servings serving${servings == 1 ? '' : 's'}',
                            style: AsanTextTheme.labelSmall.copyWith(
                              height: 16 / 12,
                              color: AsanColorScheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

// SEARCH CARD
class AsanSearchCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const AsanSearchCard({
    super.key,
    required this.title,
    this.icon = Symbols.search_rounded,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: color ?? AsanColorScheme.container,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AsanSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: AsanColorScheme.onContainer,
                size: 24,
                weight: 600,
                fill: 1,
              ),
              const SizedBox(width: AsanSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AsanTextTheme.bodyMedium.copyWith(
                    color: AsanColorScheme.onContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TAGS
class AsanTag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const AsanTag({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label.isEmpty
        ? label
        : '${label[0].toUpperCase()}${label.substring(1).toLowerCase()}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AsanSpacing.sm,
        vertical: AsanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color ?? AsanColorScheme.container,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        displayLabel,
        style: AsanTextTheme.labelSmall.copyWith(
          color: textColor ??
              (color != null ? Colors.white : AsanColorScheme.onSurface),
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
