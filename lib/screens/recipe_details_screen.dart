import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/recipes.dart';
import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/selections.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipes recipe;
  final String? imageUrl;
  final bool isSaved;
  final Set<String> idealFor;
  final List<String> ingredients;
  final List<String> ingredientNotes;
  final List<String> instructions;
  final bool showEditButton;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onAddToGroceries;
  final VoidCallback? onAddToMealPlan;

  const RecipeDetailsScreen({
    super.key,
    required this.recipe,
    this.imageUrl,
    this.isSaved = false,
    this.idealFor = const {},
    this.ingredients = const [],
    this.ingredientNotes = const [],
    this.instructions = const [],
    this.showEditButton = false,
    this.onEdit,
    this.onToggleSaved,
    this.onAddToGroceries,
    this.onAddToMealPlan,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  static const _tabs = ['Details', 'Ingredients', 'Instructions'];

  int _selectedTab = 0;
  late int _ingredientServings;
  bool _imageScrolledPastHeader = false;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _ingredientServings = widget.recipe.servings > 0 ? widget.recipe.servings : 1;
    _isSaved = widget.isSaved;
  }

  @override
  void didUpdateWidget(covariant RecipeDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) _isSaved = widget.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final tags = [...recipe.tags.where((tag) => !asanMealTimes.contains(tag))];
    final cuisine = recipe.cuisine?.trim();
    if (cuisine != null &&
        cuisine.isNotEmpty &&
        !tags.any((tag) => tag.toLowerCase() == cuisine.toLowerCase())) {
      tags.add(cuisine);
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroHeight = screenWidth * 3 / 4;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AsanColorScheme.surface,
      body: Stack(
        children: [
          NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                final scrolled = notification.metrics.pixels >= heroHeight - 72;
                if (scrolled != _imageScrolledPastHeader) {
                  setState(() => _imageScrolledPastHeader = scrolled);
                }
                return false;
              },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: heroHeight,
                    child: _HeroImage(
                      imageUrl: widget.imageUrl,
                      imageBytes: widget.recipe.imageBytes,
                    ),
                  ),
                  Container(
              decoration: const BoxDecoration(
                color: AsanColorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(AsanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    recipe.name,
                    style: AsanTextTheme.headlineSmall,
                  ),
                  const SizedBox(height: AsanSpacing.sm),
                  _MetaRow(
                    recipe: recipe,
                    dishType: recipe.mealCategory?.trim().isNotEmpty == true
                        ? recipe.mealCategory!.trim()
                        : recipe.dishTypes.isNotEmpty
                            ? recipe.dishTypes.first
                            : null,
                  ),
                  if (recipe.idealFor.isNotEmpty || recipe.tags.any(asanMealTimes.contains)) ...[
                    const SizedBox(height: AsanSpacing.sm),
                    _LabelValue(
                      label: 'Ideal for',
                      value: [...recipe.idealFor, ...recipe.tags.where(asanMealTimes.contains)]
                          .toSet()
                          .join(', '),
                      color: AsanColorScheme.inactive,
                      showColon: false,
                      boldLabel: false,
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: AsanSpacing.sm),
                    _TagWrap(tags: tags),
                  ],
                  const SizedBox(height: AsanSpacing.md),
                  AsanSegmentedButton(
                    views: _tabs,
                    selectedIndex: _selectedTab,
                    onChanged: (index) =>
                        setState(() => _selectedTab = index),
                  ),
                  const SizedBox(height: AsanSpacing.md),
                  switch (_selectedTab) {
                        0 => _DetailsTab(recipe: recipe),
                        1 => _IngredientsTab(
                          ingredients: widget.ingredients,
                          ingredientNotes: widget.ingredientNotes,
                          servings: _ingredientServings,
                          baseServings: widget.recipe.servings > 0
                              ? widget.recipe.servings
                              : 1,
                          onServingsChanged: (value) =>
                              setState(() => _ingredientServings = value),
                        ),
                        _ => _InstructionsTab(
                          instructions: widget.instructions,
                          notes: recipe.notes,
                        ),
                  },
                ],
              ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + AsanSpacing.md,
                left: AsanSpacing.lg,
                right: AsanSpacing.lg,
                bottom: AsanSpacing.md,
              ),
              decoration: BoxDecoration(
                color: _imageScrolledPastHeader
                    ? AsanColorScheme.surface
                    : Colors.transparent,
                boxShadow: _imageScrolledPastHeader
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TonalIconButton.round(
                    icon: const Icon(Symbols.chevron_left_rounded, size: 32),
                    color: AsanColorScheme.secondary,
                    size: 48,
                    showShadow: !_imageScrolledPastHeader,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  if (widget.showEditButton)
                    TonalIconButton.round(
                      icon: const Icon(Symbols.edit_rounded, size: 24),
                      color: AsanColorScheme.secondary,
                      size: 48,
                      showShadow: !_imageScrolledPastHeader,
                      onPressed: widget.onEdit,
                    )
                  else
                    TonalIconButton.round(
                      icon: Icon(
                        Symbols.bookmark_rounded,
                        size: 28,
                        weight: 600,
                        fill: _isSaved ? 1 : 0,
                        color: _isSaved
                            ? AsanColorScheme.primary
                            : AsanColorScheme.secondary,
                      ),
                      size: 48,
                      showShadow: !_imageScrolledPastHeader,
                      onPressed: widget.onToggleSaved == null
                          ? null
                          : () {
                              setState(() => _isSaved = !_isSaved);
                              widget.onToggleSaved!();
                            },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
                constraints: const BoxConstraints(minHeight: 66),
                padding: const EdgeInsets.symmetric(
                  horizontal: AsanSpacing.lg,
                  vertical: AsanSpacing.md,
                ),
                decoration: const BoxDecoration(
                  color: AsanColorScheme.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Add to Groceries',
                        fontSize: 12,
                        icon: const Icon(
                          Symbols.add_shopping_cart_rounded,
                          weight: 600,
                        ),
                        onPressed: widget.onAddToGroceries,
                      ),
                    ),
                    const SizedBox(width: AsanSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Add to Meal Plan',
                        fontSize: 12,
                        icon: const Icon(
                          Symbols.calendar_add_on_rounded,
                          weight: 600,
                        ),
                        onPressed: widget.onAddToMealPlan,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const _HeroImage({required this.imageUrl, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, width: double.infinity, fit: BoxFit.cover);
    }
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: AsanColorScheme.container,
        child: const Icon(
          Symbols.restaurant_rounded,
          size: 64,
          color: AsanColorScheme.inactive,
        ),
      );
    }
    return Image.network(
      imageUrl!,
      width: double.infinity,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AsanColorScheme.container,
        child: const Icon(
          Symbols.restaurant_rounded,
          size: 64,
          color: AsanColorScheme.inactive,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Recipes recipe;
  final String? dishType;

  const _MetaRow({required this.recipe, this.dishType});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AsanSpacing.sm,
      children: [
        if (dishType?.isNotEmpty == true) ...[
          Text(dishType!, style: AsanTextTheme.labelSmall),
          Container(
            width: 1,
            height: 16,
            color: AsanColorScheme.inactive,
          ),
        ],
          ...[
            const Icon(
              Symbols.local_dining_rounded,
              size: 16,
              color: AsanColorScheme.secondary,
              weight: 600,
            ),
            Text('${recipe.prepTime}m prep', style: AsanTextTheme.labelSmall),
          ],
          ...[
            const Icon(
              Symbols.skillet_rounded,
              fill: 1,
              size: 16,
              color: AsanColorScheme.secondary,
            ),
            Text('${recipe.cookTime}m cook', style: AsanTextTheme.labelSmall),
          ],
        if (recipe.servings > 0) ...[
          const Icon(
            Symbols.group_rounded,
            size: 16,
            color: AsanColorScheme.secondary,
            fill: 1,
          ),
          Text('${recipe.servings} servings', style: AsanTextTheme.labelSmall),
        ],
      ],
    );
  }
}

class _TagWrap extends StatelessWidget {
  final List<String> tags;

  const _TagWrap({required this.tags});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AsanSpacing.xs,
    runSpacing: AsanSpacing.xs,
    children: tags.map((tag) => AsanTag(label: tag)).toList(),
  );
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool showColon;
  final bool boldLabel;

  const _LabelValue({
    required this.label,
    required this.value,
    this.color = AsanColorScheme.secondary,
    this.showColon = true,
    this.boldLabel = true,
  });

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: AsanTextTheme.labelSmall.copyWith(color: color),
      children: [
        TextSpan(
          text: showColon ? '$label: ' : '$label ',
          style: TextStyle(
            fontWeight: boldLabel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        TextSpan(text: value),
      ],
    ),
  );
}

class _DetailsTab extends StatelessWidget {
  final Recipes recipe;

  const _DetailsTab({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Description',
          style: AsanTextTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Text(
          _display(recipe.description),
          style: AsanTextTheme.bodyMedium,
        ),
        const SizedBox(height: AsanSpacing.md),
        Container(
          padding: const EdgeInsets.all(AsanSpacing.md),
          decoration: BoxDecoration(
            color: AsanColorScheme.container,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nutrition',
                style: AsanTextTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AsanSpacing.sm),
              _NutritionRow(label: 'Calories', value: recipe.calories == 0 ? null : recipe.calories, unit: 'kcal'),
              _NutritionRow(label: 'Fats', value: recipe.fats == 0 ? null : recipe.fats, unit: 'g'),
              _NutritionRow(
                label: 'Cholesterol',
                value: recipe.cholesterol == 0 ? null : recipe.cholesterol,
                unit: 'mg',
              ),
              _NutritionRow(label: 'Sodium', value: recipe.sodium == 0 ? null : recipe.sodium, unit: 'mg'),
              _NutritionRow(
                label: 'Carbohydrates',
                value: recipe.carbohydrates == 0 ? null : recipe.carbohydrates,
                unit: 'g',
              ),
              _NutritionRow(label: 'Protein', value: recipe.protein == 0 ? null : recipe.protein, unit: 'g'),
            ],
          ),
        ),
      ],
    );
  }
}

