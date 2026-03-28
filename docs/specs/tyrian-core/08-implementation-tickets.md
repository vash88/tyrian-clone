# Tyrian Core Implementation Tickets

## Purpose

This document turns the Tyrian core spec package into an implementation backlog for the current native codebase.

Primary target code areas:

- `TyrianClone/TyrianClone/App`
- `TyrianClone/TyrianClone/Features`
- `TyrianClone/TyrianClone/GameCore`
- `TyrianClone/TyrianClone/Rendering`
- `TyrianClone/TyrianClone/Shared`

## Ticketing Rules

- `P0` means foundational and blocks multiple downstream tickets.
- `P1` means required for the first playable Full Game slice.
- `P2` means useful for parity but can land after the first slice is playable.
- Every ticket should preserve the separation between `GameCore`, SwiftUI `Features`, and `Rendering`.
- No ticket should introduce networking, settings UX, or non-gameplay platform work.

## Milestones

### Milestone A: Core Architecture Reset

Replace the single-stage prototype data model with Tyrian-oriented campaign, mission, and item definitions.

### Milestone B: Combat Systems

Implement the shared generator, weapon, shield, and sidekick rules so combat behaves like Tyrian rather than the current prototype.

### Milestone C: Campaign And Shops

Drive progression through authored nodes, datacubes, shops, and route choices instead of a single sortie loop.

### Milestone D: First Playable Slice

Ship the first complete route:

- Tyrian start
- Savara shop
- branch
- Deliani or Savara alternate route
- Gyges prep
- Gyges boss

### Milestone E: Verification

Add tests and parity checks for systems that are easy to regress.

## Tickets

### TYC-001: Replace Prototype Domain Model With Canonical Tyrian Types

- Priority: `P0`
- Depends on: none
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Domain/GameTypes.swift`
  - `TyrianClone/TyrianClone/GameCore/Domain/RunState.swift`
  - new files under `TyrianClone/TyrianClone/GameCore/Domain`
- Goal:
  - replace prototype-only types like `StageDefinition` and `EnemyArchetype` with canonical types from the spec, including `CampaignState`, `MissionState`, `PlayerLoadout`, `ShipDefinition`, `WeaponPortDefinition`, `ShieldDefinition`, `GeneratorDefinition`, `SidekickDefinition`, `EnemyDefinition`, `BossPhaseDefinition`, `LevelDefinition`, `LevelEvent`, `NavNodeDefinition`, `DatacubeDefinition`, `ShopInventoryRule`, and `PickupDefinition`
- Acceptance criteria:
  - the old single-stage terminology is no longer the primary domain model
  - the new domain types map directly to the spec docs
  - the game core can represent campaign state, mission state, and shop state without adapter hacks

### TYC-002: Build A Tyrian Catalog Layer

- Priority: `P0`
- Depends on: `TYC-001`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Data/PrototypeData.swift`
  - new files under `TyrianClone/TyrianClone/GameCore/Data`
- Goal:
  - replace `PrototypeData` with a Tyrian-oriented catalog split by ships, front weapons, rear weapons, shields, generators, sidekicks, enemies, levels, datacubes, and navigation nodes
- Acceptance criteria:
  - a single `TyrianCatalog` can answer lookups for all first-pass content
  - exact names from the spec are preserved in the data layer
  - content confidence notes remain in authoring comments or adjacent docs, not runtime UI

### TYC-003: Introduce A Campaign Graph Runner

- Priority: `P0`
- Depends on: `TYC-001`, `TYC-002`
- Target areas:
  - `TyrianClone/TyrianClone/App/AppModel.swift`
  - new files under `TyrianClone/TyrianClone/GameCore/Simulation` or `GameCore/Campaign`
- Goal:
  - replace the current `briefing -> stage -> shop/destroyed` flow with a node-driven Full Game campaign graph
- Acceptance criteria:
  - `AppModel` can advance through intermission, mission, shop, branch, and episode-transition nodes
  - mission clear and mission destruction both resolve back into campaign state
  - branch selection is represented as data, not hard-coded screen flow

