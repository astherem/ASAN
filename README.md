# Asan

> Asan is a meal planning and pantry management mobile app designed for students and busy households who want to plan meals, organize ingredients, and reduce food waste with less effort.

**Live demo:** https://benicemalig.github.io/ASAN/ <br>
**Demo video:** To be added after recording. <br>
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University <br>
**Author:** Benice Asheret Malig

---

## Screenshots

Put two or three real screenshots at phone size in `docs/assets/`, then replace
this paragraph with them:

```markdown
| Home | Detail | Add |
| --- | --- | --- |
| ![Home](docs/assets/screen-home.png) | ![Detail](docs/assets/screen-detail.png) | ![Add](docs/assets/screen-add.png) |
```

A repo without screenshots reads as abandoned, whatever the code says.

## What it does

- Discover, save, and add recipes.
- Plan and manage meals for the week.
- Track pantry items and monitor expiration dates.
- Create grocery lists based on planned meals.

## Built with

| | |
| --- | --- |
| Framework | Flutter (Dart) |
| State | Local widget state with `setState` |
| Storage | None yet; current data is sample or in-memory data |
| Other packages | `material_symbols_icons` for icons, `google_fonts` for typography, `device_preview` for responsive previews, and `image_picker` for image selection support |

## Running it yourself

```bash
flutter pub get
flutter run -d web-server --web-port 8080
```

Then open http://localhost:8080. Requires Flutter (run `flutter --version` and
put yours here).

### Environment variables

This project reads its configuration from a `.env` file that is **not** in the
repository. Copy `.env.example`, fill in your own values, and never commit the
result.

| Variable | What it is | Where to get one |
| --- | --- | --- |
| `EXAMPLE_API_KEY` | ... | ... |

## Privacy and secrets

- What personal data this app stores, if any, and where it goes.
- Where the secrets live (`.env` locally, repository secrets in the deploy
  workflow) and what protects the data on the service side (Firestore rules,
  Supabase RLS, or "nothing leaves the device").
- Confirm that all sample data, screenshots and the video contain **no real
  personal information**.

## Project documentation

| Document | |
| --- | --- |
| [Proposal](docs/01-proposal.md) | the problem, the users, the scope |
| [Mockup and wireframes](docs/02-mockup.md) | what it looks like, and the screen flow |
| [Design system](docs/03-design-system.md) | colors, type, spacing, components |
| [Weekly reports](docs/04-weekly-reports.md) | what happened each week |
| [Demo video](docs/05-demo-video.md) | the recording and what it shows |
| [Start here](START-HERE.md) | how this repo works (delete once you have read it) |
| [Security and privacy](docs/06-security-and-privacy.md) | the checklist, filled in |

## Status and what is next

Be honest. What works, what is half done, what you would build next. An honest
"known issues" section reads better than a claim the reader disproves in thirty
seconds.

**What works:** Main navigation, recipe browsing and creation, pantry and grocery forms, search, filters, sorting, and grocery-to-pantry handoff are implemented.

**What is half done:** Meal plan view and persistent storage are still in progress.

**What would be built next:** Complete meal scheduling, add persistence, replace placeholder recipe data.

## Credits

- Packages: see `pubspec.yaml`
- Icons: by Google and Tim Maffett, licensed under the [Apache License Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)

## AI use

AI tools were used to support documentation, implementation review, and debugging. Final design and code decisions were reviewed in the project files.

## Licence

MIT, see [LICENSE](LICENSE).
