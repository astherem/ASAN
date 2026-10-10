import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:asan/services/supabase_config.dart';
import 'package:asan/services/auth_service.dart';
import 'package:asan/screens/groceries_screen.dart';
import 'package:asan/screens/meal_plan_screen.dart';
import 'package:asan/screens/pantry_screen.dart';
import 'package:asan/screens/recipes_screen.dart';
import 'package:asan/screens/settings_screen.dart';

import 'package:asan/models/pantry_item.dart';
import 'package:asan/models/grocery_item.dart';
import 'package:asan/models/meal_plans.dart';
import 'package:asan/models/recipes.dart';
import 'package:asan/services/recipe_api.dart';
import 'package:asan/services/cloud_storage.dart';
import 'package:asan/services/sync_service.dart';
import 'package:asan/data/local_storage.dart';
import 'package:asan/data/grocery_box.dart';
import 'package:asan/data/meal_plan_box.dart';
import 'package:asan/data/pantry_box.dart';
import 'package:asan/data/recipe_box.dart';
import 'package:asan/data/saved_recipe_box.dart';
import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/navigations.dart';
import 'package:asan/widgets/communication.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RecipeApi.loadConfig();
  final storage = await LocalStorage.create();
  if (SupabaseConfig.hasSupabase) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabasePublishableKey,
    );
  }
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => AppBootstrap(
        storage: storage,
        client: SupabaseConfig.hasSupabase ? Supabase.instance.client : null,
      ),
    ),
  );
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({required this.storage, this.client, super.key});

  final LocalStorage storage;
  final SupabaseClient? client;

  @override
  Widget build(BuildContext context) {
    if (client == null) return Asan(storage: storage);
    return StreamBuilder<AuthState>(
      stream: client!.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (client!.auth.currentSession == null) {
          return AuthService(client: client!);
        }
        return Asan(storage: storage, client: client);
      },
    );
  }
}

class Asan extends StatefulWidget {
  const Asan({super.key, this.storage, this.client});

  final LocalStorage? storage;
  final SupabaseClient? client;

  @override
  State<Asan> createState() => _AsanState();
}

