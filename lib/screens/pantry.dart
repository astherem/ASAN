import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _searchQuery = '';
  AsanFilterSelection? _activeFilters;

  List<String> get _activeFilterLabels => [
    ...?_activeFilters?.expirationStatuses,
    ...?_activeFilters?.foodGroups,
  ];

  Future<void> _showFilters() async {
    final selection = await showModalBottomSheet<AsanFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: filterSheetInitialSize(context),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AsanFilterList(
          scrollController: scrollController,
          menuType: AsanFilterMenuType.pantry,
        ),
      ),
    );
    if (selection != null && mounted) {
      setState(() => _activeFilters = selection);
    }
  }

  void _removeFilter(String label) {
    final filters = _activeFilters;
    if (filters == null) return;

    final expirationStatuses = {...filters.expirationStatuses}..remove(label);
    final foodGroups = {...filters.foodGroups}..remove(label);
    setState(() {
      _activeFilters = filters.copyWith(
        expirationStatuses: expirationStatuses,
        foodGroups: foodGroups,
      );
    });
  }

  void _showAddPantryItemDialog(BuildContext context) {
    final formKey = GlobalKey<_AddPantryItemFormState>();

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Scaffold(
              appBar: FullScreenDialogHeader(
                screenTitle: 'Add Pantry Item',
                onBackPressed: () async {
                  final formState = formKey.currentState;
                  if (formState == null || !formState.hasChanges) {
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }

                  final shouldDiscard = await AsanAlertDialog.show(context);
                  if (shouldDiscard == true && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              body: AddPantryItemForm(key: formKey),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AsanAppBar(
        screenTitle: 'Pantry',
        icon: const Icon(Symbols.add_rounded),
        onIconPressed: () {
          _showAddPantryItemDialog(context);
        },
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            38 +
                AsanSpacing.md +
                (_activeFilterLabels.isEmpty ? 0 : 32 + AsanSpacing.md),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AsanSearchBar(
                        hintText: 'Search pantry...',
                        onChanged: (query) =>
                            setState(() => _searchQuery = query),
                      ),
                    ),
                    const SizedBox(width: AsanSpacing.sm),
                    FilledIconButton(
                      icon: const Icon(Symbols.tune_rounded),
                      isActive: _activeFilterLabels.isNotEmpty,
                      badgeCount: _activeFilterLabels.length,
                      onPressed: _showFilters,
                    ),
                  ],
                ),
                if (_activeFilterLabels.isNotEmpty) ...[
                  const SizedBox(height: AsanSpacing.md),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _activeFilterLabels.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AsanSpacing.sm),
                      itemBuilder: (context, index) {
                        final label = _activeFilterLabels[index];
                        return ActiveFilterChip(
                          label: label,
                          onRemoved: () => _removeFilter(label),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AsanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AsanSpacing.md),
            if (_searchQuery.isEmpty || 'September 1'.contains(_searchQuery))
              AsanExpansionTile(title: 'September 1', itemCount: 2),
          ],
        ),
      ),
    );
  }
}

class AddPantryItemForm extends StatefulWidget {
  const AddPantryItemForm({super.key});

  @override
  State<AddPantryItemForm> createState() => _AddPantryItemFormState();
}

class _AddPantryItemFormState extends State<AddPantryItemForm> {
  late final TextEditingController _itemController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;
  String? _foodGroup;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;

  bool get hasChanges =>
      _itemController.text.isNotEmpty ||
      _quantityController.text.isNotEmpty ||
      _unitController.text.isNotEmpty ||
      _notesController.text.isNotEmpty ||
      _foodGroup != null ||
      _purchaseDate != null ||
      _expiryDate != null;

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
    _itemController = TextEditingController();
    _quantityController = TextEditingController();
    _unitController = TextEditingController();
    _notesController = TextEditingController();
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
          ),
          const SizedBox(height: AsanSpacing.md),
          AsanDropdownMenu(
            label: 'Food Group',
            items: asanFoodGroups,
            value: _foodGroup,
            hintText: 'Select a food group',
            onChanged: (value) {
              if (value != null) setState(() => _foodGroup = value);
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
            label: 'Add to Pantry',
            height: 38,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
