# Proposal

## The problem, in one sentence

Students and busy individuals often forget what food they have at home, causing groceries to expire and money to be wasted because there is no simple way to track pantry items, shopping lists, and meal plans in one app.

## Who it is for

- This app is designed for college students and busy households who prepare their own meals but have busy schedules.
- Instead of using this app, they usually rely on memory, handwritten shopping lists, notes on their phones, or checking their refrigerator manually.

## Core features

- **Recipes:** Browse and search recipes from Spoonacular through a Supabase Edge
  Function, open recipe details, filter results, save recipes for the current
  app installation, and create custom recipes. Custom recipes can include
  preparation details, ingredients, instructions, notes, tags, and an optional
  image.
- **Meal planning:** Browse planned meals by day or week, move between dates,
  group meals by Breakfast, Lunch, and Dinner, and filter the displayed entries
  by meal time or recipe category. Add, edit, and delete planned meals, send
  visible meal ingredients to Groceries, and receive recipes from the recipe
  workflow.
- **Pantry tracking:** Add and edit pantry items with quantity, unit, aisle,
  purchase date, expiry date, and notes. Search items, filter by aisle or expiry
  status, and review them in grouped lists.
- **Grocery tracking:** Add and edit grocery items, search them, filter by
  aisle, and sort or group the list. Checking an item removes it from Groceries
  and adds it to Pantry with its purchase date. The navigation badge shows the
  current grocery-item count.

## Out of scope, and why


- **Barcode scanning, automatic receipt importing, and automatic expiry
  detection:** These require device-specific integrations or external data
  sources and are not necessary to test manual pantry and grocery tracking.
- **Social, collaborative, and marketplace features:** Sharing lists, household
  permissions, messaging, grocery ordering, and price comparison are outside
  the single-user prototype goal.
- **A second recipe provider or a fully offline recipe catalogue:** Spoonacular
  is sufficient for demonstrating recipe discovery. Supporting multiple
  providers or bundling a large catalogue would add maintenance, licensing,
  caching, and provider-fallback work.

## Data the app remembers, and where it is saved

The app saves the user's food-management data locally on the device so it
remains available after the app is closed or reloaded. The local persistent
storage layer covers:

- pantry items, including quantities, units, aisle, purchase and expiry dates,
  notes, and consumed status;
- grocery items, including quantities, units, aisle, notes, and purchase date;
- custom recipes and recipes saved from Explore;
- meal-plan entries, including their dates, meal times, selected recipes, and
  serving overrides; and
- the relationships between recipes, planned meals, groceries, and pantry
  items, including moving checked groceries into the pantry.

This data is serialized with Hive and saved in the app's private local storage
on the user's device. It is loaded during startup and written when the user
adds, edits, checks, consumes, saves, or deletes an item. Writes are queued per
storage box so quick successive changes are persisted in order. Email accounts
and password recovery are provided through Supabase Auth. When Supabase is
configured and the user is signed in, data is synchronized through one
`user_data` table with a collection type and JSON payload for Pantry,
Groceries, Recipes, Saved Recipes, and Meal Plan entries. The shared table
keeps `amount` and `unit` nullable for data types where those fields do not
apply. On first sync, existing local data is uploaded; subsequent syncs merge
records by collection-specific identity, prefer the local copy when an
identity exists in both places, retain records created elsewhere, and upload
the merged collection. Without a configured service or signed-in account, the
app remains usable with local Hive storage only.

The Supabase URL and publishable key continue to come from local `env.json` or
build-time environment defines. The Spoonacular API key remains in the
`SPOONACULAR_API_KEY` Supabase Edge Function secret rather than being saved in
the Flutter client. Recipe search requests and responses pass through that
function and are not used as a user-data archive.

## Risks

- **Data loss:** Local storage reduces loss after an app restart, but clearing
  app data, uninstalling the app, storage corruption, or an interrupted write
  could still remove locally stored pantry, grocery, recipe, or meal-plan
  changes. Signed-in users have a cloud copy, but it is not a versioned backup
  and sync does not yet provide automatic record-level conflict resolution.
- **Service availability and quota:** Explore depends on network access, valid
  Supabase configuration, a deployed Edge Function, Spoonacular availability,
  and the provider's quota and rate limits. The rest of the local prototype can
  still be used when Explore is unavailable.
- **Secret and configuration exposure:** The Supabase publishable key is
  necessarily available to the client, while the Spoonacular secret must remain
  in Supabase and out of source control. A leaked provider key or an overly
  permissive server configuration could create unexpected usage or cost.
- **Incorrect user-entered inventory data:** Missed or incorrect quantities and
  expiry dates can lead to wasted food or unsafe assumptions. The app records
  what the user enters; it does not verify freshness or provide food-safety
  advice.
- **Input and platform edge cases:** Duplicate items, image-picker behavior,
  responsive layouts, and some validation paths still need broader testing
  across browsers and devices.
- **Third-party content and privacy:** Explore results come from an external
  provider. Account email addresses and signed-in app data are processed by
  Supabase, while recipe searches pass through the Supabase Edge Function to
  Spoonacular. The public recipe proxy needs usage monitoring and does not
  provide user-data authorization.

## Changes since the last version

### September 7–13, 2026

- Replaced the initial project shell with the four main destinations and
  reusable form, navigation, input, selection, and communication widgets.
- Added the first pantry form and search/filter interactions.
- Kept state local and sample-based so the interaction design could be tested
  before choosing a persistence layer.

### September 14–20, 2026

- Added grocery and pantry item forms, recipe creation, saved recipes, recipe
  filtering, and shared search/filter/sort/group patterns for inventory.
- Connected checked groceries to Pantry and added the grocery-count badge.
- Deferred persistence and the complete meal-plan data flow rather than hiding
  those unfinished behaviors behind a partial backend.

### September 21–27, 2026

- Connected Explore to Spoonacular through a Supabase Edge Function, added
  recipe search, filters, details, and error/quota handling, and kept the
  provider key server-side.
- Expanded Meal Plan with Day and Week views, date navigation, meal-time
  sections, and recipe-category filtering.
- Added local Supabase configuration support and documented deployment and
  security limitations.

### September 28–October 4, 2026

- Added Hive-backed local persistence for groceries, pantry items, custom
  recipes, saved Explore recipes, and meal-plan entries.
- Loaded persisted records during application startup and saved changes from the
  shared application state callbacks.
- Added ordered write handling for each local storage box so rapid updates do
  not overwrite one another out of order.
- Completed meal-plan creation, editing, deletion, and adding planned
  ingredients to Groceries.

### October 5–11, 2026

- Added Supabase email sign-up, sign-in, and password-reset entry points.
- Added Hive-backed local copies and cloud synchronization for Pantry,
  Groceries, Recipes, Saved Recipes, and Meal Plans.
- Added one RLS-protected `user_data` table with per-user collection payloads,
  stable collection-specific identities, and deletion tombstones.
- Added bidirectional collection merging so local changes are uploaded while
  records from another device are retained; local records take precedence when
  the same identity exists in both collections.
- Recorded the app walkthrough and documented its chapters in the demo guide.
- Updated the project documentation to reflect the implemented design system
  and current app behavior.
