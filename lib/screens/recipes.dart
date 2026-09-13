import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  void _showAddRecipeDialog(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Scaffold(
              appBar: const FullScreenDialogHeader(screenTitle: 'Add Recipe'),
              body: Padding(
                padding: const EdgeInsets.all(AsanSpacing.lg),
                child: Text('Add a recipe', style: AsanTextTheme.bodyMedium),
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
        screenTitle: 'Recipes',
        icon: const Icon(Symbols.add_rounded, size: 32),
        onIconPressed: () => _showAddRecipeDialog(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38 + AsanSpacing.md),
          child: Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.md),
            child: Row(
              children: [
                const Expanded(
                  child: AsanSearchBar(hintText: 'Search recipes'),
                ),
                const SizedBox(width: AsanSpacing.sm),
                FilledIconButton(
                  icon: const Icon(Symbols.tune_rounded),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AsanSpacing.lg),
        child: Text('Your recipes', style: AsanTextTheme.bodyMedium),
      ),
    );
  }
}
