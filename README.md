# Asan

**Live demo:** https://astherem.github.io/ASAN/ <br>
**Demo video:** To be added after recording. <br>
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University <br>
**Author:** astherem

## 1. Overview

Asan is a Flutter-based food and meal planning app designed to help people track groceries, manage pantry stock, and save or explore recipes in one place. It targets busy students and households who want a clearer picture of what they have, what they need, and what they could cook next.

## 2. Setup and installation

**The app targets:**

- Flutter stable
- Dart SDK 3.8.0 or newer

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

For local development, put your Supabase project URL and publishable key in the root `env.json` file. This local config is git-ignored and loaded at app startup, so ordinary `flutter run` works without defines. Build-time `--dart-define` values remain supported for CI and deployments.

If you want accounts and cloud sync, create a Supabase project, apply
`supabase/migrations/user_data.sql` in the Supabase SQL editor, and enable email
authentication. The migration also creates a private `profile-photos` Storage
bucket with per-user access policies. If you already applied the migration,
run its profile photo bucket and policy statements as well. The app uses the publishable key in the client; never place a
Supabase secret key or the Spoonacular API key in `env.json`.

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
When the app loads successfully, it opens to Recipes. With Supabase
configured, the app shows the sign-in/onboarding flow before opening the app.
Without Supabase configuration, it runs in local-only mode. The bottom
navigation contains Recipes, Meals, Pantry, and Groceries. Recipe search
requires a configured Supabase project and a deployed `spoonacular` Edge
Function; the other screens can be explored without that service.

## 4. Features and usage

### Recipes

- Explore tab loads a set of recipes from Spoonacular and supports text search and recipe filters. Select a result to view its details, ingredients, and instructions.
- Save Explore recipes to Saved. Local data is retained between launches, and
  signed-in users also sync it with Supabase.
- Use My Recipes to create, view, and manage custom recipes. Recipe images can be selected with the device image picker where supported.
- Explore requires valid Supabase client configuration and a deployed `spoonacular` Edge Function with the `SPOONACULAR_API_KEY` secret. Without these, custom recipes and the other local screens remain available, but Explore cannot fetch recipes.

### Accounts and sync

- Create an account, sign in, and request a password-reset email through
  Supabase Auth.
- Hive stores a local copy of recipes, saved recipes, pantry items, groceries,
  and meal plans.
- After sign-in, the app merges local collections with the user's Supabase
  `user_data` records and uploads later changes. Row-level security limits each
  user to their own data.
- Profile photos are stored in a private Supabase Storage bucket under the
  signed-in user's ID and cached locally for offline viewing.
- If cloud sync is unavailable, the app keeps the local data and displays a
  sync error instead of silently discarding changes.

### Meal Plan

- Switch between Day and Week views, navigate by day or week, select a date, and filter the displayed meal entries by meal time or recipe category. The screen groups entries into Breakfast, Lunch, and Dinner.
- Add meals from a saved or Explore recipe, choose the date, meal time, serving
  count, and optional dish type, then edit or delete planned entries.
- Open a planned recipe's details and send its ingredients to Groceries. The
  app keeps the planned meal and grocery collections connected when data is
  saved locally or synchronized after sign-in.

### Pantry

- Add and edit pantry items with name, quantity, purchase/expiry dates, notes, and aisle.
- Search by item name and filter by aisle or expiry status.
- Grouped list sections make it easier to review inventory by category.

### Groceries

- Add and edit grocery items; search, filter by aisle, and sort or group the list.
- Checking an item removes it from Groceries and adds it to Pantry with its purchase date. The navigation badge tracks the grocery item count.

### Settings

- Edit the local profile name, email display value, and profile image.
- Set preferred cuisines, dietary restrictions, the first day of the week, and
  the default serving size.
- Preferences are stored locally and, when an account is available, mirrored to
  the signed-in user's Supabase metadata.


## 5. Project structure

The project is organised by app responsibility. The main folders and files are:

```text
├── .github/workflows/deploy-web.yml    GitHub Pages build and deployment
├── docs/                               Proposal, design, reports, and app assets
│   └── assets/                         Screenshots, logos, and fonts
├── lib/                                Flutter application source
│   ├── data/                           Hive-backed storage and collection boxes
│   ├── models/                         Recipe, meal, pantry, grocery, and filter models
│   ├── screens/                        App screens and recipe forms/details
│   ├── services/                       Auth, sync, Supabase, and recipe API services
│   ├── styles/                         App theme
│   ├── widgets/                        Shared controls and navigation
│   └── main.dart                       App startup and root navigation
├── supabase/
│   ├── functions\spoonacular/          Server-side Spoonacular proxy Edge Function
│   └── migrations/                     Database schema and row-level security policies
├── test/                               Widget tests
├── web/                                Flutter web entry point and manifest
├── .env.example                        Example environment configuration
├── pubspec.yaml                        Flutter dependencies and project metadata
└── README.md                           Project overview and setup guide
```