### TYC-004: Refactor Screen Flow Around Campaign Nodes

- Priority: `P1`
- Depends on: `TYC-003`
- Target areas:
  - `TyrianClone/TyrianClone/App/AppScreen.swift`
  - `TyrianClone/TyrianClone/Features/MainScreen.swift`
  - `TyrianClone/TyrianClone/Features/BriefingView.swift`
  - `TyrianClone/TyrianClone/Features/ShopView.swift`
  - `TyrianClone/TyrianClone/Features/DestroyedView.swift`
- Goal:
  - make the SwiftUI shell reflect campaign node types instead of prototype screens
- Acceptance criteria:
  - the UI can show intermission, datacube, shop, branch, mission, and failure states
  - the sheet content comes from current node payload, not a single hard-coded flow
  - there is no assumption that every mission clear goes straight to the same shop

### TYC-005: Implement Shared Generator, Energy, And Shield Recharge Rules

- Priority: `P0`
- Depends on: `TYC-001`, `TYC-002`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - `TyrianClone/TyrianClone/GameCore/Domain/RunState.swift`
- Goal:
  - make weapon fire, shield recharge, and generator throughput compete through one shared energy model
- Acceptance criteria:
  - the generator sets effective recharge throughput
  - firing reduces available recharge throughput
  - shields respect a post-hit delay and cannot recharge for free
  - the runtime model supports different generator and shield tiers from the catalog

### TYC-006: Implement 11-Level Front And Rear Weapon Power

- Priority: `P0`
- Depends on: `TYC-001`, `TYC-002`, `TYC-005`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - `TyrianClone/TyrianClone/GameCore/Economy/Economy.swift`
  - `TyrianClone/TyrianClone/Features/ShopView.swift`
- Goal:
  - replace the current simplified weapon scaling with explicit 1-11 power levels for front and rear ports
- Acceptance criteria:
  - front and rear power are stored separately
  - each weapon can express 11 authored power entries or a well-defined interpolation rule
  - shop upgrades and mission pickups both apply cleanly
  - max-power overflow resolves into a fallback reward rule instead of breaking state

### TYC-007: Implement Rear Weapon Mode Switching

- Priority: `P1`
- Depends on: `TYC-006`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - `TyrianClone/TyrianClone/GameCore/Input/PlayerIntent.swift`
  - `TyrianClone/TyrianClone/Features/HUDView.swift`
- Goal:
  - support rear weapons with two configurations and runtime mode switching
- Acceptance criteria:
  - rear mode is part of persistent loadout plus runtime mission state
  - the active rear mode changes weapon behavior immediately
  - HUD state shows the active rear mode when a weapon supports multiple modes

### TYC-008: Implement Sidekick Behavior Classes

- Priority: `P1`
- Depends on: `TYC-001`, `TYC-002`, `TYC-005`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - `TyrianClone/TyrianClone/GameCore/Domain/RunState.swift`
  - `TyrianClone/TyrianClone/GameCore/Snapshots/RenderSnapshot.swift`
- Goal:
  - support left/right sidekick slots with attached, follower, charge-up, and ammo-limited behavior
- Acceptance criteria:
  - sidekicks are independent left and right equipment slots
  - unlimited-fire sidekicks can link to primary fire
  - ammo-limited sidekicks track ammo separately
  - sidekick drain can affect generator pressure if authored to do so

### TYC-009: Add Ship Definitions And Movement Profiles

- Priority: `P1`
- Depends on: `TYC-001`, `TYC-002`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - `TyrianClone/TyrianClone/GameCore/Domain/RunState.swift`
  - `TyrianClone/TyrianClone/Features/ShopView.swift`
- Goal:
  - make ship choice matter through armor and movement profile differences
- Acceptance criteria:
  - at least `USP Talon`, `Gencore Phoenix`, `Gencore Maelstrom`, and `USP Fang` are selectable
  - ship choice affects movement speed and armor capacity
  - switching ships in the shop updates both runtime and HUD state cleanly

### TYC-010: Replace Single-Stage Spawns With Authored Level Events And Waves

