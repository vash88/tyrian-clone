# Enemies, Bosses, And Encounters

## Scope

This document defines the enemy taxonomy, encounter grammar, and first-pass roster needed for near-parity Tyrian combat.

## Reference Basis

- `tyrian.hdt.txt` decodes enemy records and confirms a large authored enemy set for episodes 1-3.
- `manual.doc` establishes world tone and environment style that should shape encounter composition.
- `rewrite-prototype` provides a minimal current baseline with fodder units, pathing enemies, and one boss.

## Enemy Taxonomy

The first-pass system must support the following canonical enemy roles.

### Fodder Enemies

Low-durability targets that establish lane pressure, pickup flow, and weapon feel.

Requirements:

- simple pathing
- low armor
- low-value bullets or contact threat
- frequent pickup or score reward participation

### Formation Enemies

Groups that enter in authored patterns and test spread coverage and route discipline.

Requirements:

- shared spawn event or formation script
- synchronized or staggered firing
- positional value for wide front weapons

### Aimed-Fire Enemies

Enemies whose bullets challenge the player to dodge, reposition, or temporarily stop firing to recover shields.

Requirements:

- aimed, semi-aimed, or delayed aimed shots
- readable wind-up or cadence
- stronger synergy with corridor stages

### Pathing Or Diving Enemies

Enemies that sweep, arc, or dive across the screen to break static positioning.

Requirements:

- authored spline or waypoint pattern
- contact danger
- ability to overlap other wave pressure

### Scripted Hazards

Non-standard threats tied to the level environment.

Examples for first pass:

- tower lanes in Deliani-style missions
- tunnel or gate structures in Gyges-style missions
- environmental contact threats

### Minibosses And Bosses

High-durability authored set pieces with gated progression and phase logic.

Requirements:

- named phase structure
- mixed bullet and positional pressure
- explicit completion conditions
- reward payload larger than normal enemies

## `EnemyDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable enemy id |
| `name` | Authored display or designer-facing name |
| `sourceStatus` | `exact`, `approximation`, or `placeholder` |
| `taxonomy` | Fodder, formation, aimed-fire, pathing, hazard, miniboss, or boss |
| `armor` | Base durability |
| `collisionDamage` | Contact damage |
| `movementScript` | Path or behavior profile |
| `fireProfiles` | One or more shot profiles |
| `dropTable` | Pickup or credit reward outcomes |
| `scoreValue` | Reward contribution |
| `deathBehavior` | Explosion, spawn-on-death, script trigger, or none |
| `notes` | Special constraints or weak points |

## `BossPhaseDefinition`

| Field | Meaning |
| --- | --- |
| `id` | Stable phase id |
| `bossId` | Owning boss |
| `phaseIndex` | Sequence order |
| `enterCondition` | Health threshold or script event |
| `movementPattern` | Phase-specific movement logic |
| `attackSet` | Active projectile or spawn attacks |
| `weakPointRules` | Any targetability restrictions |
| `exitCondition` | Threshold or event that ends the phase |
| `rewardTrigger` | Reward or script payload fired at phase end |

## Encounter Grammar

Tyrian encounters are authored compositions, not random spawns.

Each encounter should combine:

- lane pressure
- aimed pressure
- movement pressure
- pickup opportunity
- a reason for weapon and sidekick choice to matter

### Encounter Construction Rules

- open with readable fodder or formation targets
- mix in aimed fire to punish autopilot lane camping
- add at least one pickup-bearing enemy or scripted reward window
- use tougher targets to force front-vs-rear and sustain decisions
- reserve bosses or minibosses for authored escalation moments

### Drop Logic

Every enemy category does not need to drop power items. Use authored drop tables.

Drop classes:

- none
- credits only
- common pickup pool
- authored guaranteed reward
- datacube or mission key item

### Destruction Behavior

At minimum, the system must support:

- standard explosion and removal
- delayed death script trigger
- spawn children on death
- reward drop on death

## Boss Design Rules For First Pass

A first-pass boss must:

- occupy a defined portion of the screen
- pressure both movement and energy management
- force the player to choose when to commit offense while shields are healthy
- have at least 2 phases
- gate mission completion

The boss should not be a pure bullet sponge. It must have pattern changes or positional shifts that alter the fight.

## First-Pass Enemy Roster

The first-pass roster intentionally mixes exact names only where the local reference set supports them. Most first-pass enemy names remain designer-facing placeholders until a dedicated enemy extraction pass is completed.

| Enemy | Role | Status |
| --- | --- | --- |
| `Tyrian Scout` | Fodder fly-in target in opening missions | Placeholder pending extraction |
| `Savara Diver` | Pathing enemy that sweeps diagonally | Placeholder pending extraction |
| `Deliani Tower Turret` | Scripted hazard / aimed-fire fixture | Reference-informed approximation |
| `Microsol Interceptor` | Formation enemy for mid-mission pressure | Placeholder pending extraction |
| `Gyges Gate Drone` | Tough aimed-fire enemy before boss | Reference-informed approximation |
| `Zica Tunnel Spawn` | Exotic movement or ambush target in Gyges route | Exact species reference, enemy details approximated |

## First-Pass Boss Roster

| Boss | Mission | Role | Status |
| --- | --- | --- | --- |
| `Savara Customs Platform` | `savara-passage` or alternate route | First miniboss and sustain check | Placeholder pending extraction |
| `Gyges Gate Controller` | `gyges-boss` | Slice finale boss with 2-3 phases | Reference-informed approximation |

## Boss Phase Template For `Gyges Gate Controller`

| Phase | Behavior | Purpose | Status |
| --- | --- | --- | --- |
| `phase-1-lane-control` | Sweeping aimed shots plus summon drones | Teach safe-lane repositioning | Reference-informed approximation |
| `phase-2-pressure-window` | Faster volleys and exposed weak window | Reward aggression while shield is up | Reference-informed approximation |
| `phase-3-collapse` | Hazard overlap and desperate fire pattern | End-fight climax | Placeholder pending tuning |
