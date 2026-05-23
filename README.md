# First Light — Murmuration MVP

Turn real-world Merlin Bird ID catches into trading cards.

## Prerequisites

| Tool | Install |
|---|---|
| Flutter SDK | `brew install --cask flutter` (macOS) |
| Supabase CLI | `brew install supabase/tap/supabase` |
| Deno (for Edge Functions) | `brew install deno` |

After installing Flutter, run `flutter doctor` to confirm the toolchain is ready.

## Project setup

### 1. Generate native platform directories

This repo contains only Dart source files. Run once to generate the `android/`
and `ios/` directories:

```sh
flutter create . --project-name first_light --org com.murmuration
```

### 2. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) → New Project
2. Note your **Project URL** and **anon public key** (Settings → API)
3. Set your Anthropic key as a secret:
   ```sh
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
   ```

### 3. Apply the database schema

```sh
supabase db push
```

Or paste `supabase/migrations/20260522000000_initial_schema.sql` directly into
the Supabase SQL editor.

### 4. Deploy the Edge Function

```sh
supabase functions deploy parse-screenshot
```

### 5. Run the Flutter app

Pass your Supabase credentials as compile-time constants so they are never
hard-coded:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

For VS Code, add a `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "First Light",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=${env:SUPABASE_URL}",
        "--dart-define=SUPABASE_ANON_KEY=${env:SUPABASE_ANON_KEY}"
      ]
    }
  ]
}
```

Then set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your shell environment (or
a `.env` file that VS Code loads).

## Architecture

```
Flutter app (iOS + Android)
  └── SupabaseService
        ├── uploadScreenshot()  →  Supabase Storage (screenshots bucket)
        ├── processScreenshot() →  parse-screenshot Edge Function
        │                              └── Claude vision API (claude-sonnet-4-6)
        ├── fetchAviary()       →  aviary_cards table
        └── catch_log table     (daily limit enforcement)
```

## MVP scope

- [x] Screenshot import (gallery or camera)
- [x] Claude vision parsing → species name, rarity, location
- [x] New lifer → card created at Level 1, card reveal animation
- [x] Existing species → XP awarded, level-up detection
- [x] 1 catch per bird per day (enforced in app + DB unique index)
- [x] Aviary browser (species, level, XP bar, first-catch date/location)
- [ ] Flock building and gameplay (post-MVP)
- [ ] Trading (post-MVP)
- [ ] Merlin OAuth integration (post-MVP)
