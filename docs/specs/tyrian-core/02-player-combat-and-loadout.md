# Player Combat And Loadout

## Scope

This document defines the player's combat model, hit model, loadout structure, pickups, and first-pass HUD requirements.

## Player Vehicle Model

The player always controls one active ship in the mission. The ship's equipped loadout is persistent across campaign progression until changed in a shop or script event.

Core runtime layers:

- movement and collision body
- armor
- shield
- shared generator energy
- front weapon port
- rear weapon port
- left sidekick
- right sidekick

## Movement Model

The first-pass implementation uses a Tyrian-style free-movement ship constrained to the visible playfield.

Movement requirements:

- immediate directional response
- sub-pixel or floating-point movement internally
- authored camera-safe bounds that prevent hiding under UI overlays
- no inertia-heavy drift
- support for dense dodging in narrow lanes, especially in Deliani-style stages

Ship movement speed comes primarily from the equipped ship profile.

## Hit Model

Damage resolves in this order:

1. shield absorbs damage if shield value is above zero
2. remaining damage spills into armor
3. destruction occurs when armor reaches zero

Rules:

- contact damage from enemies and hazards is valid
- enemy shots can be destructible or indestructible per attack definition
- shields recharge only after a delay and only when generator throughput is available
- armor does not passively regenerate

## Destruction Flow

On destruction:

- the mission ends immediately unless a scripted exception is authored
- temporary in-level pickups not yet committed to campaign state are lost
- persistent purchased equipment remains owned
- control returns to campaign failure resolution defined in `01-campaign-progression.md`

## `PlayerLoadout`

`PlayerLoadout` is the persistent equipment model used between shop, campaign, and mission systems.

| Field | Meaning |
| --- | --- |
| `shipId` | Equipped ship |
| `frontWeaponId` | Equipped front weapon port item |
| `frontPowerLevel` | Purchased or current front weapon level from 1 to 11 |
| `rearWeaponId` | Equipped rear weapon port item or none |
| `rearPowerLevel` | Purchased or current rear weapon level from 1 to 11 |
| `rearModeIndex` | Active rear weapon mode for multi-mode rear guns |
| `shieldId` | Equipped shield |
| `generatorId` | Equipped generator |
| `leftSidekickId` | Equipped left sidekick or none |
| `rightSidekickId` | Equipped right sidekick or none |
| `specialId` | Reserved for later parity; deferred in first pass |

## `ShipDefinition`

`ShipDefinition` describes a ship as an equipment item.

| Field | Meaning |
| --- | --- |
| `id` | Stable identifier |
| `name` | Original Tyrian ship name |
| `sourceStatus` | `exact`, `approximation`, or `placeholder` |
| `armorCapacity` | Max armor |
| `speedBand` | Relative movement speed and responsiveness |
| `shopCost` | Purchase price if the ship is sold |
| `unlockRule` | Campaign/shop availability |
| `notes` | Reference ambiguity or special handling |

## Starter Loadout Baseline

OpenTyrian's `JE_initPlayerData` is used as the operational baseline for the first pass:

- ship: `USP Talon`
- front weapon: `Pulse-Cannon`
- rear weapon: `None`
- shield: `Gencore High Energy Shield`
- generator: `Advanced MR-12`
- sidekicks: `None`

This is exact to the local OpenTyrian source, while the original manual's `USP Perren Scout` mention remains an open ambiguity.

## Pickup Model

`PickupDefinition` describes in-level collectables.

| Field | Meaning |
| --- | --- |
| `id` | Stable pickup identifier |
| `kind` | Credits, datacube, front power, rear power, armor repair, shield restore, sidekick ammo, or scripted item |
| `presentation` | Sprite or effect identity |
| `applyMode` | Immediate, banked on mission end, or script-triggered |
| `value` | Numeric payload or content id |
| `persistOnFailure` | Whether the reward survives mission destruction |
| `notes` | Special rules |

### Canonical Pickup Categories

- **Credits**: coins, gems, and direct currency pickups
- **Datacubes**: persistent intel pickups
- **Front power pod**: increments front weapon power
- **Rear power pod**: increments rear weapon power
- **Armor repair**: restores armor immediately
- **Shield restore**: optional pickup type for authored missions
- **Sidekick ammo**: only for ammo-limited sidekicks

### Power-Up Rules

The manual establishes 11 power levels for front and rear weapons. OpenTyrian's player code also shows purple-ball thresholds used for power progression in related modes.

For Full Game first pass:

- shop purchases are the primary deterministic power progression
- mission pickups can temporarily or permanently increase front or rear power based on authored mission rules
- front and rear power never exceed 11
- if a power-up is collected while already maxed, it should convert into credits or another authored fallback reward

## Sidekick Runtime Behavior

Sidekicks operate as independent support systems tied to the player's loadout.

Rules:

- unlimited-ammo sidekicks fire in relation to normal firing
- charge-up sidekicks have their own timing rules
- ammo-limited sidekicks consume their own resource pool
- left and right sidekicks can be different items
- sidekick loss on player death is not introduced unless later reference extraction supports it

## First-Pass Ship Roster Approach

The first pass includes a small set of ships sufficient to validate shop and movement tradeoffs.

| Ship | Role | Status |
| --- | --- | --- |
| `USP Talon` | Starter light fighter baseline | Exact name, baseline exact from OpenTyrian init |
| `Gencore Phoenix` | Upgraded all-rounder | Exact name, stats approximated |
| `Gencore Maelstrom` | Heavier durability option | Exact name, stats approximated |
| `USP Fang` | Fast alternative light fighter | Exact name, stats approximated |

## First-Pass HUD Requirements

The first-pass gameplay HUD only needs to expose gameplay state the player must act on.

Required fields:

- armor current and max
- shield current and max
- generator energy current and max
- front weapon and power level
- rear weapon, power level, and current mode if multi-mode
- left and right sidekick states
- credits
- mission time or scroll progress
- boss health or phase state when applicable

## HUD Priority

Combat-critical information should always be more visible than campaign flavor information. Datacube text and campaign narration belong outside the active combat HUD.
