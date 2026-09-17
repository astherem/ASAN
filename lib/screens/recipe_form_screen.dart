import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/models/recipes.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipes? initialItem;

  const RecipeFormScreen({super.key, this.initialItem});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<_AddRecipeFormState>();

  bool get _isEditing => widget.initialItem != null;

  Future<void> _handleBackPressed() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.hasChanges) {
      if (context.mounted) Navigator.pop(context);
      return;
    }

    final shouldDiscard = await AsanAlertDialog.show(context);
    if (shouldDiscard == true && context.mounted) {
      Navigator.pop(context);
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
  late final TextEditingController _itemController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;
  String? _foodGroup;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  bool _itemHasError = false;
  bool _foodGroupHasError = false;

  bool get hasChanges => widget.initialItem == null
      ? _itemController.text.isNotEmpty ||
            _quantityController.text.isNotEmpty ||
            _unitController.text.isNotEmpty ||
            _notesController.text.isNotEmpty ||
            _foodGroup != null ||
            _purchaseDate != null ||
            _expiryDate != null
      : _itemController.text.trim() != widget.initialItem!.name ||
            _quantityController.text.trim() != widget.initialItem!.quantity ||
            _unitController.text.trim() != widget.initialItem!.unit ||
            _notesController.text.trim() != widget.initialItem!.notes ||
            _foodGroup != widget.initialItem!.foodGroup ||
            _purchaseDate != widget.initialItem!.purchaseDate ||
            _expiryDate != widget.initialItem!.expiryDate;

  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _itemController = TextEditingController(text: item?.name);
    _quantityController = TextEditingController(text: item?.quantity);
    _unitController = TextEditingController(text: item?.unit);
    _notesController = TextEditingController(text: item?.notes);
    _foodGroup = item?.foodGroup;
    _purchaseDate = item?.purchaseDate;
    _expiryDate = item?.expiryDate;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayHint = _formatDate(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(AsanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AsanTextField(
            label: 'Item Name',
            hintText: 'Enter item name',
            controller: _itemController,
            hasError: _itemHasError,
            required: true,
          ),
          const SizedBox(height: AsanSpacing.md),
          AsanDropdownMenu(
            label: 'Food Group',
            items: asanFoodGroups,
            value: _foodGroup,
            hintText: 'Select a food group',
            hasError: _foodGroupHasError,
            required: true,
            onChanged: (value) {
              setState(() {
                _foodGroup = value;
                _foodGroupHasError = false;
              });
            },
          ),
          const SizedBox(height: AsanSpacing.md),
          Row(
            children: [
              Expanded(
                child: AsanTextField(
                  label: 'Quantity',
                  hintText: 'Enter quantity',
                  controller: _quantityController,
                ),
              ),
              const SizedBox(width: AsanSpacing.md),
              Expanded(
                child: AsanTextField(
                  label: 'Unit',
                  hintText: 'Enter unit',
                  controller: _unitController,
                ),
              ),
            ],
          ),
          const SizedBox(height: AsanSpacing.md),
          Row(
            children: [
              Expanded(
                child: AsanDateField(
                  label: 'Purchase Date',
                  initialDate: _purchaseDate,
                  hintText: todayHint,
                  onChanged: (date) => _purchaseDate = date,
                ),
              ),
              const SizedBox(width: AsanSpacing.md),
              Expanded(
                child: AsanDateField(
                  label: 'Expiry Date',
                  initialDate: _expiryDate,
                  hintText: todayHint,
                  onChanged: (date) => _expiryDate = date,
                ),
              ),
            ],
          ),
          const SizedBox(height: AsanSpacing.md),
          AsanTextField(
            label: 'Notes',
            hintText: 'Add notes',
            controller: _notesController,
          ),
          const Spacer(),
          PrimaryButton(
            label: widget.submitLabel,
            height: 38,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _itemController.text.trim();
    final hasFoodGroup = _foodGroup != null;
    setState(() {
      _itemHasError = name.isEmpty;
      _foodGroupHasError = !hasFoodGroup;
    });
    if (name.isEmpty || !hasFoodGroup) return;

    Navigator.pop(
      context,
      Recipes(
        name: name,
        quantity: _quantityController.text.trim(),
        unit: _unitController.text.trim(),
        foodGroup: _foodGroup,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        notes: _notesController.text.trim(),
        consumed: widget.initialItem?.consumed ?? false,
        consumedDate: widget.initialItem?.consumedDate,
      ),
    );
  }
}