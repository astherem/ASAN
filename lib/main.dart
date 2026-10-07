import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'package:asan/screens/groceries_screen.dart';
import 'package:asan/screens/meal_plan_screen.dart';
import 'package:asan/screens/pantry_screen.dart';
import 'package:asan/screens/recipes_screen.dart';

import 'package:asan/models/pantry_item.dart';
import 'package:asan/models/grocery_item.dart';
import 'package:asan/models/meal_plans.dart';
import 'package:asan/models/recipes.dart';
import 'package:asan/models/api_recipe.dart';
import 'package:asan/services/api/recipe_api.dart';
import 'package:asan/data/local_storage.dart';
import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/navigations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RecipeApi.loadConfig();
  final storage = await LocalStorage.create();
  runApp(DevicePreview(enabled: true, builder: (context) => Asan(storage: storage)));
}

class Asan extends StatefulWidget {
  const Asan({super.key, this.storage});

  final LocalStorage? storage;

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
  List<GroceryItem> _groceries = [];
  List<MealPlans> _mealPlans = [];
  List<ApiRecipe> _savedRecipes = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.storage == null) {
      _loaded = true;
    } else {
      _loadStoredData();
    }
  }

  Future<void> _loadStoredData() async {
    final results = await Future.wait([
      widget.storage!.loadGroceries(),
      widget.storage!.loadPantry(),
      widget.storage!.loadRecipes(),
      widget.storage!.loadMealPlans(),
      Future.value(widget.storage!.loadSavedRecipes()),
    ]);
    if (!mounted) return;
    setState(() {
      _groceries = results[0] as List<GroceryItem>;
      _groceriesItemCount = _groceries.length;
      _receivedPantryItems.addAll(results[1] as List<PantryItem>);
      _recipes.addAll(results[2] as List<Recipes>);
      _mealPlans = results[3] as List<MealPlans>;
      _savedRecipes = results[4] as List<ApiRecipe>;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
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
              initialSavedRecipes: _savedRecipes,
              onSavedRecipesChanged: (recipes) {
                _savedRecipes = recipes.toList();
                widget.storage?.saveSavedRecipes(_savedRecipes);
              },
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
                widget.storage?.saveRecipes(_recipes);
              },
              onAddToGroceries: (items) async {
                await _groceriesKey.currentState?.addItems(items);
              },
              onViewGroceries: () => setState(() => _selectedIndex = 3),
              onAddToMealPlan: (recipe) {
                setState(() => _selectedIndex = 1);
                _mealPlanKey.currentState?.addMealFromRecipe(recipe);
              },
            ),
            MealPlanScreen(
              key: _mealPlanKey,
              recipes: _recipes,
              incomingEntries: _mealPlans,
              onEntriesChanged: (entries) {
                _mealPlans = List.of(entries);
                widget.storage?.saveMealPlans(_mealPlans);
              },
              onViewMealPlan: () => setState(() => _selectedIndex = 1),
              onViewGroceries: () => setState(() => _selectedIndex = 3),
              onAddToGroceries: (items) async =>
                  await _groceriesKey.currentState?.addItems(items) ?? false,
            ),
            PantryScreen(
              incomingItems: _receivedPantryItems,
              onItemsChanged: (items) {
                _receivedPantryItems
                  ..clear()
                  ..addAll(items);
                widget.storage?.savePantry(items);
              },
            ),
            GroceriesScreen(
              key: _groceriesKey,
              initialItems: _groceries,
              onItemsChanged: (items) {
                _groceries = List.of(items);
                widget.storage?.saveGroceries(items);
              },
              onItemCountChanged: (count) {
                setState(() => _groceriesItemCount = count);
              },
              onItemChecked: (item) {
                setState(() => _receivedPantryItems.add(item));
                widget.storage?.savePantry(_receivedPantryItems);
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
