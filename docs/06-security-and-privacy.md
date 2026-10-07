# Security and privacy

**Last checked:** 2026-10-07

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| Groceries, pantry items, custom recipes, meal plans, and saved recipes | Locally in Hive boxes on the user's device/browser | The user of that device/browser; there is no account or sync service |
| Recipe search text, recipe type, and selected recipe IDs | Sent over HTTPS to the Supabase `spoonacular` Edge Function and then to Spoonacular when Explore is used | Supabase/Spoonacular process the request; the app does not store a server-side copy |
| Recipe images referenced by Explore results | Loaded from the HTTPS image URL supplied by the recipe provider | The browser/device and the image host receive the request |

The app does not collect names, email addresses, passwords, payment details, or
precise location. Local data can still be read by someone who has access to the
same device or browser profile.

## Secrets

- Client configuration names: `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY`.
- Provider secret: `SPOONACULAR_API_KEY`.
- Local client configuration is in the git-ignored root `env.json`; the
  committed [`.env.example`](../.env.example) documents the configuration
  convention. CI reads the client values from GitHub Actions repository
  secrets.
- `SPOONACULAR_API_KEY` is stored only as a Supabase Edge Function secret and
  is read with `Deno.env`; it is not compiled into the Flutter app or sent to
  the browser.
- The deployed web build necessarily contains the Supabase URL and publishable
  key. They identify the project but are intended for client use; they do not
  grant access to a privileged Supabase role. No service-role key or other
  privileged credential is shipped.

## What protects the data on the service side

The repository defines no Supabase tables, user records, or RLS policies. App
lists remain local. The Supabase Edge Function is intentionally callable by
the client (`verify_jwt = false`) and has `Access-Control-Allow-Origin: *`;
there is no user authentication or per-user authorization at that endpoint.
It validates the supported actions and input lengths, keeps the Spoonacular
key server-side, forwards only the required recipe request, and returns
provider errors without exposing the key. Because the function is public,
usage and Spoonacular quota should be monitored.

## Checklist

- [x] `env.json` is in `.gitignore`, and `.env.example` is committed.
- [x] Git history was searched for `api_key`, `secret`, `password`, and
  `token`; no real credential was found.
- [x] No service account file, keystore, or `service_role` key is in the repo.
- [x] No backend app-data tables exist; the public function validates input and
  does not expose the provider key.
- [x] No real personal data is used in sample data, screenshots, or the app
  documentation.
- [x] No course or university credentials are stored in the repo.
- [x] No other person's data appears in the app's test data.

No key was found and revoked during this review.
