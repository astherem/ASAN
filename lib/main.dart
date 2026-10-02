import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'package:asan/screens/groceries_screen.dart';
import 'package:asan/screens/meal_plan_screen.dart';
import 'package:asan/screens/pantry_screen.dart';
import 'package:asan/screens/recipes_screen.dart';

import 'package:asan/models/pantry_item.dart';
import 'package:asan/models/recipes.dart';
import 'package:asan/services/api/recipe_api.dart';
import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/navigations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RecipeApi.loadConfig();
  runApp(DevicePreview(enabled: true, builder: (context) => const Asan()));
}

class Asan extends StatefulWidget {
  const Asan({super.key});

  @override
  State<Asan> createState() => _AsanState();
}

class _AsanState extends State<Asan> {
  final _groceriesKey = GlobalKey<GroceriesScreenState>();
  final _mealPlanKey = GlobalKey<MealPlanScreenState>();
  int _selectedIndex = 0;
  int _groceriesItemCount = 0;
  final List<PantryItem> _receivedPantryItems = [];
  final List<Recipes> _recipes = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asan',
      debugShowCheckedModeBanner: false,

      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,

          primary: AsanColorScheme.primary,
          onPrimary: AsanColorScheme.onPrimary,

          secondary: AsanColorScheme.secondary,
          onSecondary: AsanColorScheme.onSecondary,

          surface: AsanColorScheme.surface,
          onSurface: AsanColorScheme.onSurface,

          error: AsanColorScheme.error,
          onError: AsanColorScheme.onError,

          surfaceContainerHighest: AsanColorScheme.container,
          onSurfaceVariant: AsanColorScheme.onContainer,
        ),
      ),

      home: Scaffold(
      resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            RecipesScreen(
              incomingRecipes: _recipes,
              onRecipesChanged: (recipes) {
                for (var i = 0; i < _recipes.length && i < recipes.length; i++) {
                  final previous = _recipes[i];
                  final updated = recipes[i];
                  if (!identical(previous, updated)) {
                    _mealPlanKey.currentState?.updatePlannedRecipe(
                      previous,
                      updated,
                    );
                  }
                }
                setState(() {
                  _recipes
                    ..clear()
                    ..addAll(recipes);
                });
              },
              onAddToGroceries: (items) async => await _groceriesKey.currentState?.addItems(items),
              onViewGroceries: () => setState(() => _selectedIndex = 3),
              onAddToMealPlan: (recipe) {
                setState(() => _selectedIndex = 1);
                _mealPlanKey.currentState?.addMealFromRecipe(recipe);
              },
            ),
            MealPlanScreen(
              key: _mealPlanKey,
              recipes: _recipes,
              onViewMealPlan: () => setState(() => _selectedIndex = 1),
            ),
            PantryScreen(incomingItems: _receivedPantryItems),
            GroceriesScreen(
              key: _groceriesKey,
              onItemCountChanged: (count) {
                setState(() => _groceriesItemCount = count);
              },
              onItemChecked: (item) {
                setState(() => _receivedPantryItems.add(item));
              },
            ),
          ],
        ),
        bottomNavigationBar: AsanNavigationBar(
          selectedIndex: _selectedIndex,
          groceriesBadgeCount: _groceriesItemCount,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
