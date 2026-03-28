# Shop, Economy, And Upgrades

## Scope

This document defines the persistent credit economy, shop rules, power upgrades, and first-pass inventory availability.

## Reference Basis

- `manual.doc` describes credits, shop menus, 11 power levels, ships, shields, generators, and sidekicks.
- `files.txt` states that episode scripts determine shop contents.
- `tyrian.hdt.txt` provides base item structures and costs for weapons, generators, shields, ships, and sidekicks.

## Economy Principles

Tyrian progression is driven by both combat pickups and deliberate spending.

The first-pass economy must preserve these pressures:

- buying a better weapon competes with upgrading its power
- better generators and shields are not optional luxury items
- ship purchases are major decisions, not automatic upgrades
- route choice can affect reward pacing and shop access

## Credits

Credits are the persistent campaign currency.

Sources:

- mission-end rewards
- in-level coin and gem pickups
- authored bounty drops
- conversion rewards for redundant pickups or maxed power-ups

Uses:

- buy ships
- buy front weapons
- buy rear weapons
- buy shields
- buy generators
- buy sidekicks
- buy front weapon power upgrades
- buy rear weapon power upgrades

## `ShopInventoryRule`

| Field | Meaning |
| --- | --- |
| `id` | Stable rule id |
| `nodeId` | Shop node that owns the rule |
| `itemType` | Ship, front weapon, rear weapon, shield, generator, sidekick, or power upgrade |
| `itemId` | Target item or target slot |
| `availabilityConditions` | Flags, world, branch, or prior purchase constraints |
| `basePrice` | Base shop price |
| `priceFormula` | Optional scaling formula |
| `replacementPolicy` | Whether buying replaces or adds inventory |
| `notes` | Special behavior |

## Purchase Flow

Canonical purchase behavior:

1. open the shop at a shop-capable node
2. inspect a category
3. compare owned and equipped item
4. confirm purchase
5. deduct credits immediately
6. apply item ownership and equip rules

## Power Upgrade Rules

Power upgrades for front and rear weapons are distinct from buying the weapon item itself.

Rules:

- each weapon has 11 power levels
- power upgrades are bought against the currently equipped weapon slot
- power cost should scale with weapon base cost and current level
- the shop must clearly expose current level and next level
- power can also be increased by mission pickups if the mission definition allows it

## First-Pass Pricing Policy

Exact original price extraction is not complete in this pass, so the first-pass slice uses this rule:

- preserve exact item names where known
- use exact costs only if later extracted directly from HDT or code
- otherwise use a consistent reference-informed pricing ladder

### Pricing Ladder

| Category | Pricing Rule | Status |
| --- | --- | --- |
| Ships | Large purchases spaced across major progression points | Reference-informed approximation |
| Front weapons | Mid-cost purchases that define build direction | Reference-informed approximation |
| Rear weapons | Slightly lower than major front purchases unless especially strong | Reference-informed approximation |
| Generators | Comparable to major weapon purchases due to sustain value | Reference-informed approximation |
| Shields | Mid-tier defensive investment | Reference-informed approximation |
| Sidekicks | Broad range based on behavior complexity | Reference-informed approximation |
| Weapon power upgrades | Scale with current level and equipped weapon cost | Reference-informed approximation |

## Inventory Availability

Shop inventory is scripted per node, not globally static.

The first pass uses these availability principles:

- `savara-port-shop` introduces a first real weapon, shield, and generator choice
- branch outcome can alter available inventory
- `gyges-gate` or the node before it should expose a meaningful sustain or boss-prep purchase window

## Ship Acquisition Rules

Ships are replacement purchases, not additive simultaneous loadout slots.

Rules:

- the player owns a current active ship
- buying a new ship replaces the active ship in `PlayerLoadout`
- previously purchased ships may remain re-equipable later if the implementation supports ownership persistence
- the first pass should support persistent ownership if feasible, because it better matches Full Game structure

## First-Pass Shop Tables

### `savara-port-shop`

| Category | Items | Status |
| --- | --- | --- |
| Front weapons | `Pulse-Cannon`, `Multi-Cannon`, `Laser` | Exact names, inventory timing approximated |
| Rear weapons | `None`, `Starburst`, `Sonic Wave` | Exact names, rear assignment approximated |
| Generators | `Standard MR-9`, `Advanced MR-12`, `Gencore Custom MR-12` | Exact names |
| Shields | `Gencore Low Energy Shield`, `Gencore High Energy Shield`, `Advanced Integrity Field` | Exact names |
| Sidekicks | `None`, `Single Shot Option` | Exact names, inventory timing approximated |
| Ships | `USP Talon`, `Gencore Phoenix` | Exact names, availability approximated |

### `deliani-market-shop`

| Category | Items | Status |
| --- | --- | --- |
| Front weapons | `Vulcan Cannon`, `Zica Laser` | Exact names, inventory timing approximated |
| Rear weapons | `Wild Ball`, `Vulcan Cannon` | Exact names, slot usage approximated |
| Generators | `Standard MicroFusion` | Exact name |
| Shields | `MicroCorp LXS Class A`, `MicroCorp LXS Class B` | Exact names, availability approximated |
| Sidekicks | `Companion Ship Warfly`, `Charge Cannon` | Exact names, behavior approximated |
| Ships | `Gencore Maelstrom`, `USP Fang` | Exact names, availability approximated |

### `gyges-prep-shop`

| Category | Items | Status |
| --- | --- | --- |
| Front weapons | `Lightning Cannon` | Exact name, availability approximated |
| Generators | `Advanced MircoFusion`, `Gravitron Pulse-Wave` | Exact names |
| Shields | `MicroCorp HXS Class A`, `MicroCorp HXS Class B` | Exact names, availability approximated |
| Sidekicks | `MicroBomb      Ammo 60` | Exact name, behavior approximated |

## Persistent Purchases Versus Mission Pickups

The implementation must distinguish:

- **persistent purchases** made in shops
- **mission pickups** earned during play

Persistent purchases survive across the campaign.

Mission pickups:

- can grant credits immediately or at mission end
- can increment weapon power
- can grant datacubes
- can restore combat resources

They should not bypass the shop's role as the main progression gate.
