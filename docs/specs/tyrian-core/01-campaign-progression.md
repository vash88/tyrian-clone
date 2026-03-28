# Campaign Progression

## Scope

This document defines the canonical 1-player Full Game progression model and the first-pass campaign slice.

It covers:

- episode and node structure
- navigation choices
- mission completion and destruction outcomes
- shop access
- datacube flow
- difficulty as gameplay tuning

It does not define frontend menu UX.

## Reference Basis

- `references/tyrian21/manual.doc` describes Full Game navigation, datacubes, and planetary progression.
- `references/opentyrian-master/doc/files.txt` states that `levels?.dat` controls episode flow including shop contents, planets, datacubes, text intermissions, and levels.
- `references/opentyrian-master/src/mainint.c` provides the new-game loadout baseline.

## Canonical Full Game Structure

Tyrian Full Game is a scripted campaign graph, not a linear arcade ladder.

The campaign is composed of:

- episodes
- authored navigation nodes within an episode
- mission nodes
- non-mission nodes such as shops, datacubes, and text intermissions
- branch rules that unlock or redirect later nodes

Each node resolves into one of these canonical node types:

- `mission`
- `shop`
- `datacube`
- `textIntermission`
- `branch`
- `episodeTransition`
- `campaignEnd`

## First-Pass Campaign Objective

The first pass is a vertical slice of the full-game structure, not the full original campaign.

The slice must demonstrate:

- more than one mission
- at least one shop stop
- at least one datacube reward
- at least one branch choice
- at least one boss gate
- persistent credits and equipment across missions

## First-Pass Authored Slice

The first-pass campaign slice is an Episode 1-style route centered on the early sector worlds described in the manual.

### Node Sequence

1. `tyrian-briefing`
2. `tyrian-outskirts`
3. `savara-port-shop`
4. `savara-passage`
5. `branch-savara-or-deliani`
6. `deliani-run` -> `deliani-market-shop` or `savara-depths`
7. `gyges-prep-shop`
8. `gyges-gate`
9. `gyges-boss`
10. `episode-slice-end`

### World Framing

The slice uses the manual's early-world framing:

- **Tyrian** as the starting world under Microsol pressure
- **Savara** as the free world and trade location
- **Deliani** as the dense urban Gencore refuge
- **Gyges** as a Microsol stronghold and boss escalation point

These are exact world names from the manual. The exact original level list and route order are not fully extracted in this pass, so the first-pass mission arrangement is **reference-informed approximation**.

## `CampaignState`

`CampaignState` is the persistent model for the Full Game run.

| Field | Meaning |
| --- | --- |
| `campaignId` | Identifier for the active campaign ruleset |
| `episodeId` | Current episode or episode-like authored slice |
| `currentNodeId` | Current graph node |
| `visitedNodeIds` | Nodes already resolved |
| `completedMissionIds` | Mission nodes cleared |
| `failedMissionIds` | Mission nodes failed at least once |
| `unlockedNodeIds` | Nodes available for selection |
| `credits` | Persistent spendable currency |
| `difficulty` | Selected gameplay difficulty |
| `loadout` | Current persistent `PlayerLoadout` |
| `ownedItemIds` | Purchased or permanently unlocked inventory |
| `datacubeIds` | Obtained datacubes |
| `campaignFlags` | Script flags set by missions or datacubes |
| `continuePolicy` | Rule set for destruction/retry handling |

## `MissionState`

`MissionState` is created when the player enters a mission node.

| Field | Meaning |
| --- | --- |
| `missionId` | Current mission definition |
| `sourceNodeId` | Campaign node that launched the mission |
| `elapsedTime` | Mission timer |
| `scrollProgress` | Normalized or authored progress through the stage |
| `playerState` | Runtime combat state |
| `spawnedEnemies` | Active enemies and hazards |
| `activePickups` | Active pickups in the field |
| `bossState` | Active boss phase state when applicable |
| `rewardBuffer` | Credits, datacubes, or drops earned this mission before commit |
| `outcome` | `inProgress`, `cleared`, `destroyed`, or `aborted` |

## Node Resolution Rules

### Mission Clear

On mission clear:

- commit mission rewards to `CampaignState`
- mark the mission node completed
- apply any datacubes granted by mission events
- set script flags authored by the mission definition
- unlock the next node or branch options
- move to the post-mission node authored by the graph

### Mission Destruction

The first-pass implementation uses a conservative Full Game failure model:

- persistent shop purchases remain owned
- mission-local transient pickups are lost unless explicitly banked before failure
- the campaign returns to the most recent safe non-mission node for retry
- the failed mission node remains available

This is **reference-informed approximation** shaped to preserve Tyrian's campaign stakes while avoiding unsupported continue-menu detail in this pass.

### Shop Node

A shop node resolves without combat. It exposes a `ShopInventoryRule` set bound to the node and returns the player to the next authored node once they leave.

### Datacube Node

A datacube node reveals text or intel, sets associated campaign flags, and unlocks its next node.

### Branch Node

A branch node exposes two or more route choices. Each option references unlock conditions and next-node outcomes.

## Difficulty

Tyrian exposes multiple named difficulties in OpenTyrian, including Easy, Normal, Hard, and Impossible, with higher hidden tiers beyond that.

For this spec package:

- Full Game first-pass UI only needs `Easy`, `Normal`, `Hard`, and `Impossible`.
- Difficulty is a gameplay modifier, not a separate content mode.
- Difficulty affects:
  - enemy health multiplier
  - enemy bullet density or cadence
  - pickup generosity only if explicitly authored
  - score or reward tuning only if needed later

The campaign graph itself does not change by difficulty in the first pass.

## Vertical Slice Definition

For campaign purposes, "vertical slice" means:

- one episode-like authored route
- multiple worlds represented
- navigation, shop, datacube, mission, and boss nodes all exercised
- persistence across several missions
- enough content to validate the whole Full Game loop

It does **not** mean a single stage with a fake shop attached afterward.

## First-Pass Node Table

| Node Id | Type | Purpose | Status |
| --- | --- | --- | --- |
| `tyrian-briefing` | `textIntermission` | Campaign start and route framing | Reference-informed approximation |
| `tyrian-outskirts` | `mission` | Opening combat mission and loadout validation | Reference-informed approximation |
| `savara-port-shop` | `shop` | First equipment and power upgrade stop | Exact world name, node content approximated |
| `savara-passage` | `mission` | Pickup-rich route that teaches power growth | Reference-informed approximation |
| `branch-savara-or-deliani` | `branch` | First route decision | Placeholder pending exact script extraction |
| `deliani-run` | `mission` | Dense city-style mission with tighter lanes | Exact world name, mission approximated |
| `deliani-market-shop` | `shop` | Branch reward shop after the Deliani route | Reference-informed approximation |
| `savara-depths` | `mission` | Alternate route with broader lanes and more drops | Reference-informed approximation |
| `gyges-prep-shop` | `shop` | Final sustain and boss-prep inventory stop | Reference-informed approximation |
| `gyges-gate` | `mission` | Escalation mission before boss | Exact world name, mission approximated |
| `gyges-boss` | `mission` | Boss-gated finale for the slice | Reference-informed approximation |
| `episode-slice-end` | `episodeTransition` | End-of-slice summary and next-episode placeholder | Placeholder pending later content extraction |
