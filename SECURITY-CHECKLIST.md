# Security checklist template

Copy this into your workspace `project/SECURITY-CHECKLIST.md` and fill it in
before you make your project repository public.

Every row gets one of **Yes**, **No** or **N/A**, and one line of evidence in
your own words: what you checked, where, and what you found. "N/A" is a correct
answer when it is true, but it needs its reason. A blank row scores nothing, and
a Yes your repository contradicts scores nothing either.

Replace the example evidence with your own.

## Secrets and credentials

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 1 | No API key, token or password is hardcoded in `lib/`, including in comments and commented-out code | Yes | Searched `lib/`; found only Supabase publishable-key configuration references, with no literal credential values. |
| 2 | Anything private is in a gitignored config or passed with `--dart-define`, with an example file committed | Yes | `.gitignore` excludes `.env` and `assets/config/supabase.json`; `.env.example` and `assets/config/supabase.example.json` contain placeholders, and the deploy workflow reads config through `--dart-define`. |
| 3 | No keystore, `key.properties` or signing credential is in the repository | Yes | Searched repository files and ignored-file status; no keystore, `key.properties`, or signing credential is present. |
| 4 | Git history is clean: I searched `git log -p` for password, secret, api key and token | Yes | Searched all available commit patches for those terms; matches were documentation and placeholder/config references, with no real credential value found. |
| 5 | Any credential that was ever committed has been rotated | N/A | The history search found no real credential committed, so there was no committed credential to rotate. |

## GitHub Actions

If your project has no workflows, mark every row N/A and say so once.

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 6 | No secret value is written literally in any workflow YAML file | Yes | Reviewed `.github/workflows/deploy-web.yml`; it reads URL and publishable-key values from secret references and contains no literal secret value. |
| 7 | Secrets are stored in repository Actions secrets and read with `${{ secrets.NAME }}` | Yes | Confirmed by the repository owner; `deploy-web.yml` reads both values using `${{ secrets.SUPABASE_URL }}` and `${{ secrets.SUPABASE_PUBLISHABLE_KEY }}`. |
| 8 | No workflow step echoes, dumps or debug-prints a secret, and I opened a recent run's log to confirm | N/A | There was no recent run log to inspect because the API configuration was not yet in place; reviewed workflow YAML contains no secret dump or debug print. |
| 9 | If I build a signed APK: the keystore is a base64 secret decoded to a file at build time, never printed | N/A | This workflow builds and publishes a Flutter web app; it does not build a signed APK. |
| 10 | Uploaded build artifacts contain no key file, keystore or generated config | Yes | The workflow uploads only `build/web`; the repository contains no key file or keystore, and the client config is compiled into the web app as public values. |
| 11 | Third-party actions are pinned to a commit SHA, not a moveable tag | Yes | All four external actions in `deploy-web.yml` use full commit SHAs, with release versions retained in comments. |
| 12 | Secret scanning and push protection are enabled on the repository | Yes | Confirmed by the repository owner: secret protection and push protection are enabled. |

## Backend and security rules

If your app is fully local with no backend, mark every row N/A and say so once.

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 13 | Firestore and Storage rules are not left open to anyone; they require an authenticated user | N/A | The app does not use Firestore or Firebase Storage; its app data remains in widget state on the device. |
| 14 | Rules restrict a user to their own documents where that makes sense | N/A | The app has no user documents or per-user backend data to restrict. |
| 15 | If Supabase: Row Level Security is on for every table | N/A | Supabase is used only for a callable Spoonacular Edge Function; this repository defines no Supabase database tables or user data policies. |
| 16 | Firebase and Google API keys are restricted in the Google Cloud console to the APIs and app they are for | N/A | The repository does not use Firebase or Google API keys. |
| 17 | I opened the app signed out and confirmed I could not read or write data I should not | N/A | The app has no account system or backend storage for its pantry, grocery, or recipe data; those lists live in session widget state. |
| 18 | Seed and sample data is invented, not real people's data | Yes | No personal test dataset is present in the repository; the example Supabase config contains placeholder values. |

## Input and app surface

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 19 | Input is validated before it is written, not only styled as valid in the UI | Yes | Pantry and grocery forms reject blank names before adding items, and the recipe form checks required fields and parses numeric fields before saving to widget state. |
| 20 | Nothing secret is recoverable from the built app, since a shipped binary can be unpacked | Yes | The Flutter client uses only the Supabase URL and publishable key; the Spoonacular key is read from `Deno.env` by the Edge Function and is not sent to the client. |

## Repository and privacy

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 21 | No student number, personal email, phone number or home address in the repository or in commit messages | Yes | Searched tracked project content and commit subjects; found no student number, personal contact details, or home address. |
| 22 | No classmate's personal data in the repository | Yes | Reviewed repository files and found no classmate personal data; app records are user-entered and session-only. |
| 23 | Dependencies come from pub.dev, and `build/` and `.dart_tool/` are gitignored | Yes | `pubspec.yaml` lists Flutter and pub.dev packages, and `.gitignore` excludes both `build/` and `.dart_tool/`. |
| 24 | Images, fonts and other assets are mine, licensed, or credited | N/A | No image or font asset files are bundled in this repository; runtime recipe images are provided by the recipe service. |
| 25 | Repository visibility is deliberate, and I checked it after my last push | Yes | Confirmed by the repository owner that the repository is public as intended. |

## Anything I found and fixed

The review confirmed that the Spoonacular credential is read server-side and that app lists stay in session state; it also surfaced that the workflow used moveable action tags and the Edge Function is publicly callable with `verify_jwt = false`. I pinned the workflow actions to release commit SHAs; there was no recent workflow run log to inspect because API configuration was not yet in place.
