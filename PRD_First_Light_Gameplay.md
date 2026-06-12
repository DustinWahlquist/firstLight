# First Light — Gameplay Design Spec

**Version:** 1.0 (Draft)
**Author:** Dustin Wahlquist
**Date:** 2026-06-11
**Scope:** the match game ("the migration race") — extracted from `PRD_First_Light.md`, and authoritative for all match/gameplay rules. The main PRD covers the surrounding app: collection, catch logging, social, CMS.

---

## 1. The Game in One Paragraph

Two Watchers race their Flocks along a migration path. Each round is one in-game day: at **First Light** the players alternate activating birds one at a time — each bird either **flies** (banking its Migration Speed as kilometers) or, in a later gameplay layer, **uses a move** (fighting instead of flying). At **Night** every bird slides one slot down the Endurance Track, exhausted birds fall off into the discard, players draw cards and deploy new birds. **First Watcher to bank 10,000 km wins.**

---

## 2. Glossary

| Term | Meaning |
|---|---|
| **Watcher** | A player |
| **Aviary** | A player's full card collection (built by real-world birding) |
| **Flock** | The deck built from the Aviary for a match |
| **Roost** | The play area — in match terms, the Endurance Track |
| **Endurance Track** | Five slots (5→1) where deployed birds live; position = remaining endurance |
| **First Light** | The day phase: alternating bird activations |
| **Night** | The night phase: track shift, draw, deploy |
| **Tap** | Using a bird for the day (physically: turn the card sideways) |
| **Odometer** | A Watcher's running km total toward 10,000 |

---

## 3. Match Structure

- A match is a series of **rounds**; each round is one in-game day: **First Light** (day) then **Night**.
- **Win condition:** first Watcher to bank **10,000 km** of migration.
- **The Flock (deck): 50 cards**, built from the Watcher's Aviary. A Watcher with fewer than 50 birds has the Flock filled out with **starter cards** — generic low-level birds, visually marked as starters, that can't be leveled up. As the player's real collection grows, starters get crowded out naturally.
- **Setup:** each Watcher draws an opening hand of **5 cards** from their Flock deck.

---

## 4. First Light (Day Phase)

### 4.1 Initiative

At the start of each First Light, Watchers roll to determine who acts first.

- Each Watcher rolls a die and applies their **Initiative modifier** (derived from individual bird skills).
- A flat penalty applies based on active Flock size:

| Flock Size | Bird Count | Initiative Penalty |
|---|---|---|
| Small | 1–2 | 0 |
| Medium | 3–4 | −1 |
| Large | 5–6 | −2 |
| Extra Large | 7–8+ | −3 |

- **Exempt birds:** birds with traits like *Silent Riser* don't count toward the Flock Size threshold.
- Highest roll acts first; ties go to the Watcher with fewer birds in their Roost.

### 4.2 Alternating Activations

- The Initiative winner activates a **single bird**, then the opponent activates a single bird, back and forth.
- If one Watcher runs out of untapped birds, the other continues activating one at a time.
- **The day goes on until no one has any cards left to play in their Roost** — every bird activates every day.

### 4.3 Activating a Bird

Activating **taps** the bird (done for the day) and is a choice between two ways to spend its day:

- **Fly** — bank the bird's Migration Speed (×100 km, plus any Support boosts) on your odometer.
- **Use a move** *(second gameplay layer — see §8)* — attack the opposing Flock or play a Defense/Support effect. Fighting replaces flying: a bird that uses a move banks **no distance** that day.

> **V1 scope:** moves don't exist yet (no move content in the CMS), so every V1 activation is a fly. V1 is the pure migration race — all the decisions live in deck building and the Night phase.

---

## 5. Night Phase

In order:

1. **Track shift:** every bird slides one slot left on the Endurance Track and untaps; birds sliding off slot 1 go to the discard pile.
2. **Draw:** each Watcher draws **2 cards** from their Flock deck. **Maximum hand size is 7** — no forced discard; draws that would exceed the cap are forfeited (at 7 you draw nothing, at 6 you draw one).
3. **Deploy:** each Watcher may place up to **3 birds** onto the Endurance Track, each in the slot matching its Endurance stat. Deployment is always **free** — the only limit is the 3-per-night cap. Deployed birds are active from the next First Light.

Turn order during Night carries over from First Light.

---

## 6. The Endurance Track

The Roost is an **Endurance Track** — five slots labeled Endurance 5 down to Endurance 1, draw pile at the right end, discard pile at the left end. A bird's position on the track *is* its remaining endurance; no counters or damage markers exist.

