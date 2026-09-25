import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/models/recipes.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipes? initialItem;
  final VoidCallback? onDelete;

  const RecipeFormScreen({super.key, this.initialItem, this.onDelete});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<_AddRecipeFormState>();

  bool get _isEditing => widget.initialItem != null;

  Future<void> _handleBackPressed() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      if (context.mounted) Navigator.pop(context);
      return;
    }
    if (formState.currentStep > 0) {
      formState.goToPreviousStep();
      return;
    }
    if (!formState.hasChanges) {
      if (context.mounted) Navigator.pop(context);
      return;
    }
    final shouldDiscard = await AsanAlertDialog.show(context,
      title: 'Discard Changes?',
      content: 'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
      cancelText: 'Cancel',
      destructiveText: 'Discard',
    );
    if (shouldDiscard == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleDelete() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AsanAlertDialog(
      title: 'Delete Recipe?',
      content:
          'This recipe will be permanently removed from your collection and meal plans. Are you sure you want to delete it?',
      cancelText: 'Cancel',
      destructiveText: 'Delete Recipe',
    ),
  );

  if (!mounted) return;

  if (confirmed == true) {
    widget.onDelete?.call();
    Navigator.of(context).pop();
  }
}

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: SafeArea(
        child: Scaffold(
          appBar: FullScreenDialogHeader(
            screenTitle: _isEditing
                ? 'Edit ${widget.initialItem!.name}'
                : 'Add Recipe',
            onBackPressed: _handleBackPressed,
            trailing: _isEditing
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                  icon: const Icon(
                    Symbols.delete_rounded,
                    fill: 1,
                    size: 28,
                    color: AsanColorScheme.error,
                  ),
                  onPressed: _handleDelete,
                )
              : null,
          ),
          body: AddRecipeForm(
            key: _formKey,
            initialItem: widget.initialItem,
            submitLabel: _isEditing ? 'Save' : 'Add to Recipes',
          ),
        ),
      ),
    );
  }
}

class AddRecipeForm extends StatefulWidget {
  final Recipes? initialItem;
  final String submitLabel;

  const AddRecipeForm({
    super.key,
    this.initialItem,
    this.submitLabel = 'Add to Recipes',
  });

  @override
  State<AddRecipeForm> createState() => _AddRecipeFormState();
}

class _AddRecipeFormState extends State<AddRecipeForm> {
  static const int stepCount = 5;
  static const _stepTitles = [
    'Basic Information',
    'Ingredients',
    'Instructions',
    'More Details',
    'Review',
  ];

  late final PageController _pageController;
  late final TextEditingController _itemController;
  late final TextEditingController _notesController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _cookTimeController;
  late final TextEditingController _servingsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _fatsController;
  late final TextEditingController _cholesterolController;
  late final TextEditingController _sodiumController;
  late final TextEditingController _carbohydratesController;
  late final TextEditingController _proteinController;
  String? _mealCategory;
  final Set<String> _idealFor = {};
  bool _itemHasError = false;
  bool _mealCategoryHasError = false;
  int _currentStep = 0;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _imageBytes;

  int get currentStep => _currentStep;

  int get _prepTimeMinutes => int.tryParse(_prepTimeController.text.trim()) ?? 0;
  int get _cookTimeMinutes => int.tryParse(_cookTimeController.text.trim()) ?? 0;
  int get _totalTimeMinutes => _prepTimeMinutes + _cookTimeMinutes;

  final List<_IngredientEntry> _ingredients = [_IngredientEntry()];
  final List<_StepEntry> _steps = [_StepEntry()];