class _AsanState extends State<Asan> {
  final _groceriesKey = GlobalKey<GroceriesScreenState>();
  final _mealPlanKey = GlobalKey<MealPlanScreenState>();
  int _selectedIndex = 0;
  bool _isLoadingData = false;
  int _groceriesItemCount = 0;
  int _defaultServings = 1;
  String _firstDayOfWeek = 'Sunday';
  Map<String, List<String>> _foodPreferences = {'cuisines': [], 'diets': []};
  final List<PantryItem> _receivedPantryItems = [];
  final List<Recipes> _recipes = [];
  List<GroceryItem> _groceries = [];
  List<MealPlans> _mealPlans = [];
  List<ApiRecipe> _savedRecipes = [];
  String? _pendingSyncError;
  final Map<String, List<Map<String, dynamic>>> _syncBaselines = {};
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    if (widget.storage != null) {
      _isLoadingData = true;
      final preferences = widget.storage!.loadProfilePreferences();
      final metadata = widget.client?.auth.currentUser?.userMetadata?['preferences'];
      final saved = metadata is Map ? metadata : preferences;
      _foodPreferences = {
        for (final key in ['cuisines', 'diets'])
          key: (saved[key] is List ? saved[key] as List : const []).whereType<String>().toList(),
      };
      final firstDay = saved['first_day_of_week'];
      if (firstDay is List && firstDay.isNotEmpty && firstDay.first is String) {
        _firstDayOfWeek = firstDay.first as String;
      }
      _loadStoredData();
    }
  }

  Future<void> _loadStoredData() async {
    final localPreferences = widget.storage!.loadProfilePreferences();
    final metadataPreferences = widget.client?.auth.currentUser?.userMetadata?['preferences'];
    final profilePreferences = metadataPreferences is Map
        ? metadataPreferences
        : localPreferences;
    final servingValues = profilePreferences['serving_size'];
    if (servingValues is List && servingValues.isNotEmpty) {
      _defaultServings = (int.tryParse('${servingValues.first}') ?? 1).clamp(1, 100);
    }
    final results = await Future.wait([
      widget.storage!.loadGroceries(),
      widget.storage!.loadPantry(),
      widget.storage!.loadRecipes(),
      widget.storage!.loadMealPlans(),
      Future.value(widget.storage!.loadSavedRecipes()),
    ]);
    var groceries = results[0] as List<GroceryItem>;
    var pantryItems = results[1] as List<PantryItem>;
    var recipes = results[2] as List<Recipes>;
    var mealPlans = results[3] as List<MealPlans>;
    var savedRecipes = results[4] as List<ApiRecipe>;
    if (widget.client != null) {
      try {
        final sync = SyncService(CloudStorage(widget.client!));
        final synced = await Future.wait([
          sync.syncCollection('groceries', groceries.map(GroceryBox.toJson)),
          sync.syncCollection('pantry', pantryItems.map(PantryBox.toJson)),
          sync.syncCollection('recipes', recipes.map(RecipeBox.toJson)),
          sync.syncCollection('meal_plans', mealPlans.map(MealPlanBox.toJson)),
          sync.syncCollection(
            'saved_recipes',
            savedRecipes.map(SavedRecipeBox.toJson),
          ),
        ]);
        groceries = synced[0].map(GroceryBox.fromJson).toList();
        pantryItems = synced[1].map(PantryBox.fromJson).toList();
        recipes = synced[2].map(RecipeBox.fromJson).toList();
        mealPlans = synced[3].map(MealPlanBox.fromJson).toList();
        savedRecipes = synced[4].map(SavedRecipeBox.fromJson).toList();
        _syncBaselines.addAll({
          'groceries': groceries.map(GroceryBox.toJson).toList(),
          'pantry': pantryItems.map(PantryBox.toJson).toList(),
          'recipes': recipes.map(RecipeBox.toJson).toList(),
          'meal_plans': mealPlans.map(MealPlanBox.toJson).toList(),
          'saved_recipes': savedRecipes.map(SavedRecipeBox.toJson).toList(),
        });
        await Future.wait([
          widget.storage!.saveGroceries(groceries),
          widget.storage!.savePantry(pantryItems),
          widget.storage!.saveRecipes(recipes),
          widget.storage!.saveMealPlans(mealPlans),
          widget.storage!.saveSavedRecipes(savedRecipes),
        ]);
      } on Exception catch (error) {
        _pendingSyncError = 'Cloud sync failed: $error';
      }
    }
    if (!mounted) return;
    setState(() {
      _groceries = groceries;
      _groceriesItemCount = _groceries.length;
      _receivedPantryItems.addAll(pantryItems);
      _recipes.addAll(recipes);
      _mealPlans = mealPlans;
      _savedRecipes = savedRecipes;
      _isLoadingData = false;
    });
    final syncError = _pendingSyncError;
    if (syncError != null) {
      _pendingSyncError = null;
      _showSyncError(syncError);
    }
  }

  void _saveCollection(String type, Iterable<Map<String, dynamic>> payload) {
    final current = payload.toList();
    final previous = _syncBaselines[type] ?? const [];
    final currentKeys = current.map((item) => _syncKey(type, item)).toSet();
    final deletedKeys = previous
        .map((item) => _syncKey(type, item))
        .where((key) => !currentKeys.contains(key));
    _syncBaselines[type] = current;
    if (widget.client == null) return;
    SyncService(CloudStorage(widget.client!))
        .syncCollection(type, current, deletedKeys: deletedKeys)
        .then((merged) => _syncBaselines[type] = merged)
        .catchError((error) {
          if (mounted) _showSyncError('Cloud sync failed: $error');
          return <Map<String, dynamic>>[];
        });
  }

  String _syncKey(String type, Map<String, dynamic> item) {
    switch (type) {
      case 'pantry':
        return 'id:${item['id'] ?? _stableValue(item)}';
      case 'groceries':
        return 'grocery:${item['name']}|${item['aisle'] ?? ''}';
      case 'recipes':
        return 'recipe:${item['name']}';
      case 'saved_recipes':
        return 'saved:${item['id'] ?? item['title'] ?? _stableValue(item)}';
      case 'meal_plans':
        return 'meal:${item['date']}|${item['mealTime']}|'
            '${(item['recipe'] as Map?)?['name'] ?? ''}';
      default:
        return _stableValue(item);
    }
  }

  String _stableValue(Map<String, dynamic> item) =>
      item.entries.map((entry) => '${entry.key}=${entry.value}').join('|');

  void _showSyncError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = _messengerKey.currentState;
      if (mounted && messenger != null) {
        AsanSnackBar.showOn(messenger, message: message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: 'Asan',
      debugShowCheckedModeBanner: false,

      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: ThemeData(
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _AsanPageTransitionsBuilder(),
            TargetPlatform.iOS: _AsanPageTransitionsBuilder(),
            TargetPlatform.linux: _AsanPageTransitionsBuilder(),
            TargetPlatform.macOS: _AsanPageTransitionsBuilder(),
            TargetPlatform.windows: _AsanPageTransitionsBuilder(),
            TargetPlatform.fuchsia: _AsanPageTransitionsBuilder(),
          },
        ),
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
        body: Column(
          children: [
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : _AnimatedIndexedStack(
                      index: _selectedIndex,
                      children: [
                  RecipesScreen(
                    defaultServings: _defaultServings,
                    foodPreferences: _foodPreferences,
                    incomingRecipes: _recipes,
                    initialSavedRecipes: _savedRecipes,
                    onSavedRecipesChanged: (recipes) {
                      _savedRecipes = recipes.toList();
                      widget.storage?.saveSavedRecipes(_savedRecipes);
                      _saveCollection(
                        'saved_recipes',
                        _savedRecipes.map(SavedRecipeBox.toJson),
                      );
                    },
                    onRecipesChanged: (recipes) {
                      for (
                        var i = 0;
                        i < _recipes.length && i < recipes.length;
                        i++
                      ) {
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
                      _saveCollection(
                        'recipes',
                        _recipes.map(RecipeBox.toJson),
                      );
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
                    defaultServings: _defaultServings,
                    firstDayOfWeek: _firstDayOfWeek,
                    key: _mealPlanKey,
                    recipes: _recipes,
                    incomingEntries: _mealPlans,
                    onEntriesChanged: (entries) {
                      _mealPlans = List.of(entries);
                      widget.storage?.saveMealPlans(_mealPlans);
                      _saveCollection(
                        'meal_plans',
                        _mealPlans.map(MealPlanBox.toJson),
                      );
                    },
                    onViewMealPlan: () => setState(() => _selectedIndex = 1),
                    onViewGroceries: () => setState(() => _selectedIndex = 3),
                    onAddToGroceries: (items) async =>
                        await _groceriesKey.currentState?.addItems(items) ??
                        false,
                  ),
                  PantryScreen(
                    incomingItems: _receivedPantryItems,
                    onItemsChanged: (items) {
                      _receivedPantryItems
                        ..clear()
                        ..addAll(items);
                      widget.storage?.savePantry(items);
                      _saveCollection('pantry', items.map(PantryBox.toJson));
                    },
                  ),
                  GroceriesScreen(
                    key: _groceriesKey,
                    initialItems: _groceries,
                    onItemsChanged: (items) {
                      _groceries = List.of(items);
                      widget.storage?.saveGroceries(items);
                      _saveCollection(
                        'groceries',
                        _groceries.map(GroceryBox.toJson),
                      );
                    },
                    onItemCountChanged: (count) {
                      setState(() => _groceriesItemCount = count);
                    },
                    onItemChecked: (item) {
                      setState(() => _receivedPantryItems.add(item));
                      widget.storage?.savePantry(_receivedPantryItems);
                      _saveCollection(
                        'pantry',
                        _receivedPantryItems.map(PantryBox.toJson),
                      );
                    },
                  ),
                  SettingsScreen(
                    client: widget.client,
                    storage: widget.storage,
                    onDefaultServingsChanged: (value) =>
                        setState(() => _defaultServings = value),
                    onFoodPreferencesChanged: (preferences) => setState(() => _foodPreferences = preferences),
                    onFirstDayOfWeekChanged: (day) => setState(() => _firstDayOfWeek = day),
                  ),
                      ],
                    ),
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

class _AnimatedIndexedStack extends StatefulWidget {
  const _AnimatedIndexedStack({
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<_AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<_AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addStatusListener(_handleAnimationStatus);
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  int? _previousIndex;

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousIndex != null) {
      setState(() => _previousIndex = null);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          Offstage(
            offstage: index != widget.index && index != _previousIndex,
            child: IgnorePointer(
              ignoring: index != widget.index,
              child: AnimatedBuilder(
                animation: _progress,
                child: widget.children[index],
                builder: (context, child) {
                  final offset = index == widget.index
                      ? Offset(0, 0.04 * (1 - _progress.value))
                      : Offset(0, -0.04 * _progress.value);
                  return FractionalTranslation(
                    translation: offset,
                    child: child,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _AsanPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AsanPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final easedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(easedAnimation),
      child: child,
    );
  }
}
