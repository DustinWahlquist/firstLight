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

Each match is divided into rounds. Each round has two phases: **First Light** (day) and **Night**.

### 5.1 First Light (Day Phase)

First Light is the active movement and combat phase.

- **Migration:** Each Watcher moves their Flock based on active birds' Migration Speed stats (×100 km/day) and any Support boosts, advancing their km odometer.
- **Offensive actions:** Watchers may attack the opposing Flock — applying fatigue, disrupting active cards, or culling birds. Acting **taps** the bird (turned sideways; one action per day), and an offensive action costs one extra slot at the nightly Endurance Track shift (see 6.5).
- Turn order is determined by the Initiative roll (see 5.3).

> If a morning sub-phase is introduced later, it would occur at the top of First Light before movement and combat begin.

### 5.2 Night Phase

Night is the recovery and setup phase.

- **Track shift:** every bird slides one slot left on the Endurance Track (attackers slide two) and untaps; birds sliding off slot 1 go to the discard pile.
- **Draw:** Watchers draw cards from their personal Flock deck (the pick pile at the right end of the board).
- **Deploy:** Place birds onto the Endurance Track slot matching their Endurance stat, active from the next First Light.
- Turn order during Night carries over from First Light.

### 5.3 Initiative

At the start of each First Light, Watchers roll to determine turn order.

- Each Watcher rolls a die and applies their **Initiative modifier** (derived from individual bird skills).
- A flat penalty is applied based on active Flock size:

| Flock Size | Bird Count | Initiative Penalty |
|---|---|---|
| Small | 1–2 | 0 |
| Medium | 3–4 | −1 |
| Large | 5–6 | −2 |
| Extra Large | 7–8+ | −3 |

- **Exempt birds:** Birds with traits like *Silent Riser* do not count toward the Flock Size threshold — they join the Flock without slowing morning coordination.
- Highest roll acts first. Tiebreaker goes to the Watcher with the fewest birds in their Roost.

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
- **Stats:** Migration Speed, Endurance, Attack Power, Defense
- **Moves** (up to max, unlocked progressively by level): categorized as Offense, Defense, or Support
- **Bird facts** (rotating educational trivia)
- **Rarity indicator**
- Player's personal catch count for that species

### 6.5 Bird Lifecycle (In-Match): The Endurance Track

The Roost is an **Endurance Track** — five slots labeled Endurance 5 down to Endurance 1, with the draw pile at the right end and the discard pile at the left end. A bird's position on the track *is* its remaining endurance; no counters or damage markers are needed.

**Hand → track slot matching the bird's Endurance → slides left nightly → off the track → Discard**

- **Deploy (Night):** a bird enters the track at the slot matching its Endurance stat (an Endurance 3 bird is placed in slot 3).
- **Act (First Light):** using a bird — attacking, moving, supporting — **taps** it (turn the card sideways). A tapped bird can't act again that day.
- **Nightly shift:** when Night comes, every bird slides **one slot left** (the day's flying) and untaps. Taking an offensive action that day costs one **additional** slot at the shift — an attacker slides two.
- **Exhaustion:** a bird that slides off Endurance 1 leaves the board and goes to the discard pile.

High-speed or high-power birds typically have low Endurance (1–2), making Flock stamina a key strategic consideration alongside raw power.

### 6.6 Physical Cards

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

- Each bird card can hold up to **3 moves**.
- New moves unlock at level milestones.
- Players choose which moves to keep when a new one is unlocked, creating strategic decisions.
- Move quality is tied to **bird classification** (e.g., raptors skew offense, shorebirds skew support, songbirds could be support/utility).

---

## 8. Win Condition: The Migration

### 8.1 Core Win Condition

The game board represents a **bird migration path**. The goal is to **migrate your flock a total of 10,000 kilometers** before your opponent does.

- **1 round = 1 in-game day (First Light phase + Night phase)**
- **Migration Speed** is the primary stat determining how far your flock moves each round — a bird flies **Migration Speed × 100 km per day** (100–1,000 km)
- **Physical tracking:** each player keeps a four-digit km odometer with four D10 dice (thousands / hundreds / tens / ones)
- Modifiers:
  - **Drafting birds** (Support type) → boost migration speed
  - **Endurance** stat → limits how many days a bird can stay active; depleted birds move to discard
  - **Attracting birds** → pull in additional card/resource advantages
  - **Support power** → enables overnight travel (move during opponent's turn)

### 8.2 Alternative / Secondary Win Conditions (To Explore)

- Reduce opponent's points to 0
- Place X number of birds in contested territories on the board
- Reach a specific elevation (vertical migration variant)
- Travel the furthest cumulative distance across a season

> 10,000 km migration is the default win condition; the alternatives above are variant formats to explore for tournaments.

### 8.3 Digital Roost: board → app mapping

The physical board translates directly to the app, with the bookkeeping automated:

| Physical | Digital |
|---|---|
| Five Endurance Track slots on the mat | Roost screen renders the track as five columns; cards sit in their slot |
| Place a deployed bird in the slot matching its Endurance | Drag from hand; the app enforces the correct slot |
| Tap (turn sideways) to act | Literally tap the card; tapped state shown by rotating it |
| Nightly shift: slide every bird one slot left, untap | Cards animate one column left at Night automatically; extra slide applied to attackers |
| Slide off slot 1 → discard pile | Automatic, with a fly-away animation |
| Four D10 dice as a km odometer | Running km totals for both players, always visible; progress bar to 10,000 km |
| Initiative die roll each morning | Server-side roll, animated |
| Players police legality (slot placement, tap rules, drains) | The server is the rules authority — the client can only submit legal moves, mirroring how catch logging already works |

- **Async play** maps cleanly: your First Light actions are your turn; Night resolves automatically once both players have acted, then the next day begins.
- **Spectating/replay** falls out of server-held match state.
- The physical mat legend (bottom of the board sketch: Endurance / card / title / callouts) doubles as the print-at-home layout for matless play.

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

| # | Question | Priority |
|---|---|---|
| 1 | Which cards or abilities allow retrieval from the discard pile? | High |
| 2 | How does Flock migration distance combine across active birds — sum of speeds, slowest bird, or lead bird only? | High |
| 3 | Is there a max number of birds per Endurance Track slot, or unlimited stacking? | Medium |
| 4 | Can Support effects (e.g. Drafting) restore endurance by sliding a bird right on the track? | Medium |
| 5 | Does deploying mid-match cost anything, or is Night deployment always free? | Medium |

---

## 16. Out of Scope (V1)

- PvE / story campaign
- Guild / flock-team multiplayer (3+ players)
- Real-money card trading marketplace
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
