import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/selections.dart';

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  String _searchQuery = '';
  AsanFilterSelection? _activeFilters;

  List<String> get _activeFilterLabels => [
    ...?_activeFilters?.purchaseStatuses,
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
          menuType: AsanFilterMenuType.groceries,
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

    final purchaseStatuses = {...filters.purchaseStatuses}..remove(label);
    final foodGroups = {...filters.foodGroups}..remove(label);
    setState(() {
      _activeFilters = filters.copyWith(
        purchaseStatuses: purchaseStatuses,
        foodGroups: foodGroups,
      );
    });
  }

  void _showAddGroceryDialog(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Scaffold(
              appBar: const FullScreenDialogHeader(
                screenTitle: 'Add Grocery Item',
              ),
              body: Padding(
                padding: const EdgeInsets.all(AsanSpacing.lg),
                child: Text(
                  'Add a grocery item',
                  style: AsanTextTheme.bodyMedium,
                ),
              ),
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
        screenTitle: 'Groceries',
        icon: const Icon(Symbols.add_rounded),
        onIconPressed: () => _showAddGroceryDialog(context),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            38 + AsanSpacing.md +
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
                        hintText: 'Search groceries...',
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
            if (_searchQuery.isEmpty ||
                'ground pork meat'.contains(_searchQuery.toLowerCase()))
              const AsanListTile(
                itemName: 'ground pork',
                quantity: '1/4',
                unit: 'kg',
                category: 'meat',
                purchasedDate: 'bought August 10',
              ),
          ],
        ),
      ),
    );
  }
}
