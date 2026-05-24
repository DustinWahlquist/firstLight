# PRD: First Light CMS

**Version:** 0.1 (Draft)
**Author:** Dustin Wahlquist
**Date:** 2026-05-24
**Platform:** Web app (internal tool)

---

## 1. Overview

The First Light CMS is an internal web tool for managing all bird species content that powers the First Light mobile app. Every bird card players collect is backed by shared species data — stats, descriptions, facts, line art, and moves — that lives in the `bird_species` table and an upcoming `species_moves` table. The CMS gives the First Light team a UI to create, edit, and publish that content without touching the database directly.

---

## 2. Users

All users are **Content Admins** with full read/write access to species, moves, and art.

Auth: email/password via Supabase Auth. No public-facing sign-up.

---

## 3. Core Entities

### 3.1 Bird Species

One record per species (matches `bird_species.species_name` PK used in the app).

| Field | Type | Notes |
|---|---|---|
| Species name | text | Primary key, display name shown on card |
| Scientific name | text | Italic subtitle on card |
| Description | rich text | Shown on bird detail screen |
| Fun facts | list of strings | Shown as rotating trivia on card (up to 5) |
| Migration Speed | int 1–10 | Core stat |
| Endurance | int 1–5 | Core stat |
| Attack Power | int 1–10 | Core stat (not yet in app, build toward) |
| Defense | int 1–10 | Core stat (not yet in app, build toward) |
| Line art | image upload | SVG preferred; shown on card face |
| Status | enum | Draft / Published |

### 3.2 Moves

Each species can have up to 3 moves. Moves are authored per species (not shared globally — the same "Dive Bomb" might have different values on a Peregrine vs. a Tern).

| Field | Type | Notes |
|---|---|---|
| Move name | text | Shown on card |
| Category | enum | Offense / Defense / Support |
| Description | text | What the move does in plain language |
| Effect type | enum | Damage / Speed Boost / Endurance Drain / Draw / Shield / etc. |
| Effect value | int | Numeric magnitude of effect |
| Unlock level | int | Which level (1, 2, or 3) this move becomes available |

---

## 4. Key Screens

### 4.1 Species List

- Searchable, filterable table (filter by status, missing art, missing moves)
- Inline status badge (Draft vs. Published)
- Quick indicators: has line art ✓, move count, stat completeness
- Bulk actions: publish selected
- "New species" button

### 4.2 Species Editor

Full-page form. Two-column layout on desktop: fields on left, **live card preview** on right.

Sections:
- **Identity** — name, scientific name, status
- **Stats** — 4 sliders/number inputs with reference ranges shown (e.g., "Common Sparrow: 3 | Peregrine Falcon: 9")
- **Lore** — description + facts list (add/remove/reorder facts)
- **Line Art** — drag-and-drop upload zone; shows current art; renders in card preview instantly
- **Moves** — up to 3 move cards, each collapsible; add/remove/reorder

Auto-save draft. Explicit "Publish" button that makes changes live in the app.

### 4.3 Card Preview

Always-visible panel showing exactly how the card will render in the mobile app at the current form state. Renders the same visual hierarchy as the Flutter card: line art, name, stats, move slots.

### 4.4 Bulk Import

CSV upload for importing species en masse. Maps columns → fields, validates on upload, shows a diff preview before committing. Useful for seeding from eBird taxonomy data.

### 4.5 Stats Dashboard *(nice to have, v2)*

- Distribution charts for each stat across all species
- "Outlier" flagging — species that are likely over/underpowered by stat percentile

---

## 5. Navigation

```
Sidebar:
  Species          ← main content list
  Moves Library    ← browse/search all moves across species
  Drafts           ← unpublished changes
  Import           ← CSV bulk import
  Settings         ← user management, Supabase connection
```

---

## 6. Tech Notes (for dev handoff, not designer)

- Reads/writes directly to Supabase `bird_species` table and a new `species_moves` table
- Line art uploads to Supabase Storage bucket `line-art`
- Supabase RLS: CMS service role key bypasses RLS (internal tool, not user-facing)
- Stack suggestion: Next.js + Tailwind + Supabase JS client; hosted on Vercel

---

## 7. Out of Scope (v1)

- Player account management
- Match history or gameplay data
- Catch log moderation
- Localization / multi-language content
- Public API for third-party integrations

---

## 8. Open Questions

| # | Question |
|---|---|
| 1 | Should the move library be globally shared (one "Dive Bomb" record reused by many species) or always species-specific? |
| 2 | Is "Attack Power" and "Defense" ready to surface in the CMS now, or wait until the battle system design is finalized? |
| 3 | Who else besides you needs CMS access at launch? |