## 6. Screenshots

| Onboarding | Sign Up | Log In |
| --- | --- | --- |
| <img src="docs/assets/screenshots/onboarding.jpg" alt="Onboarding" width="220"> | <img src="docs/assets/screenshots/sign_up.jpg" alt="Sign Up" width="220"> | <img src="docs/assets/screenshots/log_in.jpg" alt="Log In" width="220"> |

| Recipes (Explore) | Recipes (Saved) | Recipes (My Recipes) |
| --- | --- | --- |
| <img src="docs/assets/screenshots/recipes_explore.jpg" alt="Recipes (Explore)" width="220"> | <img src="docs/assets/screenshots/recipes_saved.jpg" alt="Recipes (Saved)" width="220"> | <img src="docs/assets/screenshots/recipes_my_recipes.jpg" alt="Recipes (My Recipes)" width="220"> |

| Recipe Details | Search Recipes | Add Recipe |
| --- | --- | --- |
| <img src="docs/assets/screenshots/recipe_details.jpg" alt="Recipe Details" width="220"> | <img src="docs/assets/screenshots/search_recipes.jpg" alt="Search Recipes" width="220"> | <img src="docs/assets/screenshots/add_recipe.jpg" alt="Add Recipe" width="220"> |

| Meal Plan (Day) | Meal Plan (Week) | Add Meal to Plan |
| --- | --- | --- |
| <img src="docs/assets/screenshots/meal_plan_day.jpg" alt="Meal Plan (Day)" width="220"> | <img src="docs/assets/screenshots/meal_plan_week.jpg" alt="Meal Plan (Week)" width="220"> | <img src="docs/assets/screenshots/add_meal_to_plan.jpg" alt="Add Meal to Plan" width="220"> |

| Pantry | Add Pantry Item | Groceries |
| --- | --- | --- |
| <img src="docs/assets/screenshots/pantry.jpg" alt="Pantry" width="220"> | <img src="docs/assets/screenshots/add_pantry_item.jpg" alt="Add Pantry Item" width="220"> | <img src="docs/assets/screenshots/groceries.jpg" alt="Groceries" width="220"> |

| Add Grocery Item | Settings |
| --- | --- |
| <img src="docs/assets/screenshots/add_grocery_item.jpg" alt="Add Grocery Item" width="220"> | <img src="docs/assets/screenshots/settings.png" alt="Settings" width="220"> |

## 7. Known issues and next steps

**Current known limitations:**

- Explore tab depends on the Supabase Edge Function and the Spoonacular service/quota. Configure and deploy the function before expecting Explore results.
- Cloud sync requires a configured Supabase project, the `user_data` migration,
  email authentication, and a signed-in user. Local Hive storage remains
  available when Supabase is not configured.
- Sync currently merges collections by record identity and prefers the local
  record when the same identity exists in both places; it does not resolve
  concurrent field-level edits.

- Form validation exists for required item and recipe fields, but duplicate prevention and broader edge-case handling remain limited.

**Planned next steps:**

1. Improve validation and edge-case handling, including duplicate items and
   state updates.
2. Add conflict resolution and more granular sync feedback for multi-device
   edits.
3. Refresh screenshots and finish the demo and presentation materials.

## Security checklist

See [Security Checklist](SECURITY-CHECKLIST.md) for the project's security review, including client configuration, GitHub Actions, and the server-side Spoonacular key.

## Credits

- **Packages:** see [pubspec.yaml](pubspec.yaml)
- **Fonts:** Bricolage Grotesque by Mathieu Triay, licensed under the [SIL Open Font License, Version 1.1](https://openfontlicense.org/open-font-license-official-text/)
- **Icons:** Material Symbols and Icons by Google and Tim Maffett, licensed under the [Apache License Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)

## AI usage

[![Built with AI assistance](https://img.shields.io/badge/Built%20with-AI%20assistance-28B873)](AI-USAGE.md)

The app was developed with Codex and Copilot for code suggestions, debugging, API integration, and documentation, while the final implementation was reviewed and adjusted by the author. See [AI Usage](AI-USAGE.md) for more details. 

## LICENSE

Copyright © 2026 astherem. [MIT License](LICENSE).