**Hand → slot matching the bird's Endurance → slides left nightly → off the track → Discard**

- A bird deploys into the slot matching its Endurance stat (an Endurance 3 bird enters slot 3) — so a bird's lifespan is exactly its Endurance in days.
- High-speed or high-power birds typically have low Endurance (1–2): Flock stamina is a core strategic axis.

---

## 7. The Gameplay Card

A card in a match displays only what the match needs:

- Bird name + species classification
- Illustration
- **Level** and **XP bar**
- **Stats:** Migration Speed (1–10) and Endurance (1–5)
- **Moves** (future layer): up to 3, unlocked by level
- The owner's personal catch count for that species

Bird facts, trivia, and rarity live in the collection screens, not on the match card.

> *Future:* Migration Speed's 1–10 banding (×100 km) is a starting simplification — species should eventually carry more specific speeds closer to true km/day figures (e.g. 340 km rather than a flat 300).

---

## 8. Second Gameplay Layer: Moves (future — after the race is playable)

When species moves are authored in the CMS, the fly-or-move choice activates:

| Category | Description |
|---|---|
| **Offense** | Deal damage or reduce opponent's migration progress |
| **Defense** | Block, redirect, or absorb incoming attacks |
| **Support** | Boost allies' speed, endurance, or draw power (e.g., "Drafting" boosts migration; "Attracting" pulls in cards) |

- Up to **3 moves per bird**, unlocked at level milestones (player chooses which to keep).
- Move flavor follows bird classification (raptors skew offense, shorebirds support, songbirds utility).
- The attack cost is built into the activation economy: a fighting bird banks no km that day.

Also future: alternative win conditions (points knockout, contested territories, elevation, season distance) as variant/tournament formats.

---

## 9. Formats & Build Order

**Hotseat (dev milestone) → Asynchronous (V1) → Live (future).**

- **Asynchronous (V1):** take-your-turn matches with friends via invites; notifications when it's your move. Match state lives server-side and every action is validated there. Clients subscribe to match updates, so when both players are online, async feels real-time for free.
- **Live (future):** turn timers, presence, disconnect handling — a layer on the async engine, not a separate system.
- **Matchmaking (future):** skill-based ranked queue. V1 is friend invites only.
- **In-person/physical play and tournaments:** future, alongside physical cards.

---

## 10. Digital Presentation Principles

The physical-board concepts above (tap = sideways, five-column mat, dice odometer) describe the *rules*, **not the screen**. The digital version is free to move far from the tabletop layout — present endurance, hands, and migration however works best on a phone — as long as the rules and game state stay identical.

- **Portrait-first.** Matches are designed for vertical, one-handed phone play; landscape is never required. A natural anatomy: opponent's Roost compressed at top, the race odometers as a shared progress bar, your Roost, your hand at the bottom in thumb reach. iPad may use its larger canvas freely.
- **The track can be implicit.** Per-card "days left" indicators that tick down at Night are equivalent to track position — columns are optional.
- **Automate all bookkeeping:** the nightly shift, untaps, discards, draw caps, deploy-slot legality, and km math all just happen; the only player inputs are *which bird*, *fly or move*, and *what to deploy*.
- **Night is a moment.** The shift/draw/deploy sequence is the game's heartbeat — worth a sunset/sunrise transition rather than an instant state change.
- **Server-authoritative.** The client can only submit legal moves; the server holds match state and resolves everything (the app already works this way for catch logging).
- **Async pacing.** One day = several activation handoffs. Support notification batching and an optional "auto-fly the rest of my day" commitment so async matches don't ping-pong notifications.
- **Spectating/replay** falls out of server-held match state, eventually.

---

## 11. Open Design Questions

| # | Question | Priority |
|---|---|---|
| 1 | ~~Flock (deck) size?~~ Resolved: 50 cards, with starter-card fill for small aviaries (see §3). | — |
| 2 | Which cards or abilities allow retrieval from the discard pile? — deferred until species moves are designed (moves layer) | Deferred |
| 3 | ~~Max birds per Endurance Track slot?~~ Resolved: unlimited stacking. | — |
| 4 | Can Support effects restore endurance by sliding a bird right on the track? Likely yes — deferred until species moves are designed (moves layer) | Deferred |
| 5 | ~~Does deploying cost anything?~~ Resolved: Night deployment is always free, limited only by the 3-per-night cap. | — |
| 6 | What does a deck running out of cards mean — is decking out a loss, or do you race on with what's left? | Medium |

Resolved: flock migration distance is the **sum of fly activations** — each flying bird banks its own speed.
