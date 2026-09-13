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

  void _showFilters() {
    showModalBottomSheet<AsanFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: filterSheetInitialSize(context),
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) =>
            AsanFilterList(scrollController: scrollController),
      ),
    );
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
          preferredSize: const Size.fromHeight(38 + AsanSpacing.md),
          child: Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: AsanSearchBar(
                    hintText: 'Search groceries',
                    onChanged: (query) => setState(() => _searchQuery = query),
                  ),
                ),
                const SizedBox(width: AsanSpacing.sm),
                FilledIconButton(
                  icon: const Icon(Symbols.tune_rounded),
                  onPressed: _showFilters,
                ),
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
            Text('Your grocery list', style: AsanTextTheme.bodyMedium),
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
