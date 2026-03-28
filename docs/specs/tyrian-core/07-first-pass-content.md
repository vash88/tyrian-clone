# First-Pass Content

## Purpose

This document is the implementation handoff for the first playable Full Game vertical slice. It enumerates the exact content set and tags each item by reference confidence.

Status labels:

- **Exact reference-derived**
- **Reference-informed approximation**
- **Placeholder pending extraction**

## Must-Have For First Playable Slice

- persistent campaign state
- one episode-like route with multiple missions
- one branch choice
- at least two shops
- at least three datacubes
- starter ship and at least three additional ship purchases
- multiple front and rear weapon choices
- generator and shield upgrade path
- sidekicks in both support and resource-pressure roles
- one miniboss and one slice-finale boss

## Defer To Later Pass

- full episode graph extraction
- exhaustive enemy roster
- exact prices for every original item
- exact sidekick names and every original option entry
- special weapons and non-core mode systems

## Ships

| Ship | Inclusion | Confidence |
| --- | --- | --- |
| `USP Talon` | Starter ship baseline | Exact reference-derived |
| `Gencore Phoenix` | First major all-rounder upgrade | Exact reference-derived |
| `Gencore Maelstrom` | Heavier durability choice | Exact reference-derived |
| `USP Fang` | Fast alternative | Exact reference-derived |

## Front Weapons

| Weapon | Inclusion | Confidence |
| --- | --- | --- |
| `Pulse-Cannon` | Starter front weapon | Exact reference-derived |
| `Multi-Cannon` | Early spread option | Exact reference-derived |
| `Laser` | Early precision option | Exact reference-derived |
| `Zica Laser` | Mid-tier precision upgrade | Exact reference-derived |
| `Vulcan Cannon` | High-cadence upgrade | Exact reference-derived |
| `Lightning Cannon` | Late-slice premium option | Exact reference-derived |

## Rear Weapons

| Weapon | Inclusion | Confidence |
| --- | --- | --- |
| `None` | Starter rear state | Exact reference-derived |
| `Starburst` | Early rear coverage choice | Reference-informed approximation |
| `Sonic Wave` | Alternate coverage choice | Reference-informed approximation |
| `Wild Ball` | Quirky route-specific choice | Reference-informed approximation |
| `Vulcan Cannon` | Heavy sustained rear option | Reference-informed approximation |

## Shields

| Shield | Inclusion | Confidence |
| --- | --- | --- |
| `Gencore High Energy Shield` | Starter shield | Exact reference-derived |
| `Advanced Integrity Field` | Budget upgrade | Exact reference-derived |
| `Gencore Low Energy Shield` | Alternate early shield | Exact reference-derived |
| `MicroCorp LXS Class A` | Recharge-focused mid-tier alternative | Exact reference-derived |
| `MicroCorp HXS Class A` | High-capacity late-slice option | Exact reference-derived |

## Generators

| Generator | Inclusion | Confidence |
| --- | --- | --- |
| `Standard MR-9` | Entry generator | Exact reference-derived |
| `Advanced MR-12` | Starter or early baseline generator | Exact reference-derived |
| `Gencore Custom MR-12` | Mid-tier sustain upgrade | Exact reference-derived |
| `Standard MicroFusion` | Route-dependent sustain option | Exact reference-derived |
| `Advanced MircoFusion` | Pre-boss sustain upgrade | Exact reference-derived |
| `Gravitron Pulse-Wave` | Top-end first-pass generator | Exact reference-derived |

## Sidekicks

| Sidekick | Inclusion | Confidence |
| --- | --- | --- |
| `None` | Empty slot baseline | Exact reference-derived |
| `Single Shot Option` | Early attached sidekick | Exact reference-derived |
| `Companion Ship Warfly` | Linked-fire follower | Exact reference-derived |
| `Charge Cannon` | Charge-up option | Exact reference-derived |
| `MicroBomb      Ammo 60` | Ammo-limited support option | Exact reference-derived |

## Enemy Roster

| Enemy | Inclusion | Confidence |
| --- | --- | --- |
| `Tyrian Scout` | Opening fodder target | Placeholder pending extraction |
| `Savara Diver` | Diagonal pathing enemy | Placeholder pending extraction |
| `Microsol Interceptor` | Formation enemy | Placeholder pending extraction |
| `Deliani Tower Turret` | Urban hazard / aimed-fire fixture | Reference-informed approximation |
| `Gyges Gate Drone` | Durable pre-boss enemy | Reference-informed approximation |
| `Zica Tunnel Spawn` | Exotic ambush threat | Reference-informed approximation |

## Bosses

| Boss | Inclusion | Confidence |
| --- | --- | --- |
| `Savara Customs Platform` | First miniboss | Placeholder pending extraction |
| `Gyges Gate Controller` | Slice finale boss | Reference-informed approximation |

## Levels

| Level | Inclusion | Confidence |
| --- | --- | --- |
| `tyrian-outskirts` | Opening mission | Reference-informed approximation |
| `savara-passage` | Early reward-rich mission | Reference-informed approximation |
| `deliani-run` | Tight branch mission | Reference-informed approximation |
| `savara-depths` | Alternate branch mission | Reference-informed approximation |
| `gyges-gate` | Pre-boss escalation | Reference-informed approximation |
| `gyges-boss` | Boss finale mission | Reference-informed approximation |

## Navigation Nodes

| Node | Inclusion | Confidence |
| --- | --- | --- |
| `tyrian-briefing` | Campaign start | Reference-informed approximation |
| `savara-port-shop` | First shop | Reference-informed approximation |
| `branch-savara-or-deliani` | Route choice | Placeholder pending extraction |
| `deliani-market-shop` | Branch-specific shop | Reference-informed approximation |
| `gyges-prep-shop` | Pre-boss shop | Reference-informed approximation |
| `episode-slice-end` | Slice wrap-up | Placeholder pending extraction |

## Datacubes

| Datacube | Inclusion | Confidence |
| --- | --- | --- |
| `cube-savara-trade-warning` | Early branch foreshadowing | Reference-informed approximation |
| `cube-deliani-refuge` | Deliani route context | Reference-informed approximation |
| `cube-gyges-lab-intel` | Boss and facility warning | Reference-informed approximation |

## Shop Availability By Progression Point

| Progression Point | Inventory Focus | Confidence |
| --- | --- | --- |
| `savara-port-shop` | Early front/rear choice, first generator and shield tradeoff | Reference-informed approximation |
| `deliani-market-shop` | Branch reward shop with stronger weapons and ships | Reference-informed approximation |
| `gyges-prep-shop` | Sustain and boss-prep purchases | Reference-informed approximation |

## Canonical Notes For Implementation

- Use exact original names whenever present in this document.
- Keep placeholder names localized to content tables and authored data, not hard-coded into system rules.
- Treat all placeholder or approximated entries as content-data debt, not license to reshape Tyrian's core systems.
- If later extraction contradicts a first-pass item label but not the system behavior, replace the label and preserve the surrounding gameplay role.
