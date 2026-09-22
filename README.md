# Asan

[![Made with AI](https://img.shields.io/badge/Made_with-AI_assistance-blue)](AI-USAGE.md)

**Live demo:** https://benicemalig.github.io/ASAN/ <br>
**Demo video:** To be added after recording. <br>
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University <br>
**Author:** Benice Asheret Malig

## 1. Overview

Asan is a Flutter-based food and meal planning app designed to help people track groceries, manage pantry stock, and save or explore recipes in one place. It targets busy students and households who want a clearer picture of what they have, what they need, and what they could cook next.

## 2. Setup and installation

**The app was built and tested with:**

- Flutter 3.47.2
- Dart 3.13.2

**To get the project running from a fresh machine:**

1. Install Flutter and ensure the Flutter toolchain is on your PATH.
2. Clone the repository:
```bash
git clone https://github.com/benicemalig/ASAN.git
cd ASAN
```
3. Open the project folder in VS Code or your terminal.
4. Run:
``` bash
flutter pub get
```
5. If you are using a physical device or emulator, connect it and confirm it is listed with:
``` bash
flutter devices
```
6. No API keys or backend configuration are implemented yet. The Explore tab for Recipes is still awaiting a suitable recipe API. If a backend or external API is added later, store any real secrets in a secure environment file and never commit them.

## 3. How to run it

Start the app with:
``` bash
flutter run
```
For a browser preview, use:
``` bash
flutter run -d chrome
```

When the app loads successfully, the default view opens to the Recipes tab and the bottom navigation should show Recipes, Meals, Pantry, and Groceries. The interface should be fully interactive in a local development build.

## 4. Features and usage

### Recipes

- Browse the Explore tab to see recipes.
- Save recipes from the Explore view to keep them in a personal shortlist.
- Open My Recipes to view custom recipes created in-app.
- Use the add button in the Recipes app bar to open the full recipe form.
- The recipe form includes basic information, ingredients, instructions, and other details.

### Meal Plan

- The Meal Plan screen is present in the app navigation and has the planned shell for future planning features.
- It is currently a placeholder and is not yet connected to a complete meal-planning workflow or persistent data model.

### Pantry

- Add pantry items with name, quantity, expiry date, notes, and food group.
- Search by item name and filter by food group or expiry status.
- Grouped list sections make it easier to review inventory by category.

### Groceries

- Add grocery items from the Groceries tab.
- Search, filter, and review purchase status.
- Checking an item triggers its transfer into the pantry flow and updates the badge count in the navigation bar.

## 5. Project structure

The project is organised as a Flutter app with a clear screen-first structure:

```text
lib/
├──main.dart          app entry point and shared navigation state
├──screens            Recipes, Meal Plan, Pantry, and Groceries screens
├──models             recipe, pantry item, and grocery item models
├──styles             theme — color palette, spacing, and app typography
└──widgets            reusable buttons, cards, dialogs, filters, search, and navigation components
```

## 6. Screenshots

Screenshots are not yet committed to the repository for every screen, but the app currently includes these UI areas:

- Recipes screen
- Meal Plan screen
- Pantry screen
- Groceries screen
- Recipe creation/edit form

## 7. Known issues and next steps

**Current known limitations:**

- The Explore tab in Recipes is still on hold while a suitable recipe API is being evaluated.
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

This repository includes an AI usage log in [AI-USAGE.md](AI-USAGE.md). The app was developed with AI support for structure, UI patterns, and documentation, while the final implementation was reviewed and adjusted by the author to match project needs.