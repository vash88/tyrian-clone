# Weapons, Shields, Generators, And Sidekicks

## Scope

This document defines the combat equipment systems that most strongly shape Tyrian's feel: weapon ports, power levels, rear modes, generator throughput, shield recharge, and sidekick behavior.

## Reference Basis

- `manual.doc` states:
  - front and rear weapons each have 11 power levels
  - some rear weapons have two configurations
  - generators determine firing speed and shield recharge speed
  - sidekicks can be continuous-fire, charge-up, or limited-ammo
- `tyrian.hdt.txt` decodes:
  - `weaponPort`
  - `powerSys`
  - `options`
  - `shields`
- `mainint.c` provides the new-game equipment baseline

## Weapon Port Model

Tyrian's player weapons are equipment entries bound to a port definition. The port definition references per-level pattern data and a base power-use value.

## `WeaponPortDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable item id |
| `name` | Original weapon name |
| `portType` | `front` or `rear` |
| `sourceStatus` | `exact`, `approximation`, or `placeholder` |
| `shopCost` | Base purchase cost |
| `powerUse` | Base energy drain per firing cycle |
| `supportedModes` | One or two modes |
| `powerLevels` | 11 authored power entries |
| `itemGraphicRef` | Shop icon or sprite reference |
| `notes` | Extraction caveats or behavior notes |

## `WeaponFireMode`

| Field | Meaning |
| --- | --- |
| `modeIndex` | Zero-based mode id |
| `label` | Optional display label |
| `shotPatternRef` | Underlying attack pattern |
| `targetingStyle` | Forward, spread, rear, angled, homing, or special |
| `cadence` | Effective fire cadence |
| `drainMultiplier` | Multiplier against base `powerUse` if needed |

## Power Levels

Weapons use 11 power levels. Power levels increase emitted damage, coverage, projectile count, or pattern strength according to the authored port data.

Rules:

- levels are integer ranks from 1 through 11
- power is tracked separately for front and rear weapons
- changing the equipped weapon does not imply keeping the old weapon's power on another item unless explicitly supported by the item system
- upgrade pricing scales from the equipped weapon's base cost

## Generator-Energy Model

The player has one shared energy pool driven by the equipped generator.

Rules:

- firing front, rear, and qualifying sidekick weapons consumes energy
- generator output restores energy over time
- shield recharge competes for the same throughput budget
- if energy is exhausted, weapon cadence drops or firing stalls until recovery
- shield recharge must not bypass generator limits

This shared-competition rule is canonical for the first implementation pass.

## `GeneratorDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable generator id |
| `name` | Original generator name |
| `sourceStatus` | `exact`, `approximation`, or `placeholder` |
| `throughput` | Effective energy restored per second |
| `shopCost` | Base purchase cost |
| `itemGraphicRef` | Shop icon |
| `notes` | Any implementation notes |

### Canonical Generator Roster For First Pass

These names are exact from `tyrian.hdt` strings and the decoded structure.

| Generator | Intended Role | Status |
| --- | --- | --- |
| `Standard MR-9` | Entry-level generator | Exact name, throughput approximated |
| `Advanced MR-12` | Strong early upgrade and OpenTyrian starter baseline | Exact name, starter usage exact, throughput approximated |
| `Gencore Custom MR-12` | Efficient mid-tier upgrade | Exact name, throughput approximated |
| `Standard MicroFusion` | Higher sustain tier | Exact name, throughput approximated |
| `Advanced MircoFusion` | Premium sustain generator | Exact name and spelling from `tyrian.hdt`, throughput approximated |
| `Gravitron Pulse-Wave` | Top-end first-pass generator ceiling | Exact name, throughput approximated |

## Shield Model

Shields are not just hit points. They are a rechargeable defensive buffer constrained by generator output.

Rules:

- shields absorb damage before armor
- shields do not recharge while a post-hit delay is active
- once the delay expires, recharge begins only if generator energy is available
- shield recharge rate is capped by both shield profile and generator throughput
- firing high-drain weapons reduces recharge opportunity

## `ShieldDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable shield id |
| `name` | Original shield name |
| `sourceStatus` | `exact`, `approximation`, or `placeholder` |
| `capacity` | Max shield value |
| `generatorDemand` | Generator pressure needed for efficient recharge |
| `rechargeDelay` | Delay after taking damage |
| `rechargeRate` | Max recharge rate before generator competition |
| `shopCost` | Base purchase cost |
| `notes` | Any caveats |