  bool get hasChanges => widget.initialItem == null
      ? _itemController.text.isNotEmpty ||
            _notesController.text.isNotEmpty ||
            _mealCategory != null ||
            _descriptionController.text.isNotEmpty ||
            _prepTimeController.text.isNotEmpty ||
            _cookTimeController.text.isNotEmpty
      : _itemController.text.trim() != widget.initialItem!.name ||
            _notesController.text.trim() != widget.initialItem!.notes ||
            _mealCategory != widget.initialItem!.mealCategory ||
            _descriptionController.text.trim() !=
                widget.initialItem!.description ||
            _prepTimeMinutes != (widget.initialItem!.prepTime) ||
            _cookTimeMinutes != (widget.initialItem!.cookTime);

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _pageController = PageController();
    _itemController = TextEditingController(text: item?.name);
    _descriptionController = TextEditingController(text: item?.description);
    _notesController = TextEditingController(text: item?.notes);
    _prepTimeController = TextEditingController(
      text: item == null || item.prepTime == 0 ? '' : '${item.prepTime}',
    );
    _cookTimeController = TextEditingController(
      text: item == null || item.cookTime == 0 ? '' : '${item.cookTime}',
    );
    _servingsController = TextEditingController(
      text: item == null ? '' : '${item.servings}',
    );
    _caloriesController = TextEditingController(
      text: item == null || item.calories == 0 ? '' : '${item.calories}',
    );
    _fatsController = TextEditingController(
      text: item == null || item.fats == 0 ? '' : '${item.fats}',
    );
    _cholesterolController = TextEditingController(
      text: item == null || item.cholesterol == 0 ? '' : '${item.cholesterol}',
    );
    _sodiumController = TextEditingController(
      text: item == null || item.sodium == 0 ? '' : '${item.sodium}',
    );
    _carbohydratesController = TextEditingController(
      text: item == null || item.carbohydrates == 0 ? '' : '${item.carbohydrates}',
    );
    _proteinController = TextEditingController(
      text: item == null || item.protein == 0 ? '' : '${item.protein}',
    );
    _mealCategory = item?.mealCategory;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _itemController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _fatsController.dispose();
    _cholesterolController.dispose();
    _sodiumController.dispose();
    _carbohydratesController.dispose();
    _proteinController.dispose();
    for (final entry in _ingredients) {
      entry.dispose();
    }
    for (final entry in _steps) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
  final XFile? file = await _imagePicker.pickImage(
    source: source,
    maxWidth: 1200,
    imageQuality: 80,
  );
  if (file == null) return;

