# First Slice Parity Checklist

## Purpose

Use this checklist as the manual release gate for the Tyrian first-playable slice implemented in the native SwiftUI + Metal build.

This checklist validates:

- campaign flow
- mission progression
- shop and loadout behavior
- weapon, shield, and generator interaction
- branch handling
- Gyges boss completion

## Campaign Flow

- Start a fresh campaign and confirm the first node is `tyrian-briefing`.
- Advance from briefing and confirm `tyrian-outskirts` launches as a mission, not as a passive screen.
- Clear `tyrian-outskirts` and confirm the campaign advances to `savara-port-shop`.
- Leave `savara-port-shop` and confirm `savara-passage` launches.
- Clear `savara-passage` and confirm the datacube node appears before the branch node.
- Continue from the datacube and confirm the branch screen exposes both `deliani-run` and `savara-depths`.
- Choose each branch on separate runs and confirm both routes converge on `gyges-prep-shop`.
- Confirm `gyges-gate` leads into the second datacube node, then into `gyges-boss`.
- Clear `gyges-boss` and confirm the campaign advances to `episode-slice-end`.

## Mission Structure

- Confirm early missions contain materially different wave pacing and enemy mixes.
- Confirm authored event pickups appear during missions instead of all rewards coming only from enemy kills.
- Confirm `front-power`, `rear-power`, `armor-repair`, and `shield-restore` pickups can all be collected when present.
- Confirm missions with `surviveDuration` do not clear until duration, wave completion, and collectible cleanup are all satisfied.
- Confirm `gyges-boss` does not clear until the boss is destroyed and boss-spawned rewards are resolved.

## Combat Rules

- Confirm the selected ship changes starting armor and movement feel.
- Confirm front and rear weapons both support power levels up to `11`.
- Confirm front and rear power pickups increase the correct port and never exceed `11`.
- Confirm weapon fire cadence and output change as power level increases.
- Confirm the shared energy pool drains under sustained fire.
- Confirm shield recharge does not begin immediately after damage.
- Confirm shield recharge competes with weapon sustain through the same energy economy.
- Confirm low-generator loadouts feel materially worse at sustaining both fire and shields.

## Rear Weapons And Sidekicks

- Confirm rear weapons with alternate modes can switch modes at runtime.
- Confirm the autonomous pilot changes rear mode in response to boss or crowd situations.
- Confirm linked-fire sidekicks fire with the primary attack pattern.
- Confirm charge-up sidekicks hold fire longer and produce a stronger burst when charged.
- Confirm ammo-limited sidekicks consume ammo and stop firing when depleted.
- Confirm sidekick ammo pickups restore ammo for equipped ammo-limited sidekicks.

## Shop And Loadout

- Confirm `savara-port-shop`, `deliani-market-shop`, and `gyges-prep-shop` expose different inventories.
- Confirm owned gear can be re-equipped without repurchase.
- Confirm unaffordable items cannot be purchased.
- Confirm ship purchases change the equipped ship and survive mission transitions.
- Confirm generator, shield, weapon, and sidekick swaps all update the HUD on the next passive node or mission start.
- Confirm weapon power upgrades use increasing costs and stop at `11`.

## Branch Identity

- Confirm the Deliani route feels denser and more aimed-pressure heavy than the Savara branch.
- Confirm the Savara alternate route feels safer laterally and has a different pickup cadence.
- Confirm both routes still preserve the same overall campaign state and converge cleanly.

## Boss Slice

- Confirm the Gyges boss enters, anchors near the top, and remains mission-gating.
- Confirm the boss shifts behavior as health drops instead of behaving as a single flat phase.
- Confirm aggressive play while shields are healthy produces materially better boss damage uptime.
- Confirm overcommitting to damage starves shield recovery and creates a visible sustain tradeoff.

## Failure Handling

- Confirm player destruction returns to the `destroyed` flow instead of silently advancing the graph.
- Confirm mission failure records the failed mission and leaves the campaign on a safe retry path.
- Confirm restarting the campaign returns to the briefing node with starter loadout and credits.

## HUD And Presentation

- Confirm the sheet shows ship, armor, shield, generator, energy, weapons, rear mode, and sidekick state.
- Confirm sidekick ammo is surfaced when an ammo-limited sidekick is equipped.
- Confirm mission status reflects the current node or mission state rather than prototype-only wording.
- Confirm the full-screen gameplay viewport still renders pickups, credits, enemies, sidekicks, and boss telemetry after route transitions.

## Pass Criteria

The first slice is considered ready for wider parity review when:

- both branches are completable
- Gyges boss can be cleared from either route
- shops materially affect outcome through ship, shield, generator, or weapon choices
- event pickups, boss gating, and datacube/branch transitions all work without manual resets
- no prototype-only single-stage assumptions remain in the critical campaign loop
