# AI usage

This project was built with AI assistance. This file is the record of it. It is
graded as the finals badge, and it is worth 100 points.

Start it in week 1 and keep it up as you go. The commit history of this file is
part of the evidence: a file written all at once the night before the deadline
looks exactly like what it is.

## 1. How I used AI

### 2026-09-16 - Pantry and grocery interactions

- **Tool:** Codex
- **What I asked for:** Help implement the pantry and grocery list interactions, including search, filters, and moving checked groceries into the pantry.
- **What it gave back:** Flutter code suggestions for list state, filtering, and item actions.
- **What I kept, what I changed, and why:** I adapted the suggestions to the app's item models and shared widgets so the screens use consistent controls and update their local lists.
- **Commit:** https://github.com/astherem/ASAN/commit/0a9757306e85b2ea09b43c7ddc2b12294f7e690e

### 2026-09-17 - Recipe creation and saved recipe lists

- **Tool:** Copilot
- **What I asked for:** Help build a recipe form and connect it to the saved recipe list.
- **What it gave back:** Suggestions for form fields, validation, recipe state, and displaying saved recipes.
- **What I kept, what I changed, and why:** I kept the form structure and adapted the state updates to the existing recipe model so new recipes use the same data shape as the rest of the app.
- **Commit:** https://github.com/astherem/ASAN/commit/85fdcc3a1829a2d3b182e870b413d3eefae7dcf5

### 2026-09-18 - Recipe discovery and segmented browsing

- **Tool:** Copilot
- **What I asked for:** Help add an explore view and a segmented control for switching between saved and discoverable recipes.
- **What it gave back:** Widget structure for the segmented view, recipe cards, and the explore state.
- **What I kept, what I changed, and why:** I kept the card layout and revised the selection behavior to fit the app's existing navigation and saved-recipe state.
- **Commit:** https://github.com/astherem/ASAN/commit/7ee7ba70d0272182acb1a5fed9e1d289f75b5c86

### 2026-09-20 - Recipe details and saved recipes

- **Tool:** Codex
- **What I asked for:** Help structure the recipe details and saved recipe experience.
- **What it gave back:** Ideas for displaying recipe information and connecting the details screen with the recipe list.
- **What I kept, what I changed, and why:** I kept the parts that fit the existing recipe model and revised the screen behavior to match the app's session-based saved recipes.
- **Commit:** https://github.com/astherem/ASAN/commit/761ca41df97b1d671e9b23fcddc30aeed568f0c2

### 2026-09-25 - API-backed recipes and meal planning

- **Tool:** Copilot
- **What I asked for:** Help connect the Spoonacular recipe API and use the returned recipes in meal planning.
- **What it gave back:** Suggestions for the API boundary, Supabase function configuration, response handling, and meal-plan integration.
- **What I kept, what I changed, and why:** I kept the API separation and adjusted the response handling to match the app's recipe model and configuration.
- **Commit:** https://github.com/astherem/ASAN/commit/a73391b21e72f2f0b7b2a88850e999ff7e7f3c52

### 2026-09-30 - Recipe search and grocery integration

- **Tool:** Codex
- **What I asked for:** Help me connect recipe search and the grocery flow to the existing Flutter screens.
- **What it gave back:** Suggestions and code for search results, recipe details, and transferring ingredients into the grocery list.
- **What I kept, what I changed, and why:** I used parts of the suggestions, then adapted them to the app's existing models and widgets. Keeping the flow in the current screen structure made it fit the rest of Asan.
- **Commit:** https://github.com/astherem/ASAN/commit/031682e7cea1051e3c9b759b6efcd8017d5794fa

## 2. Where the AI got it wrong

### Case 1 - Undoing a grocery transfer

- **What it gave me:** A snackbar undo action that adds a checked grocery item back to the grocery list.
- **What was wrong with it:** Checking an item also transfers it to the pantry, so adding it back to Groceries alone can leave the same item in both lists.
- **What I did instead:** I checked the behavior against the intended transfer and found that the undo must reverse both list changes. The snackbar currently only restores the grocery entry, so this is a known issue to fix.
- **Commit:** https://github.com/astherem/ASAN/commit/813c764552e5d902b58c8c253654b20e7cf66f25

### Case 2 - Filtering recipes by total time

- **What it gave me:** A filter that compared the displayed time label directly with the selected time option.
- **What was wrong with it:** The label included formatting text such as minutes, so the comparison could fail even when the recipe matched the selected range.
- **What I did instead:** I kept total time as a numeric value for filtering and formatted it only when displaying the recipe card.
- **Commit:** https://github.com/astherem/ASAN/commit/78d9527409a99d57cb746e94a910a25a0fce4400