  final bytes = await file.readAsBytes();
  if (!mounted) return;
  setState(() => _imageBytes = bytes);
}

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AsanColorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AsanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Recipe Image',
                style: AsanTextTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AsanSpacing.lg),
              PrimaryButton(
                label: 'Take a Photo',
                icon: const Icon(Symbols.photo_camera_rounded, size: 22, weight: 600),
                onPressed: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: AsanSpacing.md),
              SecondaryButton(
                label: 'Choose from Gallery',
                icon: const Icon(Symbols.image_rounded, size: 22, weight: 600),
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientEntry()));
  }

  void _removeIngredient(int index) {
    setState(() {
      final removed = _ingredients.removeAt(index);
      removed.dispose();
    });
  }

  void _addStep() {
    setState(() => _steps.add(_StepEntry()));
  }

  void _removeStep(int index) {
    setState(() {
      final removed = _steps.removeAt(index);
      removed.dispose();
    });
  }

  void goToPreviousStep() {
    if (_currentStep == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      final name = _itemController.text.trim();
      final hasMealCategory = _mealCategory != null;
      setState(() {
        _itemHasError = name.isEmpty;
        _mealCategoryHasError = !hasMealCategory;
      });
      if (name.isEmpty || !hasMealCategory) return;
    }

    if (_currentStep == stepCount - 1) {
      _submit();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == stepCount - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AsanSpacing.lg,
            0,
            AsanSpacing.lg,
            AsanSpacing.md,
          ),
          child: AsanStepProgress(
            stepCount: stepCount,
            currentStep: _currentStep,
            title: _stepTitles[_currentStep],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentStep = index),
            children: [
              _buildBasicInformationStep(),
              _buildIngredientsStep(),
              _buildInstructionsStep(),
              _buildMoreDetailsStep(),
              _buildReviewStep(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AsanSpacing.lg),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: AsanOutlinedButton(
                    label: 'Back',
                    height: 38,
                    onPressed: goToPreviousStep,
                  ),
                ),
                const SizedBox(width: AsanSpacing.sm),
              ],
              Expanded(
                child: SecondaryButton(
                  label: isLastStep ? widget.submitLabel : 'Next',
                  height: 38,
                  onPressed: _goToNextStep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInformationStep() {
    return _StepBody(
      children: [
        AsanImagePicker(
          imageBytes: _imageBytes,
          onTap: _showImageSourcePicker,
        ),
        const SizedBox(height: AsanSpacing.md),
        AsanTextField(
          label: 'Recipe Name',
          hintText: 'Enter recipe name',
          controller: _itemController,
          hasError: _itemHasError,
          required: true,
        ),
        const SizedBox(height: AsanSpacing.md),
        AsanDropdownMenu(
          label: 'Meal Category',
          items: asanMealCategories,
          value: _mealCategory,
          hintText: 'Select a meal category',
          hasError: _mealCategoryHasError,
          required: true,
          onChanged: (value) {
            setState(() {
              _mealCategory = value;
              _mealCategoryHasError = false;
            });
          },
        ),
        const SizedBox(height: AsanSpacing.md),
        Text(
          'Ideal For',
          style: AsanTextTheme.labelSmall.copyWith(
            color: AsanColorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Wrap(
          spacing: AsanSpacing.sm,
          runSpacing: AsanSpacing.sm,
          children: asanMealTimeCategories.map((mealTime) {
            final selected = _idealFor.contains(mealTime);
            return AsanFilterChip(
              label: mealTime,
              isSelected: selected,
              onPressed: () => setState(() {
                selected ? _idealFor.remove(mealTime) : _idealFor.add(mealTime);
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIngredientsStep() {
    return _StepBody(
      children: [
        for (var index = 0; index < _ingredients.length; index++) ...[
          if (index > 0) ...[
            const SizedBox(height: AsanSpacing.md),
            const AsanDivider(),
            const SizedBox(height: AsanSpacing.md),
          ],
          AsanExpansionTile(
            key: ValueKey(_ingredients[index]),
            titleWidget: AsanTextField(
              label: 'Ingredient ${index + 1}',
              hintText: 'Ingredient name',
              controller: _ingredients[index].ingredientController,
            ),
            children: [
              const SizedBox(height: AsanSpacing.sm),
              AsanDropdownMenu(
                label: 'Food Group',
                items: asanFoodGroups,
                value: _ingredients[index].foodGroup,
                hintText: 'Select a food group',
                hasError: _ingredients[index].foodGroupHasError,
                required: true,
                onChanged: (value) {
                  setState(() {
                    _ingredients[index].foodGroup = value;
                    _ingredients[index].foodGroupHasError = false;
                  });
                },
              ),
              const SizedBox(height: AsanSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AsanTextField(
                      label: 'Quantity',
                      hintText: 'Enter quantity',
                      controller: _ingredients[index].quantityController,
                    ),
                  ),
                  const SizedBox(width: AsanSpacing.sm),
                  Expanded(
                    child: AsanTextField(
                      label: 'Unit',
                      hintText: 'Enter unit',
                      controller: _ingredients[index].unitController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AsanSpacing.sm),
              AsanTextField(
                label: 'Notes',
                hintText: 'Add notes',
                controller: _ingredients[index].notesController,
              ),
              if (_ingredients.length > 1) ...[
                const SizedBox(height: AsanSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AsanTextButton.red(
                    label: 'Remove Ingredient',
                    onPressed: () => _removeIngredient(index),
                  ),
                ),
              ],
              const SizedBox(height: AsanSpacing.sm),
            ],
          ),
        ],
        const SizedBox(height: AsanSpacing.md),
        PrimaryButton(
          label: 'Add Ingredient',
          icon: const Icon(Symbols.add_rounded, size: 24, weight: 600),
          onPressed: _addIngredient,
        ),
      ],
    );
  }

  Widget _buildInstructionsStep() {
    return _StepBody(
      children: [
        for (var index = 0; index < _steps.length; index++) ...[
          if (index > 0) const SizedBox(height: AsanSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AsanTextField(
                  label: 'Step ${index + 1}',
                  hintText: 'Add instruction',
                  controller: _steps[index].instructionController,
                ),
              ),
              if (_steps.length > 1) ...[
                const SizedBox(width: AsanSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: TonalIconButton.square(
                    size: 38,
                    color: AsanColorScheme.error,
                    icon: const Icon(Symbols.delete_rounded, size: 24, weight: 600),
                    onPressed: () => _removeStep(index),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: AsanSpacing.md),
        PrimaryButton(
          label: 'Add Step',
          icon: const Icon(Symbols.add_rounded, size: 24, weight: 600),
          onPressed: _addStep,
        ),
      ],
    );
  }

  Widget _buildMoreDetailsStep() {
    return _StepBody(
      children: [
        AsanTextField(
          label: 'Prep Time',
          hintText: 'Enter prep time (mins)',
          controller: _prepTimeController,
          required: true,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Cook Time',
          hintText: 'Enter cook time (mins)',
          controller: _cookTimeController,
          required: true,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Serving Size',
          hintText: 'Enter the number of servings',
          controller: _servingsController,
          required: true,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Recipe Notes',
          hintText: 'Add recipe notes',
          controller: _notesController,
        ),
        const SizedBox(height: AsanSpacing.md),
        AsanDivider(),
        const SizedBox(height: AsanSpacing.md),
        Text(
          'Nutrition Information',
          style: AsanTextTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Calories',
          hintText: 'Enter calories (kcal)',
          controller: _caloriesController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Fats',
          hintText: 'Enter fats (g)',
          controller: _fatsController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Colesterol',
          hintText: 'Enter cholesterol (mg)',
          controller: _cholesterolController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Sodium',
          hintText: 'Enter sodium (mg)',
          controller: _sodiumController,
          keyboardType: TextInputType.number
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Carbohydrates',
          hintText: 'Enter carbohydrates (g)',
          controller: _carbohydratesController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Protein',
          hintText: 'Enter protein (g)',
          controller: _proteinController,
          keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildReviewStep() {
    return _StepBody(
      children: [
        _ReviewRow(
          label: 'Recipe Name',
          value: _itemController.text.trim(),
        ),
      ]
    );
  }

  void _submit() {
    final name = _itemController.text.trim();
    final hasMealCategory = _mealCategory != null;
    setState(() {
      _itemHasError = name.isEmpty;
      _mealCategoryHasError = !hasMealCategory;
    });
    if (name.isEmpty || !hasMealCategory) return;

    final prepTime = int.tryParse(_prepTimeController.text.trim());
    final cookTime = int.tryParse(_cookTimeController.text.trim());
    final servings = int.tryParse(_servingsController.text.trim());
    final calories = _optionalNonNegativeInt(_caloriesController.text);
    final fats = _optionalNonNegativeInt(_fatsController.text);
    final cholesterol = _optionalNonNegativeInt(_cholesterolController.text);
    final sodium = _optionalNonNegativeInt(_sodiumController.text);
    final carbohydrates = _optionalNonNegativeInt(_carbohydratesController.text);
    final protein = _optionalNonNegativeInt(_proteinController.text);
    if (prepTime == null || prepTime < 0 ||
        cookTime == null || cookTime < 0 ||
        servings == null || servings <= 0 ||
        calories == null || fats == null || cholesterol == null ||
        sodium == null || carbohydrates == null || protein == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter whole numbers: times and nutrition must be 0 or more, and servings must be at least 1.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      Recipes(
        name: name,
        imageBytes: _imageBytes,
        description: _descriptionController.text.trim(),
        mealCategory: _mealCategory,
        notes: _notesController.text.trim(),
        prepTime: prepTime,
        cookTime: cookTime,
        totalTime: prepTime + cookTime,
        servings: servings,
        calories: calories,
        fats: fats,
        cholesterol: cholesterol,
        sodium: sodium,
        carbohydrates: carbohydrates,
        protein: protein,
      ),
    );
  }

  int? _optionalNonNegativeInt(String value) {
    if (value.trim().isEmpty) return 0;
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed >= 0 ? parsed : null;
  }
}

class _StepBody extends StatelessWidget {
  final List<Widget> children;

  const _StepBody({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AsanTextTheme.labelSmall.copyWith(
            color: AsanColorScheme.inactive,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          style: AsanTextTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _IngredientEntry {
  final TextEditingController ingredientController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String? foodGroup;
  bool foodGroupHasError = false;

  void dispose() {
    ingredientController.dispose();
    quantityController.dispose();
    unitController.dispose();
    notesController.dispose();
  }
}

class _StepEntry {
  final TextEditingController instructionController = TextEditingController();

  void dispose() {
    instructionController.dispose();
  }
}
