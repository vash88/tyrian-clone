# Tyrian Core Canonical Spec

## Purpose

This document is the decision authority for the Tyrian core gameplay specification set. It defines the target product, scope boundaries, parity policy, canonical terminology, and shared state model for a near-parity single-player Full Game implementation.

This spec package is grounded in:

- `references/tyrian21/manual.doc` for original player-facing behavior, world structure, and terminology.
- `references/opentyrian-master/doc/files.txt` for data ownership and campaign-script structure.
- `references/opentyrian-master/doc/tyrian.hdt.txt` for decoded item, weapon, ship, sidekick, shield, and enemy data structures.
- `references/opentyrian-master/src/mainint.c`, `player.c`, `varz.c`, and `config.h` for implementation clues and default loadout behavior.
- `rewrite-prototype/src/game/*` for the current project's reduced baseline and naming bridge.

## Product Goal

Build a **Tyrian 2.x / OpenTyrian-era, 1-player Full Game core** with near-parity gameplay behavior and original terminology, while delivering the first implementation pass as a curated vertical slice rather than full content extraction.

The target is not a reinterpretation. The target is Tyrian's campaign, loadout, combat, progression, and economy structure adapted into a modern codebase with explicit data definitions.

## Scope

### In Scope

- 1-player Full Game campaign flow
- Ship loadout and shop flow
- Planet and node progression
- Scrolling level play
- Enemy waves, bosses, hazards, and pickups
- Front and rear weapon power progression
- Generator, shield, armor, and sidekick systems
- Credits, datacubes, and level-to-level progression
- Difficulty as gameplay tuning

### Out of Scope

- Network, modem, or multiplayer modes
- Control remapping, settings UX, installer/runtime behavior
- Save-slot UX, frontend polish, and platform-specific menus
- Demo playback and attract mode
- Super Arcade and Super Tyrian special-case rule sets
- Full asset extraction of every original item, enemy, and level in this pass

## Canonical Loop

The canonical loop for this spec package is:

1. Start or resume a Full Game campaign.
2. Review current datacubes, campaign status, and available route.
3. Enter shop or ship configuration for the current progression point.
4. Commit to the next navigation node.
5. Play a scrolling level with pickups, wave events, hazards, and boss logic.
6. Resolve the level outcome.
7. Apply rewards, unlocks, datacubes, and progression changes.
8. Return to navigation, shop, or episode transition as authored by the campaign script.

## First-Pass Principle

The first implementation pass preserves Tyrian's original structure and terminology, but narrows authored content to a vertical slice that exercises the full game loop.

The first pass must prove:

- a multi-node campaign route rather than a single stage
- persistent loadout and economy across levels
- front and rear weapon power progression
- generator competition between weapon fire and shield recharge
- meaningful sidekick support
- credits, datacubes, and shop decisions
- at least one branch in progression
- at least one boss-gated level completion

The first pass does **not** need exhaustive content parity across all episodes.

## Core Invariants

The following are canonical and must not drift across docs or implementation:

- Front and rear weapons each use **11 power levels**.
- Some rear weapons support **2 fire modes**, switched at runtime.
- Generators govern both **weapon sustainability** and **shield recharge throughput**.
- Shields and armor are distinct survival layers.
- Sidekicks are independent left and right equipment slots with distinct behavior models.
- In-level pickups and between-level shop progression both materially affect power growth.
- Datacubes are part of campaign progression and information flow, not just flavor collectibles.
- Level flow is authored by episode script data, not generated.

## Parity Policy

Use the following policy when the sources are strong, weak, or conflicting.

### Exact Reference-Derived

Use exact original naming, counts, and behavior when the local references are explicit enough to support direct implementation. Examples:

- 11 weapon power levels from the manual and OpenTyrian data structures
- generator/shield coupling from the manual
- HDT counts and data roles from `tyrian.hdt.txt`
- Full Game default loadout in `mainint.c`

### Reference-Informed Approximation

Use original naming plus mechanically faithful approximation when the references establish the system but not every numeric detail needed for the first pass. Examples:

- first-pass enemy HP or fire cadence when exact extraction is deferred
- specific shop inventory timing for an authored vertical slice
- exact level event timing when building a new authored slice inspired by original episode structure

### Placeholder Pending Extraction

Use placeholders only when the design needs a stub to preserve architecture and the local references do not yet resolve the exact content. Placeholders must be explicitly labeled and isolated to first-pass tables, never silently treated as canon.

## Reference Conflicts and Resolution

Known reference ambiguity already present in local materials:

- `manual.doc` says a Full Game begins with the **USP Perren Scout**.
- `opentyrian-master/src/mainint.c` initializes a new game with ship id `1`, commented as **USP Talon**.

Canonical resolution for this spec package:

- Treat the **original Full Game concept** as "a light starter ship with reduced armor and high speed."
- Treat the exact ship label as **ambiguous in the local references**.
- For the first implementation pass, use the OpenTyrian-initialized loadout as the operational baseline because it is directly tied to code and item ids.
- Preserve the ambiguity note in campaign and content docs so a later extraction pass can settle it conclusively.