### Case 3 - Adding a recipe to a meal plan

- **What it gave me:** Meal-plan updates that treated a fetched recipe response as if it were already a complete local recipe object.
- **What was wrong with it:** API responses and local recipes do not always contain the same fields, which could leave incomplete meal-plan entries.
- **What I did instead:** I mapped the API response into the app's recipe model before adding it to a meal plan and handled missing optional fields.
- **Commit:** https://github.com/astherem/ASAN/commit/6487bd490bc11d137689ba3dc77e8a4c30e24065

## 3. Who wrote what

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/11d63b48cb6c585434c30c89ba7cab88f86cab19
- **Files:** `lib/main.dart`, `lib/screens/`, and `lib/widgets/navigations.dart`.
- **What I wrote:** I set up the initial app structure and navigation so the core screens could share one consistent shell.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/2211f0fb4eec68ce4853993fa4ec5ac0dd44729e
- **Files:** `lib/widgets/buttons.dart`, `lib/widgets/selections.dart`, and `lib/widgets/communication.dart`.
- **What I wrote:** I built reusable controls so repeated actions and choices behave consistently across the app.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/0a9757306e85b2ea09b43c7ddc2b12294f7e690e
- **Files:** `lib/widgets/selections.dart`.
- **What I wrote:** I added the selection controls used by grocery and pantry interactions, including checked-state behavior.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/813c764552e5d902b58c8c253654b20e7cf66f25
- **Files:** `lib/models/pantry_item.dart`, `lib/screens/pantry_screen.dart`, and `lib/screens/groceries_screen.dart`.
- **What I wrote:** I implemented the pantry and grocery workflows around the app's item models and shared controls.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/85fdcc3a1829a2d3b182e870b413d3eefae7dcf5
- **Files:** `lib/models/recipes.dart`, `lib/screens/recipe_form_screen.dart`, and `lib/screens/recipes_screen.dart`.
- **What I wrote:** I added recipe creation and listing so recipes could be entered and managed in the same app structure.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/7ee7ba70d0272182acb1a5fed9e1d289f75b5c86
- **Files:** `lib/screens/recipes_screen.dart`.
- **What I wrote:** I added the segmented browse experience to separate saved recipes from recipe exploration.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/761ca41df97b1d671e9b23fcddc30aeed568f0c2
- **Files:** `lib/screens/recipe_details_screen.dart` and `lib/screens/recipes_screen.dart`.
- **What I wrote:** I added the details view and filtering behavior so users can inspect and narrow recipes.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/78d9527409a99d57cb746e94a910a25a0fce4400
- **Files:** `lib/screens/recipes_screen.dart`.
- **What I wrote:** I added numeric time filtering and category filters so recipe results can be narrowed reliably.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/a73391b21e72f2f0b7b2a88850e999ff7e7f3c52
- **Files:** `lib/services/api/recipe_api.dart`, `supabase/functions/spoonacular/index.ts`, and `lib/screens/meal_plan_screen.dart`.
- **What I wrote:** I connected external recipe data to the app and expanded meal planning around those recipes.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/6487bd490bc11d137689ba3dc77e8a4c30e24065
- **Files:** `lib/screens/recipes_screen.dart` and `lib/screens/meal_plan_screen.dart`.
- **What I wrote:** I refined the API-backed recipe flow and made meal-plan additions use the app's local recipe model.

### Written by astherem

- **Commit:** https://github.com/astherem/ASAN/commit/031682e7cea1051e3c9b759b6efcd8017d5794fa
- **Files:** `lib/screens/search_screen.dart`, `lib/screens/recipe_details_screen.dart`, `lib/screens/recipe_form_screen.dart`, `lib/screens/groceries_screen.dart`, `lib/models/`, `lib/services/api/recipe_api.dart`, and `lib/widgets/`.
- **What I wrote:** I integrated recipe search with grocery-list actions and connected the final pieces of the recipe flow.

### The AI-written part I understand best

- **File:** `lib/screens/search_screen.dart`
- **Commit:** https://github.com/astherem/ASAN/commit/031682e7cea1051e3c9b759b6efcd8017d5794fa
- **What it does and why we kept it:** This screen presents recipe search results and connects them to the rest of the app. It uses the user's search input and selected filters to show matching recipes, lets the user open a recipe's details, and provides an action for transferring recipe ingredients into the grocery list. I kept this implementation because it connects recipe discovery with existing recipe-details and grocery-list flows instead of creating separate, duplicated systems. I adapted the AI suggestions to use the app's existing recipe models, shared widgets, and navigation structure so the search feature fits the rest of the application.
