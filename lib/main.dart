import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'package:asan/screens/groceries_screen.dart';
import 'package:asan/screens/meal_plan_screen.dart';
import 'package:asan/screens/pantry_screen.dart';
import 'package:asan/screens/recipes_screen.dart';
import 'package:asan/models/pantry_item.dart';
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
  int _selectedIndex = 0;
  int _groceriesItemCount = 0;
  final List<PantryItem> _receivedPantryItems = [];

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
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const RecipesScreen(),
            const MealPlanScreen(),
            PantryScreen(incomingItems: _receivedPantryItems),
            GroceriesScreen(
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
