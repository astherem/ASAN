import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/recipes.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/containment.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipes recipe;
  final String? imageUrl;
  final bool isSaved;
  final Set<String> idealFor;
  final List<String> ingredients;
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

  static const Map<String, Color> _mealTimeColors = {
    'Breakfast': AsanColorScheme.yellow,
    'Brunch': AsanColorScheme.orange,
    'Lunch': AsanColorScheme.blue,
    'Snack': AsanColorScheme.pink,
    'Dinner': AsanColorScheme.purple,
  };

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      backgroundColor: AsanColorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 390,
                width: double.infinity,
                child: _HeroImage(imageUrl: widget.imageUrl),
              ),
              Expanded(child: Container()),
            ],
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AsanSpacing.lg,
                vertical: AsanSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TonalIconButton.round(
                    icon: const Icon(Symbols.chevron_left_rounded, size: 32),
                    color: AsanColorScheme.secondary,
                    size: 48,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  if (widget.showEditButton)
                    TonalIconButton.round(
                      icon: const Icon(Symbols.edit_rounded, size: 24),
                      color: AsanColorScheme.secondary,
                      size: 48,
                      onPressed: widget.onEdit,
                    )
                  else
                    TonalIconButton.round(
                      icon: Icon(
                        Symbols.bookmark_rounded,
                        size: 28,
                        weight: 600,
                        fill: widget.isSaved ? 1 : 0,
                        color: widget.isSaved
                            ? AsanColorScheme.primary
                            : AsanColorScheme.secondary,
                      ),
                      size: 48,
                      onPressed: widget.onToggleSaved,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 370,
            bottom: 66,
            child: Container(
              decoration: const BoxDecoration(
                color: AsanColorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(AsanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    recipe.name,
                    style: AsanTextTheme.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AsanSpacing.xs),
                  _MetaRow(recipe: recipe),
                  if (widget.idealFor.isNotEmpty) ...[
                    const SizedBox(height: AsanSpacing.sm),
                    _IdealForRow(
                      idealFor: widget.idealFor,
                      colors: _mealTimeColors,
                    ),
                  ],
                  const SizedBox(height: AsanSpacing.md),
                  AsanSegmentedButton(
                    views: _tabs,
                    selectedIndex: _selectedTab,
                    onChanged: (index) =>
                        setState(() => _selectedTab = index),
                  ),
                  const SizedBox(height: AsanSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      child: switch (_selectedTab) {
                        0 => _DetailsTab(recipe: recipe),
                        1 => _IngredientsTab(ingredients: widget.ingredients),
                        _ => _InstructionsTab(
                          instructions: widget.instructions,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                constraints: const BoxConstraints(minHeight: 66),
                padding: const EdgeInsets.symmetric(
                  horizontal: AsanSpacing.lg,
                  vertical: AsanSpacing.md,
                ),
                decoration: const BoxDecoration(
                  color: AsanColorScheme.surface,
                  border: Border(
                    top: BorderSide(color: AsanColorScheme.container),
                  ),
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
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;

  const _HeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
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
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Recipes recipe;

  const _MetaRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          recipe.mealCategory ?? 'Uncategorized',
          style: AsanTextTheme.labelSmall,
        ),
        const SizedBox(width: AsanSpacing.md),
        const SizedBox(
          height: 16,
          child: VerticalDivider(
            width: 1,
            thickness: 1,
            color: AsanColorScheme.container,
          ),
        ),
        const SizedBox(width: AsanSpacing.md),
        const Icon(
          Symbols.local_dining_rounded,
          size: 16,
          color: AsanColorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text('${recipe.prepTime}m prep', style: AsanTextTheme.labelSmall),
        const SizedBox(width: AsanSpacing.sm),
        const Icon(
          Symbols.skillet_rounded,
          fill: 1,
          size: 16,
          color: AsanColorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text('${recipe.cookTime}m cook', style: AsanTextTheme.labelSmall),
      ],
    );
  }
}

class _IdealForRow extends StatelessWidget {
  final Set<String> idealFor;
  final Map<String, Color> colors;

  const _IdealForRow({required this.idealFor, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Ideal for', style: AsanTextTheme.labelSmall),
        const SizedBox(width: AsanSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: idealFor.map((mealTime) {
                return Padding(
                  padding: const EdgeInsets.only(right: AsanSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors[mealTime] ?? AsanColorScheme.container,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      mealTime,
                      style: AsanTextTheme.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
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
          recipe.description.isEmpty ? 'No description added.' : recipe.description,
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
              _NutritionRow(label: 'Calories', value: recipe.calories, unit: 'kcal'),
              _NutritionRow(label: 'Fats', value: recipe.fats, unit: 'g'),
              _NutritionRow(
                label: 'Cholesterol',
                value: recipe.cholesterol,
                unit: 'mg',
              ),
              _NutritionRow(label: 'Sodium', value: recipe.sodium, unit: 'mg'),
              _NutritionRow(
                label: 'Carbohydrates',
                value: recipe.carbohydrates,
                unit: 'g',
              ),
              _NutritionRow(label: 'Protein', value: recipe.protein, unit: 'g'),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final int value;
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
          Row(
            children: [
              Text('$value', style: AsanTextTheme.bodyMedium),
              const SizedBox(width: 4),
              Text(unit, style: AsanTextTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  final List<String> ingredients;

  const _IngredientsTab({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AsanSpacing.lg),
        child: Center(
          child: Text(
            'No ingredients added yet.',
            style: AsanTextTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < ingredients.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: AsanSpacing.sm),
            const AsanDivider(),
            const SizedBox(height: AsanSpacing.sm),
          ],
          Text(ingredients[i], style: AsanTextTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _InstructionsTab extends StatelessWidget {
  final List<String> instructions;

  const _InstructionsTab({required this.instructions});

  @override
  Widget build(BuildContext context) {
    if (instructions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AsanSpacing.lg),
        child: Center(
          child: Text(
            'No instructions added yet.',
            style: AsanTextTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }
}