## Shared State Model

The implementation should organize gameplay state into these canonical domains.

### Campaign State

Persistent state across the whole run.

- current episode
- current navigation node
- completed levels
- unlocked routes
- discovered datacubes
- persistent credits
- owned inventory
- current equipped loadout
- selected difficulty
- campaign flags from script events

### Mission State

Transient state for the currently active level.

- level id
- elapsed time and scroll progress
- player combat state
- spawned enemies and hazards
- pickups currently in play
- boss phase state
- mission reward buffer
- completion or destruction outcome

### Player Loadout State

Persistent equipment and power selections that enter each mission.

- ship
- front weapon and current purchased power level
- rear weapon and current purchased power level
- active rear mode
- shield
- generator
- left sidekick
- right sidekick
- optional special slot reserved for later parity

### Shop State

The purchasable inventory and pricing rules at a progression point.

- inventory list
- unlock constraints
- current prices
- comparison state against equipped items
- upgrade affordance for front and rear power levels

### Unlock and Discovery State

Information the campaign has revealed even if not currently equipped.

- owned ships
- owned weapons
- owned sidekicks
- unlocked route destinations
- obtained datacubes
- boss-clear and branch flags

### Datacube State

Player-readable intel and progression facts.

- datacube ids obtained
- datacube text or associated script payload
- mission or route conditions revealed by cubes

## Canonical Gameplay-Facing Types

The following types are canonical. Their field-level definitions live in the referenced docs and should be mirrored directly in code and authored data.

| Type | Purpose | Home Doc |
| --- | --- | --- |
| `CampaignState` | Persistent run progression across episode nodes, inventory, credits, and discovery | `01-campaign-progression.md` |
| `MissionState` | Runtime level/session state for one scrolling mission | `01-campaign-progression.md` |
| `PlayerLoadout` | Equipped ship, ports, sidekicks, and current purchased power levels | `02-player-combat-and-loadout.md` |
| `ShipDefinition` | Ship identity, armor profile, speed band, cost, and loadout constraints | `02-player-combat-and-loadout.md` |
| `WeaponPortDefinition` | Front or rear weapon entry, power levels, modes, cadence, drain, and cost | `03-weapons-shields-generators-sidekicks.md` |
| `WeaponFireMode` | Runtime-selected mode for multi-mode rear weapons | `03-weapons-shields-generators-sidekicks.md` |
| `ShieldDefinition` | Shield capacity, recharge gate, and generator demand | `03-weapons-shields-generators-sidekicks.md` |
| `GeneratorDefinition` | Energy throughput and sustainability profile | `03-weapons-shields-generators-sidekicks.md` |
| `SidekickDefinition` | Left/right option behavior, charge, ammo, attachment mode, and cost | `03-weapons-shields-generators-sidekicks.md` |
| `EnemyDefinition` | Base enemy stats, pathing, fire patterns, drops, and score value | `04-enemies-bosses-and-encounters.md` |
| `BossPhaseDefinition` | Boss phase scripts, gates, attacks, and weak-point rules | `04-enemies-bosses-and-encounters.md` |
| `LevelDefinition` | Scrolling mission content, authored events, hazards, and completion gates | `05-levels-nav-and-datacubes.md` |
| `LevelEvent` / `WaveDefinition` | Spawn, hazard, script, and reward events inside a level timeline | `05-levels-nav-and-datacubes.md` |
| `NavNodeDefinition` | Campaign graph node for level, shop, datacube, branch, or intermission content | `05-levels-nav-and-datacubes.md` |
| `DatacubeDefinition` | Player-readable intel collectible with script and unlock payload | `05-levels-nav-and-datacubes.md` |
| `ShopInventoryRule` | Availability logic and pricing for shop entries at a progression point | `06-shop-economy-and-upgrades.md` |
| `PickupDefinition` | In-level pickup type, effect, persistence, and collision behavior | `02-player-combat-and-loadout.md` |

## Canonical Terminology

Use the following terms consistently across docs and implementation:

- **Full Game**: the campaign mode with navigation, datacubes, and persistent progression.
- **Mission**: one scrolling gameplay level.
- **Node**: one authored point in the campaign graph.
- **Front weapon** and **Rear weapon**: the two main player weapon ports.
- **Power level**: a purchased or collected weapon rank from 1 to 11.
- **Generator power** or **energy**: the shared throughput that limits firing and shield recharge.
- **Sidekick**: left or right support unit or option.
- **Datacube**: campaign intel collectible.
- **Credits**: shop currency collected from pickups and mission rewards.

## Acceptance Criteria for the Spec Package

The spec package is complete only if:

- a reader can derive the first-pass campaign loop without consulting source code
- generator, shield, and weapon competition rules are explicit
- first-pass shop inventory and route progression are explicit
- first-pass enemy and boss roles are explicit
- every first-pass content item is tagged as exact, approximated, or placeholder
- this document remains consistent with all seven domain docs

