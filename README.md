# Asan

**Live demo:** https://astherem.github.io/ASAN/ <br>
**Demo video:** To be added after recording. <br>
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University <br>
**Author:** astherem

## 1. Overview

Asan is a Flutter-based food and meal planning app designed to help people track groceries, manage pantry stock, and save or explore recipes in one place. It targets busy students and households who want a clearer picture of what they have, what they need, and what they could cook next.

## 2. Setup and installation

**The app was built and tested with:**

- Flutter 3.47.2
- Dart 3.13.2

**To get the project running from a fresh machine:**

Install Flutter and ensure the Flutter toolchain is on your PATH.

```bash
git clone https://github.com/astherem/ASAN.git
cd ASAN
```
Open the project folder in VS Code or your terminal.

``` bash
flutter pub get
```
If you are using a physical device or emulator, connect it and confirm it is listed with:
``` bash
flutter devices
```
Recipes Explore uses Spoonacular through a Supabase Edge Function. The Spoonacular API key stays in Supabase Function secrets; the Flutter app receives only the Supabase URL and publishable key.

For local development, copy `assets/config/supabase.example.json` to `assets/config/supabase.json` and replace the sample values with your Supabase project URL and publishable key. The local config is git-ignored and loaded at app startup, so ordinary `flutter run` and VS Code's **Asan** launch configuration work without defines. Build-time `--dart-define` values remain supported for CI and deployments.

## 3. How to run it

Start the app with:
``` bash
flutter run
```
For a browser preview, use:
``` bash
flutter run -d chrome
```

The recipe search calls the `spoonacular` Supabase Edge Function, which calls Spoonacular without exposing the provider key in the Flutter client. Configure and deploy it once:

```bash
supabase link --project-ref your-project-ref
supabase secrets set SPOONACULAR_API_KEY=your_spoonacular_key
supabase functions deploy spoonacular
```

For GitHub Pages, add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as repository secrets. The workflow passes them as Flutter `--dart-define` values. The Edge Function endpoint is callable by app clients, so monitor its usage.
When the app loads successfully, it opens to Recipes. The bottom navigation contains Recipes, Meals, Pantry, and Groceries. Recipe search requires a configured Supabase project and a deployed `spoonacular` Edge Function; the other screens can be explored without that service.

## 4. Features and usage

### Recipes

- Browse Explore recipes returned by the Spoonacular Edge Function, search by text, and filter by preparation time or meal category.
- Open a recipe to view its details, ingredients, and instructions.
- Save Explore recipes to the Saved tab for the current app session.
- Open My Recipes to view recipes created with the add button and recipe form.

### Meal Plan

- The screen has Day and Week views, date navigation, and meal sections. Adding meals, applying filters, and sending planned meals to Groceries are not implemented yet.

### Pantry

- Add pantry items with name, quantity, expiry date, notes, and food group.
- Search by item name and filter by food group or expiry status.
- Grouped list sections make it easier to review inventory by category.

### Groceries

- Add and edit grocery items; search, filter by food group, and sort or group the list.
- Checking an item removes it from Groceries and adds it to Pantry with its purchase date. The navigation badge tracks the number of grocery items.


## 5. Project structure

The project is organised as a Flutter app with a clear screen-first structure:

```text
lib/
├──main.dart          app entry point and shared navigation state
├──models             recipe, pantry item, and grocery item models
├──screens            Recipes, Meal Plan, Pantry, and Groceries screens
├──styles             theme — color palette, spacing, and app typography
└──widgets            reusable buttons, cards, dialogs, filters, search, and navigation components
```

## 6. Screenshots

| Recipes | Add Recipe | Meal Plan |
| --- | --- | --- |
| ![Recipes](docs/assets/screenshots/recipes.png) | ![Add Recipe](docs/assets/screenshots/add_recipe.png) | ![Meal Plan](docs/assets/screenshots/meal_plan.PNG) |

| Add Meal | Pantry | Add Pantry Item |
| --- | --- | --- |
| ![Add Meal](docs/assets/screenshots/add_meal.PNG) | ![Pantry](docs/assets/screenshots/pantry.PNG) | ![Add Pantry Item](docs/assets/screenshots/add_pantry_item.PNG) |

| Groceries | Add Grocery Item | --- |
| --- | --- | --- |
| ![Add Groceries](docs/assets/screenshots/groceries.PNG) | ![Add Grocery Item](docs/assets/screenshots/add_grocery_jtem.PNG) | ![]() |

## 7. Known issues and next steps

**Current known limitations:**

- Spoonacular's allowance is 50 daily credits; each request costs 1 point plus 0.01 points per result returned. High usage or large result counts can exhaust the allowance.
- Meal Plan is still a placeholder and cannot yet support the complete planning workflow because the Recipes workflow is not fully completed.
- Data is not yet persisted to local storage or a backend, so recipes, pantry items, and groceries reset when the app is restarted.
- The repository still needs final screenshot capture and polish for the visual documentation.
- More validation and edge-case handling should be added for item editing, filtering, and duplicate prevention.

**Planned next steps:**

1. Finalize the recipe workflow and identify/integrate a suitable recipe API for the Explore tab.
2. Add persistent storage for recipes, pantry items, and groceries.
3. Complete the Meal Plan workflow with recipe selection, scheduling, and date-based planning.
4. Finalize visual documentation and screenshot assets.
5. Improve validation and state handling across all screens.

## AI usage

![Built with AI assistance](https://img.shields.io/badge/built%20with-AI%20assistance-0b5fff)

The app was developed with AI support for structure, UI patterns, and documentation, while the final implementation was reviewed and adjusted by the author to match project needs. See [AI-USAGE.md](AI-USAGE.md) for more details. 

## LICENSE

Copyright © 2026 astherem. [MIT License](LICENSE).
