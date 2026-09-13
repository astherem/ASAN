import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  void _showAddMealDialog(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: Scaffold(
              appBar: const FullScreenDialogHeader(screenTitle: 'Add Meal'),
              body: Padding(
                padding: const EdgeInsets.all(AsanSpacing.lg),
                child: Text('Add a meal', style: AsanTextTheme.bodyMedium),
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
        screenTitle: 'Meals',
        icon: const Icon(Symbols.add_rounded),
        onIconPressed: () => _showAddMealDialog(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38 + AsanSpacing.md),
          child: Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.md),
            child: Row(
              children: [
                const Expanded(child: AsanSearchBar(hintText: 'Search meals')),
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
        child: Text('Your meal plan', style: AsanTextTheme.bodyMedium),
      ),
    );
  }
}
