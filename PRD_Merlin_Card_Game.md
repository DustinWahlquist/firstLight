# PRD: Merlin Card Game

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

> Note: "Flock" is a working name for the deck — alternatives to explore: *Wing*, *Roost*, *Flight*. "Arena" vs. "Atrium" vs. "Aviarium" are under consideration for the competitive play space name.

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

Each match is divided into rounds. Each round has two phases: **First Light** (day) and **Night**.

### 5.1 First Light (Day Phase)

First Light is the active movement and combat phase.

- **Migration:** Each Watcher moves their Flock based on active birds' Migration Speed stats and any Support boosts.
- **Offensive actions:** Watchers may attack the opposing Flock — applying fatigue, disrupting active cards, or culling birds.
- Turn order is determined by the Initiative roll (see 5.3).

> If a morning sub-phase is introduced later, it would occur at the top of First Light before movement and combat begin.

### 5.2 Night Phase

Night is the recovery and setup phase.

- **Draw:** Watchers draw cards from their personal Flock deck.
- **Deploy:** Place birds onto the Roost to be active in the next First Light.

### 5.3 Initiative

At the start of each First Light, Watchers roll to determine turn order.

- Each Watcher rolls a die and applies their **Initiative modifier** (derived from individual bird skills).
- A flat penalty is applied based on active Flock size:

| Flock Size | Initiative Penalty |
|---|---|
| Small | 0 |
| Medium | −1 |
| Large | −2 |
| Extra Large | −3 |

- **Exempt birds:** Birds with traits like *Silent Riser* do not count toward the Flock Size threshold — they join the Flock without slowing morning coordination.
- Highest roll acts first. Tiebreaker: TBD.

