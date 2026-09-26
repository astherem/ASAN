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
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Dialog.fullscreen(
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: FullScreenDialogHeader(
              screenTitle: _isEditing
                  ? 'Edit ${widget.initialItem!.name}'
                  : 'Add Recipe',
              onBackPressed: _handleBackPressed,
              trailing: _isEditing
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
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
  bool _prepTimeHasError = false;
  bool _cookTimeHasError = false;
  bool _servingsHasError = false;
  bool _ingredientsHaveError = false;
  bool _instructionsHaveError = false;
  bool _caloriesHasError = false;
  bool _fatsHasError = false;
  bool _cholesterolHasError = false;
  bool _sodiumHasError = false;
  bool _carbohydratesHasError = false;
  bool _proteinHasError = false;
  int _currentStep = 0;
  int _reviewTab = 0;
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _imageBytes;

  int get currentStep => _currentStep;

  int get _prepTimeMinutes => int.tryParse(_prepTimeController.text.trim()) ?? 0;
  int get _cookTimeMinutes => int.tryParse(_cookTimeController.text.trim()) ?? 0;

  final List<_IngredientEntry> _ingredients = [];
  final List<_StepEntry> _steps = [];

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
    _imageBytes = item?.imageBytes;
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
    if (item != null) {
      _idealFor.addAll(item.idealFor);
      _idealFor.addAll(item.tags.where(asanMealTimes.contains));
      for (final ingredient in item.ingredients) {
        final index = _ingredients.length;
        _ingredients.add(_IngredientEntry()
          ..ingredientController.text = ingredient
          ..notesController.text = index < item.ingredientNotes.length
              ? item.ingredientNotes[index]
              : ''
          ..aisle = asanAisles.first);
      }
      for (final instruction in item.instructions) {
        _steps.add(_StepEntry()..instructionController.text = instruction);
      }
    }
    if (_ingredients.isEmpty) _ingredients.add(_IngredientEntry());
    if (_steps.isEmpty) _steps.add(_StepEntry());
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
    late final _IngredientEntry removed;
    setState(() {
      removed = _ingredients.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
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
      final prepTime = int.tryParse(_prepTimeController.text.trim());
      final cookTime = int.tryParse(_cookTimeController.text.trim());
      final servings = int.tryParse(_servingsController.text.trim());
      final prepTimeInvalid = prepTime == null || prepTime < 0;
      final cookTimeInvalid = cookTime == null || cookTime < 0;
      final servingsInvalid = servings == null || servings <= 0;
      setState(() {
        _itemHasError = name.isEmpty;
        _mealCategoryHasError = !hasMealCategory;
        _prepTimeHasError = prepTimeInvalid;
        _cookTimeHasError = cookTimeInvalid;
        _servingsHasError = servingsInvalid;
      });
      if (name.isEmpty || !hasMealCategory || prepTimeInvalid || cookTimeInvalid || servingsInvalid) return;
    }

    if (_currentStep == 1) {
      final hasMissingIngredient = _ingredients.any(
        (entry) => entry.ingredientController.text.trim().isEmpty,
      );
      final hasMissingAisle = _ingredients.any((entry) => entry.aisle == null);
      setState(() {
        _ingredientsHaveError = hasMissingIngredient;
        for (final entry in _ingredients) {
          entry.aisleHasError = entry.aisle == null;
          if (entry.aisleHasError) entry.isExpanded = true;
        }
      });
      if (hasMissingIngredient || hasMissingAisle) return;
    }

    if (_currentStep == 2) {
      final hasMissingInstruction = _steps.any(
        (entry) => entry.instructionController.text.trim().isEmpty,
      );
      setState(() => _instructionsHaveError = hasMissingInstruction);
      if (hasMissingInstruction) return;
    }

    if (_currentStep == 3 && !_validateNutrition()) return;

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
          errorText: 'Recipe name is required.',
          required: true,
          onChanged: (_) {
            if (_itemHasError) {
              setState(() => _itemHasError = false);
            }
          },
        ),
        const SizedBox(height: AsanSpacing.md),
        AsanDropdownMenu(
          label: 'Dish Type',
          items: asanDishTypes,
          value: _mealCategory,
          hintText: 'Select a dish type',
          hasError: _mealCategoryHasError,
          errorText: 'Select a dish type.',
          required: true,
          onChanged: (value) {
            setState(() {
              _mealCategory = value;
              _mealCategoryHasError = false;
            });
          },
        ),
        const SizedBox(height: AsanSpacing.md),
        Row(
          children: [
            Expanded(
              child: AsanTextField(
                label: 'Prep Time',
                hintText: 'Enter time (mins)',
                controller: _prepTimeController,
                required: true,
                hasError: _prepTimeHasError,
                errorText: _prepTimeController.text.trim().isEmpty
                    ? 'Prep time is required.'
                    : 'Enter a whole number of 0 or more.',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _prepTimeHasError = false),
              ),
            ),
            const SizedBox(width: AsanSpacing.md),
            Expanded(
              child: AsanTextField(
                label: 'Cook Time',
                hintText: 'Enter time (mins)',
                controller: _cookTimeController,
                required: true,
                hasError: _cookTimeHasError,
                errorText: _cookTimeController.text.trim().isEmpty
                    ? 'Cook time is required.'
                    : 'Enter a whole number of 0 or more.',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _cookTimeHasError = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AsanSpacing.md),
        AsanTextField(
          label: 'Serving Size',
          hintText: 'Enter number of servings',
          controller: _servingsController,
          required: true,
          hasError: _servingsHasError,
          errorText: _servingsController.text.trim().isEmpty
              ? 'Serving size is required.'
              : 'Enter a whole number of at least 1.',
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _servingsHasError = false),
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
          children: asanMealTimes.map((mealTime) {
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
          Column(
            key: ValueKey(_ingredients[index]),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AsanTextField(
                      label: 'Ingredient ${index + 1}',
                      hintText: 'Enter ingredient name',
                      controller: _ingredients[index].ingredientController,
                      required: true,
                      hasError: _ingredientsHaveError &&
                          _ingredients[index].ingredientController.text
                              .trim()
                              .isEmpty,
                      errorText: 'Ingredient is required.',
                      onChanged: (_) {
                        if (_ingredientsHaveError) {
                          setState(() {
                            _ingredientsHaveError = _ingredients.any(
                              (entry) => entry.ingredientController.text
                                  .trim()
                                  .isEmpty,
                            );
                          });
                        }
                      },
                      labelAction: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () => setState(() {
                          _ingredients[index].isExpanded =
                              !_ingredients[index].isExpanded;
                        }),
                        icon: Icon(
                          _ingredients[index].isExpanded
                              ? Symbols.keyboard_arrow_up_rounded
                              : Symbols.keyboard_arrow_down_rounded,
                          color: AsanColorScheme.secondary,
                          size: 24,
                          weight: 600,
                        ),
                      ),
                    ),
                  ),
                  if (_ingredients.length > 1) ...[
                    const SizedBox(width: 16),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 24 + AsanSpacing.sm,
                      ),
                      child: TonalIconButton.square(
                        size: 38,
                        color: AsanColorScheme.error,
                        icon: const Icon(
                          Symbols.delete_rounded,
                          size: 24,
                          weight: 600,
                        ),
                        onPressed: () => _removeIngredient(index),
                      ),
                    ),
                  ],
                ],
              ),
              if (_ingredients[index].isExpanded) ...[
              const SizedBox(height: AsanSpacing.sm),
              AsanDropdownMenu(
                label: 'Aisle',
                items: asanAisles,
                value: _ingredients[index].aisle,
                hintText: 'Select aisle',
                hasError: _ingredients[index].aisleHasError,
                errorText: 'Aisle is required.',
                required: true,
                onChanged: (value) {
                  setState(() {
                    _ingredients[index].aisle = value;
                    _ingredients[index].aisleHasError = false;
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
                  const SizedBox(width: AsanSpacing.md),
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
                label: 'Ingredient Note',
                hintText: 'Add ingredient note',
                controller: _ingredients[index].notesController,
              ),
              const SizedBox(height: AsanSpacing.sm),
              ],
            ],
          ),
        ],
        const SizedBox(height: AsanSpacing.md),
        PrimaryButton(
          label: 'Add ingredient',
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
                  expandsWithContent: true,
                  required: true,
                  hasError: _instructionsHaveError &&
                      _steps[index].instructionController.text.trim().isEmpty,
                  errorText: 'Instruction is required.',
                  onChanged: (_) {
                    if (_instructionsHaveError) {
                      setState(() {
                        _instructionsHaveError = _steps.any(
                          (entry) => entry.instructionController.text
                              .trim()
                              .isEmpty,
                        );
                      });
                    }
                  },
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
          label: 'Add step',
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
          label: 'Description',
          hintText: 'Add recipe description',
          controller: _descriptionController,
          expandsWithContent: true,
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Recipe Note',
          hintText: 'Add recipe note',
          controller: _notesController,
          expandsWithContent: true,
        ),
        const SizedBox(height: AsanSpacing.md),
        const AsanDivider(),
        const SizedBox(height: AsanSpacing.md),
        Text(
          'Tags',
          style: AsanTextTheme.bodyMedium.copyWith(
            color: AsanColorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Text(
          'Diet',
          style: AsanTextTheme.labelSmall.copyWith(
            color: AsanColorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Wrap(
          spacing: AsanSpacing.sm,
          runSpacing: AsanSpacing.sm,
          children: asanDiets.map((diet) {
            final selected = _idealFor.contains(diet);
            return AsanFilterChip(
              label: diet,
              isSelected: selected,
              onPressed: () => setState(() {
                selected ? _idealFor.remove(diet) : _idealFor.add(diet);
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Text(
          'Cuisine',
          style: AsanTextTheme.labelSmall.copyWith(
            color: AsanColorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Wrap(
          spacing: AsanSpacing.sm,
          runSpacing: AsanSpacing.sm,
          children: asanCuisines.map((cuisine) {
            final selected = _idealFor.contains(cuisine);
            return AsanFilterChip(
              label: cuisine,
              isSelected: selected,
              onPressed: () => setState(() {
                selected ? _idealFor.remove(cuisine) : _idealFor.add(cuisine);
              }),
            );
          }).toList(),
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
          hasError: _caloriesHasError,
          errorText: 'Enter a whole number of 0 or more.',
          onChanged: (_) => setState(() => _caloriesHasError = false),
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Fats',
          hintText: 'Enter fats (g)',
          controller: _fatsController,
          keyboardType: TextInputType.number,
          hasError: _fatsHasError,
          errorText: 'Enter a whole number of 0 or more.',
          onChanged: (_) => setState(() => _fatsHasError = false),
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Colesterol',
          hintText: 'Enter cholesterol (mg)',
          controller: _cholesterolController,
          keyboardType: TextInputType.number,
          hasError: _cholesterolHasError,
          errorText: 'Enter a whole number of 0 or more.',
          onChanged: (_) => setState(() => _cholesterolHasError = false),
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Sodium',
          hintText: 'Enter sodium (mg)',
          controller: _sodiumController,
          keyboardType: TextInputType.number,
          hasError: _sodiumHasError,
          errorText: 'Enter a whole number of 0 or more.',
          onChanged: (_) => setState(() => _sodiumHasError = false),
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Carbohydrates',
          hintText: 'Enter carbohydrates (g)',
          controller: _carbohydratesController,
          keyboardType: TextInputType.number,
          hasError: _carbohydratesHasError,
          errorText: 'Enter a whole number of 0 or more.',
          onChanged: (_) => setState(() => _carbohydratesHasError = false),
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextField(
          label: 'Protein',
          hintText: 'Enter protein (g)',
          controller: _proteinController,
          keyboardType: TextInputType.number,
          hasError: _proteinHasError,
          errorText: 'Enter a whole number of 0 or more.',
          onChanged: (_) => setState(() => _proteinHasError = false),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final width = MediaQuery.sizeOf(context).width;
    final tags = _idealFor.where((tag) => !asanMealTimes.contains(tag)).toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: width * 3 / 4,
            child: _imageBytes == null
                ? Container(
                    color: AsanColorScheme.container,
                    child: const Icon(Symbols.restaurant_rounded, size: 64, color: AsanColorScheme.inactive),
                  )
                : Image.memory(_imageBytes!, width: double.infinity, fit: BoxFit.cover),
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
                Text(_itemController.text.trim().isEmpty ? 'Recipe name' : _itemController.text.trim(), style: AsanTextTheme.headlineSmall),
                const SizedBox(height: AsanSpacing.sm),
                _ReviewMetaRow(
                  dishType: _mealCategory,
                  prepTime: int.tryParse(_prepTimeController.text) ?? 0,
                  cookTime: int.tryParse(_cookTimeController.text) ?? 0,
                  servings: int.tryParse(_servingsController.text) ?? 0,
                ),
                if (_idealFor.any(asanMealTimes.contains)) ...[
                  const SizedBox(height: AsanSpacing.xs),
                  Text(
                    'Ideal for ${_idealFor.where(asanMealTimes.contains).join(', ')}',
                    style: AsanTextTheme.labelSmall.copyWith(
                      color: AsanColorScheme.inactive,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: AsanSpacing.sm),
                  Wrap(spacing: AsanSpacing.xs, runSpacing: AsanSpacing.xs, children: tags.map((tag) => AsanTag(label: tag)).toList()),
                ],
                const SizedBox(height: AsanSpacing.md),
                AsanSegmentedButton(
                  views: const ['Details', 'Ingredients', 'Instructions'],
                  selectedIndex: _reviewTab,
                  onChanged: (index) => setState(() => _reviewTab = index),
                ),
                const SizedBox(height: AsanSpacing.md),
                switch (_reviewTab) {
                  0 => _buildReviewDetailsTab(),
                  1 => _buildReviewIngredientsTab(),
                  _ => _buildReviewInstructionsTab(),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDetailsTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Description', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: AsanSpacing.sm),
      Text(_descriptionController.text.trim().isEmpty ? '-' : _descriptionController.text.trim(), style: AsanTextTheme.bodyMedium),
      const SizedBox(height: AsanSpacing.md),
      Container(
        padding: const EdgeInsets.all(AsanSpacing.md),
        decoration: BoxDecoration(color: AsanColorScheme.container, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Nutrition', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AsanSpacing.sm),
          _ReviewNutritionRow(label: 'Calories', controller: _caloriesController, unit: 'kcal'),
          _ReviewNutritionRow(label: 'Fats', controller: _fatsController, unit: 'g'),
          _ReviewNutritionRow(label: 'Cholesterol', controller: _cholesterolController, unit: 'mg'),
          _ReviewNutritionRow(label: 'Sodium', controller: _sodiumController, unit: 'mg'),
          _ReviewNutritionRow(label: 'Carbohydrates', controller: _carbohydratesController, unit: 'g'),
          _ReviewNutritionRow(label: 'Protein', controller: _proteinController, unit: 'g'),
        ]),
      ),
    ],
  );

  Widget _buildReviewIngredientsTab() {
    final ingredients = _ingredients.where((entry) => entry.ingredientController.text.trim().isNotEmpty).toList();
    final servings = int.tryParse(_servingsController.text) ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Ingredients for', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
            Text('$servings ${servings == 1 ? 'serving' : 'servings'}', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: AsanSpacing.md),
        if (ingredients.isEmpty)
          Padding(padding: const EdgeInsets.only(top: AsanSpacing.lg), child: Center(child: Text('No ingredients added yet.', style: AsanTextTheme.bodyMedium))),
        for (var i = 0; i < ingredients.length; i++) ...[
          if (i > 0) ...[const SizedBox(height: AsanSpacing.xs), const Divider(color: AsanColorScheme.container), const SizedBox(height: AsanSpacing.xs)],
          _ReviewIngredientRow(entry: ingredients[i]),
        ],
      ],
    );
  }

  Widget _buildReviewInstructionsTab() => _ReviewInstructions(
    instructions: _steps.map((entry) => entry.instructionController.text.trim()).where((value) => value.isNotEmpty).toList(),
    notes: _notesController.text.trim(),
  );

  void _submit() {
    final hasMissingIngredient = _ingredients.any(
      (entry) => entry.ingredientController.text.trim().isEmpty,
    );
    final hasMissingAisle = _ingredients.any((entry) => entry.aisle == null);
    final hasMissingInstruction = _steps.any(
      (entry) => entry.instructionController.text.trim().isEmpty,
    );
    if (hasMissingIngredient || hasMissingAisle || hasMissingInstruction) {
      setState(() {
        _ingredientsHaveError = hasMissingIngredient;
        for (final entry in _ingredients) {
          entry.aisleHasError = entry.aisle == null;
          if (entry.aisleHasError) entry.isExpanded = true;
        }
        _instructionsHaveError = hasMissingInstruction;
      });
      return;
    }

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
    final calories = _optionalNonNegativeInt(_caloriesController.text) ?? 0;
    final fats = _optionalNonNegativeInt(_fatsController.text) ?? 0;
    final cholesterol = _optionalNonNegativeInt(_cholesterolController.text) ?? 0;
    final sodium = _optionalNonNegativeInt(_sodiumController.text) ?? 0;
    final carbohydrates = _optionalNonNegativeInt(_carbohydratesController.text) ?? 0;
    final protein = _optionalNonNegativeInt(_proteinController.text) ?? 0;
    if (!_validateNutrition()) return;
    if (prepTime == null || prepTime < 0 ||
        cookTime == null || cookTime < 0 ||
        servings == null || servings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter whole numbers: times must be 0 or more, and servings must be at least 1.'),
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
        tags: _idealFor.where((tag) => !asanMealTimes.contains(tag)).toList(),
        idealFor: _idealFor.where(asanMealTimes.contains).toList(),
        ingredients: _ingredients
            .map((entry) => entry.ingredientController.text.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        ingredientNotes: _ingredients
            .map((entry) => entry.notesController.text.trim())
            .toList(),
        instructions: _steps
            .map((entry) => entry.instructionController.text.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      ),
    );
  }

  int? _optionalNonNegativeInt(String value) {
    if (value.trim().isEmpty) return 0;
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  bool _validateNutrition() {
    final caloriesInvalid = _optionalNonNegativeInt(_caloriesController.text) == null;
    final fatsInvalid = _optionalNonNegativeInt(_fatsController.text) == null;
    final cholesterolInvalid = _optionalNonNegativeInt(_cholesterolController.text) == null;
    final sodiumInvalid = _optionalNonNegativeInt(_sodiumController.text) == null;
    final carbohydratesInvalid = _optionalNonNegativeInt(_carbohydratesController.text) == null;
    final proteinInvalid = _optionalNonNegativeInt(_proteinController.text) == null;
    setState(() {
      _caloriesHasError = caloriesInvalid;
      _fatsHasError = fatsInvalid;
      _cholesterolHasError = cholesterolInvalid;
      _sodiumHasError = sodiumInvalid;
      _carbohydratesHasError = carbohydratesInvalid;
      _proteinHasError = proteinInvalid;
    });
    return !(caloriesInvalid || fatsInvalid || cholesterolInvalid || sodiumInvalid || carbohydratesInvalid || proteinInvalid);
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

class _ReviewNutritionRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;

  const _ReviewNutritionRow({required this.label, required this.controller, required this.unit});

  @override
  Widget build(BuildContext context) {
    final value = controller.text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AsanTextTheme.bodyMedium),
          Text(value.isEmpty || value == '0' ? '-' : '$value $unit', style: AsanTextTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ReviewMetaRow extends StatelessWidget {
  final String? dishType;
  final int prepTime;
  final int cookTime;
  final int servings;

  const _ReviewMetaRow({this.dishType, required this.prepTime, required this.cookTime, required this.servings});

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AsanSpacing.sm,
    children: [
      if (dishType?.trim().isNotEmpty == true) ...[
        Text(dishType!.trim(), style: AsanTextTheme.labelSmall),
        Container(width: 1, height: 16, color: AsanColorScheme.inactive.withValues(alpha: 0.5)),
      ],
      const Icon(Symbols.local_dining_rounded, size: 16, color: AsanColorScheme.secondary, weight: 600),
      Text('${prepTime}m prep', style: AsanTextTheme.labelSmall),
      const Icon(Symbols.skillet_rounded, fill: 1, size: 16, color: AsanColorScheme.secondary),
      Text('${cookTime}m cook', style: AsanTextTheme.labelSmall),
      if (servings > 0) ...[
        const Icon(Symbols.group_rounded, size: 16, color: AsanColorScheme.secondary, fill: 1),
        Text('$servings servings', style: AsanTextTheme.labelSmall),
      ],
    ],
  );
}

class _ReviewIngredientRow extends StatelessWidget {
  final _IngredientEntry entry;

  const _ReviewIngredientRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final quantity = [entry.quantityController.text.trim(), entry.unitController.text.trim()]
        .where((value) => value.isNotEmpty)
        .join(' ');
    final notes = entry.notesController.text.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.ingredientController.text.trim(), style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: AsanSpacing.xs),
                Text(notes, style: AsanTextTheme.bodyMedium.copyWith(color: AsanColorScheme.secondary)),
              ],
            ],
          ),
        ),
        if (quantity.isNotEmpty) ...[
          const SizedBox(width: AsanSpacing.md),
          Text(quantity, style: AsanTextTheme.bodyMedium, textAlign: TextAlign.right),
        ],
      ],
    );
  }
}

class _ReviewInstructions extends StatelessWidget {
  final List<String> instructions;
  final String notes;

  const _ReviewInstructions({required this.instructions, required this.notes});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (instructions.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AsanSpacing.lg),
          child: Center(child: Text('No instructions added yet.', style: AsanTextTheme.bodyMedium)),
        ),
      for (var i = 0; i < instructions.length; i++) ...[
        if (i > 0) const SizedBox(height: AsanSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${i + 1}.', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: AsanSpacing.sm),
            Expanded(child: Text(instructions[i], style: AsanTextTheme.bodyMedium)),
          ],
        ),
      ],
      if (notes.isNotEmpty) ...[
        const SizedBox(height: AsanSpacing.md),
        Container(
          padding: const EdgeInsets.all(AsanSpacing.md),
          decoration: BoxDecoration(color: AsanColorScheme.container, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Notes', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AsanSpacing.sm),
              Text(notes, style: AsanTextTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ],
  );
}

class _IngredientEntry {
  final TextEditingController ingredientController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String? aisle;
  bool aisleHasError = false;
  bool isExpanded = true;

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