- Priority: `P0`
- Depends on: `TYC-001`, `TYC-002`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - new files under `TyrianClone/TyrianClone/GameCore/Simulation`
- Goal:
  - replace `StageDefinition` and `StageSpawn` with authored `LevelDefinition`, `LevelEvent`, and `WaveDefinition`
- Acceptance criteria:
  - missions are authored as event timelines instead of a flat spawn list
  - the simulation can trigger waves, hazards, pickups, and boss intros from event definitions
  - pre-boss, boss, and post-boss beats are representable without ad hoc flags

### TYC-011: Implement Enemy Taxonomy And Boss Phase State

- Priority: `P1`
- Depends on: `TYC-010`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - `TyrianClone/TyrianClone/GameCore/Snapshots/RenderSnapshot.swift`
  - new files under `TyrianClone/TyrianClone/GameCore/Domain`
- Goal:
  - support fodder, formation, aimed-fire, diving, hazard, miniboss, and boss definitions with explicit boss phases
- Acceptance criteria:
  - enemy definitions can represent movement script, fire profile, collision damage, drops, and death behavior
  - bosses can transition through at least two authored phases
  - mission completion can be gated on boss resolution

### TYC-012: Implement Pickups, Reward Buffering, And Datacubes

- Priority: `P1`
- Depends on: `TYC-003`, `TYC-010`, `TYC-011`
- Target areas:
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
  - `TyrianClone/TyrianClone/GameCore/Snapshots/RenderSnapshot.swift`
  - `TyrianClone/TyrianClone/Features/BriefingView.swift`
  - new files under `TyrianClone/TyrianClone/GameCore/Data`
- Goal:
  - support credits, datacubes, weapon power pickups, armor repair, and optional sidekick ammo pickups
- Acceptance criteria:
  - mission rewards can be tracked before being committed to `CampaignState`
  - datacubes persist in campaign state and can unlock flags or route information
  - mission failure discards only the rewards marked as non-persistent

### TYC-013: Implement Shop Inventory Rules And Purchase Flow

- Priority: `P1`
- Depends on: `TYC-002`, `TYC-003`, `TYC-006`, `TYC-009`
- Target areas:
  - `TyrianClone/TyrianClone/App/AppModel.swift`
  - `TyrianClone/TyrianClone/GameCore/Economy/Economy.swift`
  - `TyrianClone/TyrianClone/Features/ShopView.swift`
- Goal:
  - move the shop from one static prototype catalog to node-scoped inventory rules
- Acceptance criteria:
  - `savara-port-shop`, `deliani-market-shop`, and `gyges-prep-shop` can expose different inventory
  - ship, weapon, shield, generator, sidekick, and power-up purchases all work through one coherent rules layer
  - affordability, equip, and replacement rules are explicit

### TYC-014: Rebuild HUD Around Full Game State

- Priority: `P1`
- Depends on: `TYC-003`, `TYC-005`, `TYC-006`, `TYC-008`
- Target areas:
  - `TyrianClone/TyrianClone/Features/HUDView.swift`
  - `TyrianClone/TyrianClone/Features/MainScreen.swift`
  - `TyrianClone/TyrianClone/GameCore/Snapshots/RenderSnapshot.swift`
- Goal:
  - make the sheet show campaign and combat state that matches the spec instead of prototype labels
- Acceptance criteria:
  - armor, shield, energy, front power, rear power, rear mode, sidekicks, credits, mission progress, and boss state all display cleanly
  - datacube or branch state can be surfaced in non-combat nodes
  - no prototype-only terminology like “sortie” remains where the campaign model needs node-aware labels

### TYC-015: Author The Opening Route And First Shop

- Priority: `P1`
- Depends on: `TYC-002`, `TYC-003`, `TYC-010`, `TYC-013`
- Target areas:
  - new data files under `TyrianClone/TyrianClone/GameCore/Data`
- Goal:
  - author `tyrian-briefing`, `tyrian-outskirts`, `savara-port-shop`, and `savara-passage`
- Acceptance criteria:
  - the player can start a new campaign and play through the first two missions with a shop stop between them
  - the route demonstrates credits, power pickups, and early shop decisions
  - the missions feel materially different from the current single-stage prototype