### First-Pass Shield Roster

The local `tyrian.hdt` strings provide several exact shield names, so the first pass should use those original labels rather than invented stand-ins.

| Shield | Intended Role | Status |
| --- | --- | --- |
| `Structural Integrity Field` | Cheap low-capacity baseline shield | Exact name, stats approximated |
| `Advanced Integrity Field` | Early upgrade path | Exact name, stats approximated |
| `Gencore Low Energy Shield` | Early energy-light option | Exact name, stats approximated |
| `Gencore High Energy Shield` | Starter baseline shield | Exact name from OpenTyrian init, stats approximated |
| `MicroCorp LXS Class A` | Mid-tier shield line entry | Exact name, stats approximated |
| `MicroCorp HXS Class A` | High-capacity late-slice option | Exact name, stats approximated |

## Sidekick Model

Sidekicks are separate left and right support slots. In `tyrian.hdt`, each `options` entry carries movement type, animation behavior, weapon binding, and ammo.

## `SidekickDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable sidekick id |
| `name` | Original sidekick name |
| `sourceStatus` | `exact`, `approximation`, or `placeholder` |
| `mountBehavior` | Attached, follower, launchable, or orbiting |
| `fireBehavior` | Linked fire, charge-up, independent fire, or ammo-limited |
| `ammoCapacity` | Ammo if limited, otherwise null |
| `chargeStages` | Number of charge steps if applicable |
| `weaponBinding` | Weapon port or pattern reference used by the sidekick |
| `shopCost` | Purchase price |
| `notes` | Special handling |

### First-Pass Sidekick Behavior Classes

The first pass should include one example of each meaningful behavior class:

- attached continuous-fire sidekick
- follower continuous-fire sidekick
- charge-up sidekick
- ammo-limited sidekick

### First-Pass Sidekick Roster

The local `tyrian.hdt` strings provide several exact sidekick or option names. The first pass should prioritize these before adding any placeholder companion labels.

| Sidekick | Role | Status |
| --- | --- | --- |
| `None` | Empty slot | Exact concept |
| `Single Shot Option` | Entry-level attached sidekick | Exact name, behavior approximated |
| `Charge Cannon` | Charge-up support weapon | Exact name, behavior approximated |
| `Companion Ship Warfly` | Follower sidekick with linked fire | Exact name, behavior approximated |
| `MicroBomb      Ammo 60` | Ammo-limited burst support | Exact name, behavior approximated |

## First-Pass Weapon Tables

The first pass uses exact Tyrian names where the local reference strings are strong. Port assignment is only marked exact where the local reference or original behavior is sufficiently clear.

### Front Weapons

| Weapon | Role | Status |
| --- | --- | --- |
| `Pulse-Cannon` | Starter front weapon | Exact name and starter usage from OpenTyrian init |
| `Multi-Cannon` | Wider basic spread option | Exact name, slot assignment approximated |
| `Laser` | Straight precision weapon | Exact name, slot assignment approximated |
| `Zica Laser` | Stronger precision beam option | Exact name, slot assignment approximated |
| `Vulcan Cannon` | High cadence kinetic weapon | Exact name, slot assignment approximated |
| `Lightning Cannon` | Chaining or piercing-flavored upgrade path | Exact name, behavior approximated |

### Rear Weapons

| Weapon | Role | Status |
| --- | --- | --- |
| `None` | Empty rear slot baseline | Exact concept |
| `Starburst` | Rear or multi-angle coverage | Exact name, rear assignment approximated |
| `Sonic Wave` | Area-oriented rear coverage | Exact name, rear assignment approximated |
| `Wild Ball` | Unusual coverage / ricochet-flavored option | Exact name, rear assignment approximated |
| `Vulcan Cannon` | Rear baseline in some loadouts | Exact name, rear usage exact in OpenTyrian second-player init, 1P use approximated |

## System Rules Summary

The first pass must make these tradeoffs visible:

- stronger weapons drain energy faster
- better generators allow sustained offense and faster shield recovery
- shield recovery meaningfully competes with continued firing
- sidekicks can increase damage pressure but worsen sustain if they draw from shared throughput
- rear-mode switching changes tactical coverage, not just flavor