String _display(String? value) => value == null || value.trim().isEmpty ? '-' : value;

class _NutritionRow extends StatelessWidget {
  final String label;
  final int? value;
  final String unit;

  const _NutritionRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AsanTextTheme.bodyMedium),
          Text(value == null ? '-' : '$value $unit', style: AsanTextTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  final List<String> ingredients;
  final List<String> ingredientNotes;
  final int servings;
  final int baseServings;
  final ValueChanged<int> onServingsChanged;

  const _IngredientsTab({
    required this.ingredients,
    required this.ingredientNotes,
    required this.servings,
    required this.baseServings,
    required this.onServingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Ingredients for', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ),
            TonalIconButton.round(
              icon: const Icon(Symbols.remove_rounded, size: 16, weight: 600),
              color: servings < 1 ? AsanColorScheme.inactive : AsanColorScheme.secondary,
              backgroundColor: AsanColorScheme.container,
              size: 32,
              showShadow: false,
              onPressed: servings > 1 ? () => onServingsChanged(servings - 1) : null,
            ),
            const SizedBox(width: AsanSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.sm),
              child: Text('$servings ${servings == 1 ? 'serving' : 'servings'}',
                  style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AsanSpacing.xs),
            TonalIconButton.round(
              icon: const Icon(Symbols.add_rounded, size: 20, weight: 600),
              color: AsanColorScheme.secondary,
              backgroundColor: AsanColorScheme.container,
              size: 36,
              showShadow: false,
              onPressed: () => onServingsChanged(servings + 1),
            ),
          ],
        ),
        const SizedBox(height: AsanSpacing.md),
        if (ingredients.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.lg),
            child: Center(
              child: Text('No ingredients added yet.', style: AsanTextTheme.bodyMedium),
            ),
          ),
        for (var i = 0; i < ingredients.length; i++) ...[
          if (i > 0)
            const SizedBox(height: AsanSpacing.xs),
            const Divider(color: AsanColorScheme.container),
            const SizedBox(height: AsanSpacing.xs),
          _IngredientRow(
            ingredient: ingredients[i],
            notes: i < ingredientNotes.length ? ingredientNotes[i] : '',
            multiplier: servings / baseServings,
          ),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String ingredient;
  final String notes;
  final double multiplier;

  const _IngredientRow({required this.ingredient, required this.notes, required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final match = RegExp(
      r'^(\d+(?:\s+\d+/\d+|[./]\d+)?)(?:\s+(cups?|tbsp|tablespoons?|tsp|teaspoons?|g|kg|mg|ml|l|oz|ounces?|lb|lbs|pounds?|cloves?|cans?|slices?|pieces?|pinch(?:es)?))?\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(ingredient.trim());
    final rawUnit = match?.group(2);
    final quantity = match == null
        ? ''
        : '${_scaleQuantity(match.group(1)!, multiplier)}${rawUnit == null ? '' : ' ${_shortUnit(rawUnit)}'}';
    final name = (match?.group(3)?.trim() ?? ingredient.trim())
        .replaceFirst(RegExp(r'^of\s+', caseSensitive: false), '');
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                if (notes.trim().isNotEmpty) ...[
                  const SizedBox(height: AsanSpacing.xs),
                  Text(notes.trim(), style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.inactive)),
                ],
              ],
            ),
          ),
          if (quantity.isNotEmpty) ...[
            const SizedBox(width: AsanSpacing.md),
            Expanded(
              child: Text(quantity, style: AsanTextTheme.bodyMedium, textAlign: TextAlign.right),
            ),
          ],
        ],
      ),
    );
  }

  String _shortUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'cup':
      case 'cups':
        return 'cup';
      case 'tablespoon':
      case 'tablespoons':
      case 'tbsp':
        return 'tbsp';
      case 'teaspoon':
      case 'teaspoons':
      case 'tsp':
        return 'tsp';
      case 'ounce':
      case 'ounces':
      case 'oz':
        return 'oz';
      case 'pound':
      case 'pounds':
      case 'lb':
      case 'lbs':
        return 'lb';
      case 'clove':
      case 'cloves':
        return 'cloves';
      case 'slice':
      case 'slices':
        return 'slices';
      case 'piece':
      case 'pieces':
        return 'pcs';
      case 'pinch':
      case 'pinches':
        return 'pinch';
      default:
        return unit;
    }
  }

  String _scaleQuantity(String raw, double multiplier) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    double amount = 0;
    for (final part in parts) {
      if (part.contains('/')) {
        final fraction = part.split('/');
        if (fraction.length == 2) {
          amount += (double.tryParse(fraction[0]) ?? 0) /
              (double.tryParse(fraction[1]) ?? 1);
        }
      } else {
        amount += double.tryParse(part) ?? 0;
      }
    }
    final scaled = amount * multiplier;
    final whole = scaled.floor();
    final remainder = scaled - whole;
    if (remainder < 0.0001) return '$whole';

    const denominators = [2, 3, 4, 8, 16];
    var bestNumerator = 0;
    var bestDenominator = 1;
    var smallestDifference = double.infinity;
    for (final denominator in denominators) {
      final numerator = (remainder * denominator).round();
      final difference = (remainder - numerator / denominator).abs();
      if (difference < smallestDifference) {
        smallestDifference = difference;
        bestNumerator = numerator;
        bestDenominator = denominator;
      }
    }
    if (bestNumerator == bestDenominator) return '${whole + 1}';
    if (bestNumerator == 0) return '$whole';

    var numerator = bestNumerator;
    var denominator = bestDenominator;
    for (var divisor = denominator; divisor > 1; divisor--) {
      if (numerator % divisor == 0 && denominator % divisor == 0) {
        numerator ~/= divisor;
        denominator ~/= divisor;
      }
    }
    final fraction = '$numerator/$denominator';
    return whole == 0 ? fraction : '$whole $fraction';
  }
}

class _InstructionsTab extends StatelessWidget {
  final List<String> instructions;
  final String notes;

  const _InstructionsTab({required this.instructions, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (instructions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.lg),
            child: Center(
              child: Text('No instructions added yet.', style: AsanTextTheme.bodyMedium),
            ),
          ),
        for (var i = 0; i < instructions.length; i++) ...[
          if (i > 0) const SizedBox(height: AsanSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${i + 1}.',
                style: AsanTextTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AsanSpacing.sm),
              Expanded(
                child: Text(instructions[i], style: AsanTextTheme.bodyMedium),
              ),
            ],
          ),
        ],
        if (notes.trim().isNotEmpty) ...[
          const SizedBox(height: AsanSpacing.md),
          Container(
            padding: const EdgeInsets.all(AsanSpacing.md),
            decoration: BoxDecoration(
              color: AsanColorScheme.container,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Recipe Note', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AsanSpacing.sm),
                Text(notes, style: AsanTextTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