> Exact bird-count breakpoints per tier are TBD pending playtesting.

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
  - Additional **moves** (up to a max hand size, similar to Pokémon's 4-move limit)
  - Alternate **card art / skins**
  - Improved **base stats**
- Leveling is **XP-based**, not catch-count based, to support future flexibility (e.g., rare birds give more XP per catch).

### 6.3 Card Rarity

- Rarity is tied to **real-world bird rarity and geographic distribution** — rare birds in Merlin yield higher-XP cards with better base stats.
- Rare birds = more XP per catch, more powerful moves, and potentially exclusive aesthetics.
- **Endangered species:** TBD — consider whether to include them as ultra-rare cards to promote conservation awareness, or exclude them to avoid gamifying endangered populations. Recommended: include with in-app educational prompts and conservation messaging.

### 6.4 Card Anatomy

Each card displays:
- Bird name + species classification
- High-quality illustration (sourced from Merlin / Cornell Lab assets where licensed)
- **Level** and **XP bar**
- **Stats:** Migration Speed, Endurance, Attack Power, Defense
- **Moves** (up to max, unlocked progressively by level): categorized as Offense, Defense, or Support
- **Bird facts** (rotating educational trivia)
- **Rarity indicator**
- Player's personal catch count for that species

### 6.5 Physical Cards

- **Print-at-home:** App exports printable card sheets with current stats
- **Professionally printed:** Future physical product / merchandise integration
- Handwritten stats fields on the printed card template (for use in physical-only play without app access)

---

## 7. Moves System

### 7.1 Move Categories

| Category | Description |
|---|---|
| **Offense** | Deal damage or reduce opponent's migration progress |
| **Defense** | Block, redirect, or absorb incoming attacks |
| **Support** | Boost allies' speed, endurance, or draw power (e.g., "Drafting" birds boost migration speed; "Attracting" birds pull in more cards) |

### 7.2 Move Slots

- Each bird card can hold a **limited number of moves** (exact number TBD — likely 3–4).
- New moves unlock at level milestones.
- Players choose which moves to keep when a new one is unlocked, creating strategic decisions.
- Move quality is tied to **bird classification** (e.g., raptors skew offense, shorebirds skew support, songbirds could be support/utility).

---

## 8. Win Condition: The Migration

### 8.1 Core Win Condition

The game board represents a **bird migration path**. The goal is to **migrate your flock a total of 10,000 kilometers** before your opponent does.

- **1 round = 1 in-game day (First Light phase + Night phase)**
- **Migration Speed** is the primary stat determining how far your flock moves each round
- Modifiers:
  - **Drafting birds** (Support type) → boost migration speed
  - **Endurance** stat → sustains speed over long matches
  - **Attracting birds** → pull in additional card/resource advantages
  - **Support power** → enables overnight travel (move during opponent's turn)

### 8.2 Alternative / Secondary Win Conditions (To Explore)

- Reduce opponent's points to 0
- Place X number of birds in contested territories on the board
- Reach a specific elevation (vertical migration variant)
- Travel the furthest cumulative distance across a season

> Recommendation: Use migration distance (10k km) as the default win condition, with variant formats for tournaments.

---

## 9. Gameplay Formats

### 9.1 Online

- **Live (synchronous):** Real-time 1v1 matches with turn timers
- **Asynchronous:** Take-your-turn matches; notifications when it's your move
- **Matchmaking:** Skill-based rating system; considers Flock strength and player win/loss record
- **Leaderboards:** Global and friends-based ranking

### 9.2 In-Person / Physical

- Players use the app to display their active Flock during play (Merlin bird data required for move verification)
- Physical printed cards can be used; app serves as the rulebook and stat tracker
- **Competitive physical play:** A way to normalize deck power levels for friendly play (e.g., handicap system or power-capped formats)

### 9.3 Tournaments

- In-person and virtual tournament brackets
- Tournament format may restrict Flock building (e.g., power caps, regional bird restrictions)
- Prizes: in-app cosmetics, physical card packs, or XP boosts

---

## 10. Trading

- **In-person only.** Cards can only be traded peer-to-peer via proximity/QR code, not over the internet.
- **Trade consequences:**
  - When you trade a card away, you **lose it entirely** — including all accumulated levels and XP.
  - If you later re-catch that bird in Merlin, you start a new Level 1 card from scratch.
  - If you receive a card you already own (same species), the **higher-level card wins** — but whether XP stacks is TBD. Recommend: XP merges, preserving progress.
- **Strategic intent:** Trading is high-stakes and meaningful — rare/leveled cards are genuinely valuable.

---

## 11. Player Profile & Progression

### 11.1 Profile Stats

- Total lifers caught
- Aviary size (total unique species)
- Match record (W/L/D)
- Migration total (cumulative km migrated across all matches)
- Favorite Flock composition
- Rarest bird owned

### 11.2 Bird Stats (Per Card)

- Total XP / current level
- Number of real-world catches
- Games played with this bird
- Win rate when this bird is in the active Flock
- Move history

### 11.3 Onboarding / New Player Experience

- On first launch: connect Merlin account → app imports entire life list
- All lifers become Level 1 cards in the Aviary instantly
- Cards for species caught multiple times before joining start with **bonus XP** reflecting catch history (but not full levels — exact formula TBD)
- Tutorial match with a curated starter Flock

---

## 12. Merlin Integration

- **Auth:** OAuth or deep-link handshake with Merlin Bird ID app
- **Life list sync:** Pull full lifer history on first connect; incremental sync on app open
- **Daily catch sync:** Background sync or user-triggered refresh to pick up same-day catches
- **Data used:** Species name, date first caught, location (region/country), total catch count
- **Offline mode:** Aviary and Flock management works offline; battle sync requires connectivity

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

| # | Question | Priority |
|---|---|---|
| 1 | Final name for the deck ("Flock", "Roost", "Wing"?) | High |
| 2 | Final name for competitive play space ("Arena", "Atrium", "Aviarium"?) | Medium |
| 3 | Exact move slot count per card (3 or 4?) | High |
| 4 | XP formula for importing existing Merlin life list on first login | High |
| 5 | Whether trading a duplicate gives merged XP or just takes the higher card | High |
| 6 | Whether endangered species are included, and how they're framed | Medium |
| 7 | Exact win condition tuning (10k km? Different for casual vs. competitive?) | High |
| 8 | How physical play authenticates moves without always-on app access | Medium |
| 9 | Whether online trading (non-in-person) is ever unlocked | Low |
| 10 | Whether geographic rarity is dynamic (bird ranges shift seasonally) | Low |
| 11 | Exact bird-count breakpoints for Small / Medium / Large / XL Flock tiers | High |
| 12 | Tiebreaker rule for identical Initiative rolls | Medium |
| 13 | Night phase turn order — carry over from First Light, or re-roll? | Medium |

---

## 16. Out of Scope (V1)

- PvE / story campaign
- Guild / flock-team multiplayer (3+ players)
- Real-money card trading marketplace
- Integration with eBird or other birding platforms (post-Merlin)
- AR card reveal / battle overlay
- Animated card art

---

## 17. Success Metrics

- **Activation:** % of Merlin users who connect their account within 7 days of install
- **Retention (D7, D30):** Return rate of connected Merlin users
- **Engagement:** Average matches played per week per active user
- **Real-world impact:** Increase in Merlin lifer logs per user post-install (are players going birding more?)
- **Aviary depth:** Average unique species in player Aviaries at 30 days
