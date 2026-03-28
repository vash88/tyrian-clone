# Levels, Navigation, And Datacubes

## Scope

This document defines level composition, navigation graph rules, datacube handling, and the concrete first-pass authored slice.

## Reference Basis

- `manual.doc` describes world identities, datacubes, and navigation choices.
- `files.txt` says `levels?.dat` controls planets, shop contents, datacubes, text intermissions, and levels.
- `tyrian?.lvl` data ownership in `files.txt` confirms level tilemaps and level scripts are authored content.

## Level Composition Model

A `LevelDefinition` is an authored scrolling mission composed of timeline events and spatial constraints.

## `LevelDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable level id |
| `name` | Authored level name |
| `worldId` | Associated planet or region |
| `scrollModel` | Vertical scrolling parameters and camera pacing |
| `durationTarget` | Intended mission length or event span |
| `backgroundTheme` | Environment, tileset, and hazard family |
| `events` | Ordered `LevelEvent` list |
| `bossId` | Optional boss at the end of the level |
| `completionRule` | How the level ends |
| `rewardProfile` | Credits, drops, datacube opportunities |
| `nextNodeRules` | Default post-clear routing |

## `LevelEvent`

| Field | Meaning |
| --- | --- |
| `id` | Stable event id |
| `trigger` | Time, scroll position, prior event, or boss state |
| `eventType` | Spawn wave, start hazard, grant pickup, datacube reveal, dialogue, or script flag |
| `payload` | Event-specific data |
| `notes` | Special handling |

## `WaveDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable wave id |
| `enemyRefs` | Enemies included in the wave |
| `entryPattern` | Formation, lane, dive, swarm, turret bank, or boss support |
| `spawnOffsets` | Relative spawn timing and positions |
| `dropOverride` | Optional drop override |
| `difficultyModifiers` | Optional scaling adjustments |

## Composition Rules

Every first-pass mission should contain:

- an opening calibration wave
- at least one pressure spike
- at least one reward opportunity
- at least one authored environment identity
- a clear completion gate

Boss levels additionally require:

- pre-boss escalation
- boss intro beat
- phase changes
- post-boss resolve trigger

## Navigation Graph

`NavNodeDefinition` describes the campaign route.

| Field | Meaning |
| --- | --- |
| `id` | Stable node id |
| `nodeType` | Mission, shop, branch, datacube, intermission, episode transition, or end |
| `title` | Player-facing label |
| `worldId` | Associated world, if any |
| `entryConditions` | Flags or completion requirements |
| `outputs` | One or more next-node references |
| `payloadRef` | Level, shop, datacube, or text asset |
| `notes` | Routing caveats |

### Navigation Rules

- branch choice must be explicit when multiple valid outputs exist
- shops and datacube scenes can sit between combat nodes
- a mission node can unlock more than one next node
- a node can be revisited only if explicitly authored

## Datacube Model

Datacubes are gameplay-relevant campaign intel. They are not disposable flavor popups.

`DatacubeDefinition` fields:

| Field | Meaning |
| --- | --- |
| `id` | Stable datacube id |
| `title` | Player-facing title |
| `textRef` | Body text or localization key |
| `sourceNodeId` | Where it is granted or revealed |
| `unlockEffects` | Flags, route reveals, or shop inventory reveals |
| `status` | `exact`, `approximation`, or `placeholder` |

### Datacube Usage In First Pass

The first pass should use datacubes for at least two purposes:

- narrative framing of the route and the Microsol/Gencore conflict
- functional hinting about upcoming branch or boss threats

## First-Pass Level Slice

### `tyrian-outskirts`

- World: `Tyrian`
- Role: opening mission
- Theme: open lanes, moderate fodder density, simple aimed fire
- Purpose: validate starter loadout, credit pickups, and front weapon feel
- Status: Reference-informed approximation

### `savara-passage`

- World: `Savara`
- Role: second mission and pickup-rich route
- Theme: wider spaces, more trade-route traffic, higher pickup generosity
- Purpose: teach reward routing and encourage first major shop decisions
- Status: Reference-informed approximation

### `deliani-run`

- World: `Deliani`
- Role: branch mission
- Theme: tight spaces, tower lanes, more aimed pressure
- Purpose: validate movement precision and rear weapon value
- Status: Exact world identity, level approximated

### `savara-depths`

- World: `Savara`
- Role: alternate branch mission
- Theme: more open movement, different reward cadence
- Purpose: create a meaningful route choice against Deliani's denser challenge
- Status: Reference-informed approximation

### `gyges-gate`

- World: `Gyges`
- Role: pre-boss escalation
- Theme: fortified structures, tunnel or gate-like lane constraints
- Purpose: deplete careless players before the boss and test sustain
- Status: Exact world identity, level approximated

### `gyges-boss`

- World: `Gyges`
- Role: slice-finale boss mission
- Theme: Microsol facility centerpiece and phase-based boss fight
- Purpose: prove boss, generator, and shield tradeoff loop
- Status: Reference-informed approximation

## First-Pass Branch Definition

The first pass includes one meaningful branch:

- after `savara-passage`, choose `deliani-run` or `savara-depths`

Branch intent:

- `deliani-run` offers higher pressure, tighter lanes, and stronger shop unlocks
- `savara-depths` offers safer movement and more pickup opportunities
- both routes reconverge at `gyges-prep-shop` before `gyges-gate`

This branch is a **placeholder pending exact script extraction**, but it is required for the first slice because it exercises the Full Game navigation model.

## First-Pass Datacubes

| Datacube | Source | Function | Status |
| --- | --- | --- | --- |
| `cube-savara-trade-warning` | `savara-passage` | Warns about branch consequences and hidden Microsol activity | Reference-informed approximation |
| `cube-deliani-refuge` | `deliani-run` | Explains Gencore refuge context and hints at urban hazards | Exact world context, cube content approximated |
| `cube-gyges-lab-intel` | `gyges-gate` | Foreshadows the boss and Zica/Microsol threat | Exact world context, cube content approximated |
