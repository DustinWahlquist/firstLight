# PRD: First Light

**Version:** 0.1 (Draft)
**Author:** Dustin Wahlquist
**Date:** 2026-05-22
**Platforms:** iOS, Android, iPadOS

---

## 1. Overview

### 1.1 Concept

Merlin Card Game is a collectible trading card game where your real-world birding activity — logged through the [Merlin Bird ID app](https://merlin.allaboutbirds.org/) — directly generates your card collection. Every bird you identify as a new lifer in Merlin becomes a playable card. The game blends the collection mechanics of **Pokémon**, the deck-building depth of **Magic: The Gathering**, and the social/chaotic energy of **Unstable Unicorns**.

The core fantasy: you are a bird watcher on a quest to become the **greatest bird watcher in the world** — not just in the field, but on the game board.

### 1.2 Elevator Pitch

> "Catch real birds with Merlin. Turn them into trading cards. Battle your flock against other watchers."

---

## 2. Terminology / Glossary

| Game Term | Meaning |
|---|---|
| **Watcher** | A player |
| **Aviary** | A player's full card collection |
| **Flock** | The active deck built for a match |
| **Roost** | The game mat / play area |
| **Lifer** | A bird species logged for the first time in Merlin |
| **Catch** | A Merlin bird ID log that grants XP to an existing card |
| **Migration** | The narrative win-condition journey across the game board |
| **First Light** | The day phase of each round — migration movement and offensive actions |
| **Night** | The night phase of each round — deck draw and card deployment |


---

## 3. Target Audience

- **Primary:** Casual to mid-core birders (ages 14–45) who already use Merlin Bird ID
- **Secondary:** Trading card game players (MTG, Pokémon) curious about a nature-based theme
- **Tertiary:** Families and educators using birding as an outdoor activity

---

## 4. Core Gameplay Loop

```
Real-world birding (Merlin app)
        ↓
New lifer → Card added to Aviary (1 card per species)
Repeat catch of same species → +XP on existing card
        ↓
Build a Flock (deck) from your Aviary
        ↓
Battle other Watchers (online, in-person, or async)
Each round: First Light (move + attack) → Night (draw + deploy)
        ↓
Earn rewards, level up birds, climb leaderboards
```

---

## 5. Turn Structure

The complete match design — round structure, initiative, alternating activations, and the hand economy — lives in **[PRD_First_Light_Gameplay.md](PRD_First_Light_Gameplay.md)**, the authoritative gameplay spec.

---

## 6. Card System

### 6.1 Card Acquisition

- **One card per species.** A player can only ever hold one card per bird species.
- **New lifer = new card.** When a bird is logged as a lifer in Merlin, a card for that species is added to the player's Aviary with a cinematic "card reveal" animation.
- **Catch limit:** 1 catch-logged XP gain per bird per day. This prevents grinding and keeps the game grounded in real birding behavior.
- **Existing species:** Subsequent Merlin logs of the same bird do not create a second card — they grant XP to level up the existing card.

### 6.2 Card Levels & XP

- Cards start at **Level 1** when first acquired.
- Each additional real-world catch (up to 1/day) awards XP, leveling the card up over time.
- Higher levels unlock:
  - Additional **moves** (up to 3 slots max)
  - Alternate **card art / skins**
  - Improved **base stats**
- Leveling is **XP-based**, not catch-count based, to support future flexibility (e.g., rare birds give more XP per catch).

### 6.3 Sighting Rarity

- Rarity is a property of the **individual sighting, not the species** — Merlin reports how rare a sighting is for its time of year and location, and the screenshot parse captures it.
- There are exactly three tiers, and XP per catch scales with them:

| Sighting Rarity | XP per Catch |
|---|---|
| Common | 5 |
| Uncommon | 10 |
| Rare | 15 |

- **Endangered species** are included with in-app educational prompts and conservation messaging.

### 6.4 Card Anatomy

Each card displays:
- Bird name + species classification
- High-quality illustration (sourced from Merlin / Cornell Lab assets where licensed)
- **Level** and **XP bar**
- **Stats:** Migration Speed and Endurance (Attack Power and Defense may join when the moves system lands)
- **Moves** (up to max, unlocked progressively by level): categorized as Offense, Defense, or Support
- Player's personal catch count for that species

Bird facts and trivia live on the bird detail screen in the collection, not on the gameplay card — the card carries only what a match needs.

### 6.5 Bird Lifecycle (In-Match)

The Endurance Track — how birds live and die during a match — is specified in the gameplay spec.

### 6.6 Physical Cards (future add — not in initial scope)

- **Print-at-home:** App exports printable card sheets with current stats
- **Professionally printed:** Physical product / merchandise integration
- Handwritten stats fields on the printed card template (for use in physical-only play without app access)

---

## 7. Moves System

Moved to the gameplay spec (second gameplay layer, arriving after the migration race is playable).

---

## 8. Win Condition: The Migration

The 10,000 km race, km tracking, and the digital presentation principles are specified in the gameplay spec.

---

## 9. Gameplay Formats

Formats and the build order (hotseat → asynchronous V1 → live later) are specified in the gameplay spec.

---

## 10. Trading (future)

- **In-person only, always.** Cards can only be traded peer-to-peer via proximity/QR code. Online trading will never be available.
- **Trade consequences:**
  - When you trade a card away, you **lose it entirely** — including all accumulated levels and XP.
  - If you later re-catch that bird in Merlin, you start a new Level 1 card from scratch.
  - If you receive a card you already own (same species), the **higher-level card wins** and the received card's XP is added to your existing card. If the merged total crosses a level threshold, a level-up walkthrough triggers to apply the new level and any unlocked moves.
- **Strategic intent:** Trading is high-stakes and meaningful — rare/leveled cards are genuinely valuable.

---

## 11. Player Profile & Progression

### 11.1 Profile Stats

- Total lifers caught
- Aviary size (total unique species)
- Match record (W/L/D)
- Migration total (cumulative km migrated across all matches)
- Map view: heatmap or pins of first-catch locations across the full Aviary and active Flock


### 11.2 Bird Stats (Per Card)

- Total XP / current level
- Number of real-world catches
- Location and date of first catch
- Games played with this bird
- Win rate when this bird is in the active Flock
- Move history

### 11.3 Onboarding / New Player Experience

- On first launch: connect Merlin account → app imports entire life list
- All lifers become Level 1 cards in the Aviary instantly
- Cards for species caught multiple times before joining start with **bonus XP** reflecting catch history- Tutorial match with a curated starter Flock; starter cards are visually marked as such and cannot be leveled up — they fill out the Flock until the player has enough lifers to replace them with real cards

---

## 12. Merlin Integration

- **Auth:** OAuth or deep-link handshake with Merlin Bird ID app
- **Life list sync:** Pull full lifer history on first connect; incremental sync on app open
- **Daily catch sync:** Background sync or user-triggered refresh to pick up same-day catches
- **Data used:** Species name, date first caught, location (region/country), total catch count


---

## 13. Platform Requirements

### 13.1 iOS

- Minimum deployment target: iOS 16+
- Support for Dynamic Island / Live Activities for match notifications (iPhone 14 Pro+)
- Haptic feedback on card reveals and level-ups

### 13.2 Android

- Minimum SDK: API 31 (Android 12)
- Material You theming support
- Equivalent notification support for async matches

### 13.3 iPadOS

- **First-class iPad support** — not a scaled-up phone layout
- Multi-column Aviary browser
- Side-by-side Flock builder + Aviary view
- Full Roost game board takes advantage of larger canvas
- Keyboard + trackpad/mouse support for tournament/competitive play
- Drag-and-drop card management

---

## 14. Monetization (Preliminary)

- **Free to play** with full core game loop accessible
- **Cosmetics:** Alternate card art, card backs, Roost themes, animation effects — no pay-to-win
- **Physical card printing:** In-app purchase for high-quality card print orders
- **Tournament entry:** Optional paid competitive brackets with physical prizes
- **No card-locking behind paywalls** — all cards earned through real-world birding

---

## 15. Open Questions / To Be Decided

Gameplay design questions moved to the gameplay spec.

---

## 16. Out of Scope (V1)

- PvE / story campaign
- Guild / flock-team multiplayer (3+ players)
- Real-money card trading marketplace
- Print-at-home and professionally printed physical cards
- Integration with eBird or other birding platforms (post-Merlin)
- AR card reveal / battle overlay
- Animated card art

---

## 18. MVP Scope

The MVP focuses exclusively on the card creation and leveling loop — proving the core fantasy of turning real birding into cards — before building the battle system.

### 18.1 Platform

- iOS + Android via a single Flutter codebase

### 18.2 Core Flow

1. User imports a Merlin screenshot (camera roll or share sheet)
2. Claude vision API parses the screenshot: bird species, sighting rarity, date, location
3. **New lifer:** Card created at Level 1 and added to the Aviary with a card reveal
4. **Existing species:** XP awarded based on sighting rarity (Common 5 / Uncommon 10 / Rare 15); level-up walkthrough triggers if a threshold is crossed
5. **1 catch per bird per day** enforced — duplicate submissions within the same calendar day are rejected

### 18.3 Card Art

- Placeholder art in MVP
- Every parsed screenshot is stored in a DB, passively building a dataset of real bird imagery to power AI-generated card art in future releases

### 18.4 Aviary

- Basic browser to view collected cards with level, XP bar, and first-catch location and date

### 18.5 Out of MVP Scope

- Flock building and deck management
- All gameplay (First Light, Night, Initiative, migration, combat)
- Trading
- Multiplayer and matchmaking
- Physical card printing
- Full Merlin OAuth integration

---

## 17. Success Metrics

- **Activation:** % of Merlin users who connect their account within 7 days of install
- **Retention (D7, D30):** Return rate of connected Merlin users
- **Engagement:** Average matches played per week per active user
- **Real-world impact:** Increase in Merlin lifer logs per user post-install (are players going birding more?)
- **Aviary depth:** Average unique species in player Aviaries at 30 days