### TYC-016: Author Branch Route Content

- Priority: `P1`
- Depends on: `TYC-015`
- Target areas:
  - new data files under `TyrianClone/TyrianClone/GameCore/Data`
- Goal:
  - author `branch-savara-or-deliani`, `deliani-run`, `deliani-market-shop`, and `savara-depths`
- Acceptance criteria:
  - the player can make a meaningful branch choice
  - the Deliani route emphasizes tighter lanes and aimed pressure
  - the Savara alternate route emphasizes safer movement and different reward cadence

### TYC-017: Author Gyges Prep And Slice Finale Boss

- Priority: `P1`
- Depends on: `TYC-011`, `TYC-015`, `TYC-016`
- Target areas:
  - new data files under `TyrianClone/TyrianClone/GameCore/Data`
  - `TyrianClone/TyrianClone/GameCore/Simulation/Simulation.swift`
- Goal:
  - author `gyges-prep-shop`, `gyges-gate`, and `gyges-boss` including a multi-phase boss
- Acceptance criteria:
  - both branch routes converge on the Gyges sequence
  - the boss gates mission completion
  - the fight rewards aggressive play while shield is healthy and punishes careless sustain usage

### TYC-018: Upgrade The Renderer For Multi-Node Content And Boss Telemetry

- Priority: `P2`
- Depends on: `TYC-010`, `TYC-011`, `TYC-014`
- Target areas:
  - `TyrianClone/TyrianClone/Rendering/MetalRenderer.swift`
  - `TyrianClone/TyrianClone/Rendering/SpriteBatch.swift`
  - `TyrianClone/TyrianClone/GameCore/Snapshots/RenderSnapshot.swift`
- Goal:
  - extend the current primitive renderer so it can render richer enemy families, larger bosses, hazards, pickups, and datacube-related mission cues without special-case hacks
- Acceptance criteria:
  - renderer can draw boss weak points or phase-relevant subparts if needed
  - pickups and hazards have distinct visuals
  - snapshot structure does not need prototype-only assumptions

### TYC-019: Add Rule-Level Tests For Core Systems

- Priority: `P1`
- Depends on: `TYC-005`, `TYC-006`, `TYC-008`, `TYC-010`, `TYC-013`
- Target areas:
  - new test target under the Xcode project
  - test files for `GameCore`
- Goal:
  - add automated tests for the rules most likely to regress
- Acceptance criteria:
  - tests cover generator and shield competition
  - tests cover weapon power progression and rear mode switching
  - tests cover sidekick behavior classes at a basic rules level
  - tests cover shop purchase and unlock rules
  - tests cover mission reward commit versus failure loss

### TYC-020: Add A First-Slice Parity Checklist

- Priority: `P2`
- Depends on: `TYC-015`, `TYC-016`, `TYC-017`
- Target areas:
  - new docs file under `docs/specs/tyrian-core`
- Goal:
  - create a manual verification checklist for the first playable slice against the spec and local references
- Acceptance criteria:
  - covers campaign flow, shop behavior, combat feel, pickups, datacubes, and boss completion
  - can be used as a release gate for the first playable milestone

## Recommended Build Order

Start in this order:

1. `TYC-001`
2. `TYC-002`
3. `TYC-003`
4. `TYC-005`
5. `TYC-006`
6. `TYC-010`
7. `TYC-011`
8. `TYC-012`
9. `TYC-013`
10. `TYC-014`
11. `TYC-015`
12. `TYC-016`
13. `TYC-017`
14. `TYC-019`

`TYC-004`, `TYC-007`, `TYC-008`, `TYC-009`, `TYC-018`, and `TYC-020` should be pulled in as soon as their dependencies stop blocking the main path.

## Suggested First Sprint

If work starts immediately, the highest-value first sprint is:

- `TYC-001`
- `TYC-002`
- `TYC-003`
- `TYC-005`
- `TYC-006`

That sprint turns the current prototype-shaped app into a campaign-capable Tyrian-shaped core and unlocks almost every meaningful content ticket afterward.
