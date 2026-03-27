import Combine
import CoreGraphics
import Foundation

@MainActor
final class GameplayViewModel: ObservableObject {
    @Published private(set) var hudSnapshot: HUDSnapshot

    let renderer = MetalRenderer()
    private static let simulationStep = 1.0 / 60.0

    var onStateChanged: ((RunState, HUDSnapshot) -> Void)?
    var onOutcome: ((StageOutcome, RunState) -> Void)?

    private let simulation: Simulation
    private lazy var clock = FixedStepClock(step: Self.simulationStep, preferredFramesPerSecond: 60) { [weak self] dt in
        self?.step(dt)
    }
    private var tacticalTime = 0.0
    private var smoothedAutopilotVector = CGVector.zero

    init(runState: RunState, stage: StageDefinition) {
        simulation = Simulation(runState: runState, stage: stage)
        hudSnapshot = simulation.makeHUDSnapshot()
        renderer.update(snapshot: simulation.makeRenderSnapshot())
    }

    func start() {
        syncState()
        clock.start()
    }

    func stop() {
        clock.stop()
    }

    private func step(_ dt: Double) {
        tacticalTime += dt
        let autopilot = autopilotPlan(dt: dt)
        let intent = PlayerIntent(
            axisX: autopilot.vector.dx,
            axisY: autopilot.vector.dy,
            isFiring: autopilot.isFiring,
            isLeftSidekickActive: autopilot.isLeftSidekickActive,
            isRightSidekickActive: autopilot.isRightSidekickActive,
            didToggleRearMode: false,
            isPaused: false
        )

        let outcome = simulation.update(dt: dt, intent: intent)
        syncState()

        if let outcome {
            stop()
            onOutcome?(outcome, simulation.runState)
        }
    }

    private func syncState() {
        let renderSnapshot = simulation.makeRenderSnapshot()
        let hudSnapshot = simulation.makeHUDSnapshot()
        renderer.update(snapshot: renderSnapshot)
        self.hudSnapshot = hudSnapshot
        onStateChanged?(simulation.runState, hudSnapshot)
    }

    private func hasEquippedSidekick(_ itemID: String) -> Bool {
        itemID != "empty"
    }

    private func autopilotPlan(dt: Double) -> AutopilotPlan {
        let player = simulation.player
        let vitality = vitalityRatio(for: player)
        let stance = shieldCombatStance(for: player, vitality: vitality)
        let aggressionWeight = stance.aggressionWeight
        let avoidanceWeight = stance.avoidanceWeight
        let dangerThreshold = stance.dangerThreshold
        let avoidance = avoidancePlan(for: player)
        let boss = currentBossTarget()

        let targetVector: CGVector
        if let boss {
            let bossAttackVector = bossPressureVector(for: boss, player: player, vitality: vitality)
            let bossAvoidanceWeight = max(0.68, avoidanceWeight - 0.58 - vitality * 0.22)
            let bossDangerThreshold = dangerThreshold + 0.22 + stance.shieldCommitment * 0.18

            if avoidance.danger > bossDangerThreshold {
                targetVector = combine(
                    primary: avoidance.vector.scaled(by: 0.95 + (1 - stance.shieldCommitment) * 0.55),
                    secondary: bossAttackVector.scaled(by: 0.95 + vitality * 0.4),
                    tertiary: fallbackPatrolVector(for: player).scaled(by: 0.2)
                )
            } else {
                targetVector = combine(
                    primary: bossAttackVector.scaled(by: aggressionWeight + 0.6),
                    secondary: avoidance.vector.scaled(by: bossAvoidanceWeight),
                    tertiary: .zero
                )
            }
        } else if avoidance.danger > dangerThreshold {
            targetVector = combine(
                primary: avoidance.vector.scaled(by: 1.15 + (1 - vitality) * 0.7),
                secondary: bestEnemyTarget(for: player).map {
                    seekVector(fromX: player.x, fromY: player.y, toX: $0.x, toY: preferredAttackY(for: $0), xWeight: 0.35, yWeight: 0.12)
                } ?? .zero,
                tertiary: .zero
            )
        } else if let pickup = bestPickupTarget(for: player) {
            let seekPickup = seekVector(
                fromX: player.x,
                fromY: player.y,
                toX: pickup.x,
                toY: pickup.y,
                xWeight: 1.15 + vitality * 0.45,
                yWeight: 0.95 + vitality * 0.25
            )
            let attackSupport = bestEnemyTarget(for: player).map {
                seekVector(fromX: player.x, fromY: player.y, toX: $0.x, toY: preferredAttackY(for: $0), xWeight: 0.55, yWeight: 0.26)
            } ?? .zero
            targetVector = combine(
                primary: seekPickup.scaled(by: aggressionWeight),
                secondary: avoidance.vector.scaled(by: avoidanceWeight),
                tertiary: attackSupport.scaled(by: 0.75 + vitality * 0.45)
            )
        } else if let enemy = bestEnemyTarget(for: player) {
            let attackVector = seekVector(
                fromX: player.x,
                fromY: player.y,
                toX: enemy.x,
                toY: preferredAttackY(for: enemy),
                xWeight: 1.0 + vitality * 0.35,
                yWeight: 0.45 + vitality * 0.22
            )
            targetVector = combine(
                primary: attackVector.scaled(by: aggressionWeight),
                secondary: avoidance.vector.scaled(by: avoidanceWeight),
                tertiary: fallbackPatrolVector(for: player).scaled(by: 0.55)
            )
        } else {
            targetVector = combine(
                primary: fallbackPatrolVector(for: player),
                secondary: avoidance.vector.scaled(by: avoidanceWeight * 0.9),
                tertiary: .zero
            )
        }

        let clampedTarget = targetVector.clampedMagnitude(maximum: 1)
        let smoothing = min(max(dt * 7.5, 0.08), 0.4)
        smoothedAutopilotVector.dx += (clampedTarget.dx - smoothedAutopilotVector.dx) * smoothing
        smoothedAutopilotVector.dy += (clampedTarget.dy - smoothedAutopilotVector.dy) * smoothing
        let weaponPolicy = weaponPolicy(for: player, avoidance: avoidance, boss: boss, stance: stance)

        return AutopilotPlan(
            vector: smoothedAutopilotVector.clampedMagnitude(maximum: 1),
            isFiring: weaponPolicy.isFiring,
            isLeftSidekickActive: weaponPolicy.isLeftSidekickActive,
            isRightSidekickActive: weaponPolicy.isRightSidekickActive
        )
    }

    private func bestPickupTarget(for player: PlayerState) -> CreditPickupState? {
        simulation.credits.max { lhs, rhs in
            pickupScore(lhs, player: player) < pickupScore(rhs, player: player)
        }
    }

    private func pickupScore(_ pickup: CreditPickupState, player: PlayerState) -> Double {
        let distance = hypot(pickup.x - player.x, pickup.y - player.y)
        let verticalBias = pickup.y < player.y ? 22.0 : -18.0
        return Double(pickup.value) * 10 - distance * 0.28 + verticalBias
    }

    private func bestEnemyTarget(for player: PlayerState) -> EnemyState? {
        simulation.enemies.max { lhs, rhs in
            enemyScore(lhs, player: player) < enemyScore(rhs, player: player)
        }
    }

    private func enemyScore(_ enemy: EnemyState, player: PlayerState) -> Double {
        let distance = hypot(enemy.x - player.x, enemy.y - player.y)
        let verticalBias = enemy.y < player.y ? 48.0 : -36.0
        let centerLaneBias = max(0, 40 - abs(enemy.x - Simulation.worldWidth / 2))
        let bossBonus = isBoss(enemy) ? 280.0 : 0
        return Double(enemy.reward) * 3 + verticalBias + centerLaneBias + bossBonus - distance * 0.18
    }

    private func preferredAttackY(for enemy: EnemyState) -> Double {
        let desiredOffset = isBoss(enemy) ? 128.0 : 150.0
        return min(max(enemy.y + desiredOffset, Simulation.topSafePadding + 36), Simulation.worldHeight - Simulation.bottomSheetPadding - 22)
    }

    private func avoidancePlan(for player: PlayerState) -> AvoidancePlan {
        var vector = CGVector.zero
        var danger = 0.0

        for projectile in simulation.projectiles where projectile.owner == .enemy {
            let horizon = min(max((player.y - projectile.y) / max(projectile.vy, 1), 0.1), 0.7)
            let futureX = projectile.x + projectile.vx * horizon
            let futureY = projectile.y + projectile.vy * horizon
            let dx = player.x - futureX
            let dy = player.y - futureY
            let distance = max(hypot(dx, dy), 1)
            let radius = 96.0 + projectile.radius * 4

            guard distance < radius else {
                continue
            }

            let strength = (radius - distance) / radius
            vector.dx += (dx / distance) * strength * 2.8
            vector.dy += (dy / distance) * strength * 2.2
            danger += strength * 1.2
        }

        for enemy in simulation.enemies {
            let dx = player.x - enemy.x
            let dy = player.y - enemy.y
            let distance = max(hypot(dx, dy), 1)
            let radius = (isBoss(enemy) ? 60.0 : 88.0) + enemy.radius * (isBoss(enemy) ? 1.2 : 2.4)

            guard distance < radius else {
                continue
            }

            let strength = (radius - distance) / radius
            vector.dx += (dx / distance) * strength * (isBoss(enemy) ? 1.1 : 1.8)
            vector.dy += (dy / distance) * strength * (isBoss(enemy) ? 0.8 : 1.5)
            danger += strength * (isBoss(enemy) ? 0.35 : 0.8)
        }

        if player.x < Simulation.sideSafePadding {
            vector.dx += (Simulation.sideSafePadding - player.x) / Simulation.sideSafePadding
            danger += 0.2
        } else if player.x > Simulation.worldWidth - Simulation.sideSafePadding {
            vector.dx -= (player.x - (Simulation.worldWidth - Simulation.sideSafePadding)) / Simulation.sideSafePadding
            danger += 0.2
        }

        return AvoidancePlan(vector: vector.clampedMagnitude(maximum: 1), danger: danger)
    }

    private func seekVector(fromX: Double, fromY: Double, toX: Double, toY: Double, xWeight: Double, yWeight: Double) -> CGVector {
        CGVector(
            dx: max(-1, min(1, ((toX - fromX) / 110) * xWeight)),
            dy: max(-1, min(1, ((toY - fromY) / 150) * yWeight))
        )
    }

    private func fallbackPatrolVector(for player: PlayerState) -> CGVector {
        let patrolX = Simulation.worldWidth / 2
        let patrolY = min(Simulation.worldHeight * 0.65, Simulation.worldHeight - Simulation.bottomSheetPadding - 28)
        return seekVector(fromX: player.x, fromY: player.y, toX: patrolX, toY: patrolY, xWeight: 0.55, yWeight: 0.35)
    }

    private func bossPressureVector(for boss: EnemyState, player: PlayerState, vitality: Double) -> CGVector {
        let strafeOffset = sin(tacticalTime * (1.4 + vitality * 0.5)) * (42 + vitality * 22)
        let targetX = max(
            Simulation.sideSafePadding,
            min(Simulation.worldWidth - Simulation.sideSafePadding, boss.x + strafeOffset)
        )
        let targetY = min(
            max(boss.y + 128, Simulation.topSafePadding + 28),
            Simulation.worldHeight - Simulation.bottomSheetPadding - 18
        )
        return seekVector(
            fromX: player.x,
            fromY: player.y,
            toX: targetX,
            toY: targetY,
            xWeight: 1.15 + vitality * 0.4,
            yWeight: 0.72 + vitality * 0.25
        )
    }

    private func combine(primary: CGVector, secondary: CGVector, tertiary: CGVector) -> CGVector {
        CGVector(
            dx: primary.dx + secondary.dx + tertiary.dx,
            dy: primary.dy + secondary.dy + tertiary.dy
        )
    }

    private func vitalityRatio(for player: PlayerState) -> Double {
        let shieldRatio = player.maxShield > 0 ? player.shield / player.maxShield : 0
        let armorRatio = player.maxArmor > 0 ? player.armor / player.maxArmor : 0
        return max(0, min(1, shieldRatio * 0.62 + armorRatio * 0.38))
    }

    private func shieldCombatStance(for player: PlayerState, vitality: Double) -> ShieldCombatStance {
        let shieldRatio = player.maxShield > 0 ? player.shield / player.maxShield : 0
        let shieldIsRecovering = player.shieldRegenCooldown > 0.05

        if shieldRatio > 0.55 && !shieldIsRecovering {
            return ShieldCombatStance(
                aggressionWeight: 1.45 + vitality * 0.75,
                avoidanceWeight: 0.95 - min(vitality * 0.18, 0.16),
                dangerThreshold: 0.92,
                shieldCommitment: 1
            )
        }

        if shieldRatio > 0.2 {
            return ShieldCombatStance(
                aggressionWeight: 1.0 + vitality * 0.55,
                avoidanceWeight: 1.35 - vitality * 0.2,
                dangerThreshold: 0.68,
                shieldCommitment: 0.58
            )
        }

        return ShieldCombatStance(
            aggressionWeight: 0.48 + vitality * 0.18,
            avoidanceWeight: 2.05 - vitality * 0.35,
            dangerThreshold: 0.36,
            shieldCommitment: 0.12
        )
    }

    private func weaponPolicy(
        for player: PlayerState,
        avoidance: AvoidancePlan,
        boss: EnemyState?,
        stance: ShieldCombatStance
    ) -> WeaponPolicy {
        let shieldRatio = player.maxShield > 0 ? player.shield / player.maxShield : 0
        let energyRatio = player.maxEnergy > 0 ? player.energy / player.maxEnergy : 0
        let shieldNeedsRecovery = shieldRatio < 0.98
        let lowShield = shieldRatio < 0.3
        let shieldRecoveryWindow = shieldNeedsRecovery && player.shieldRegenCooldown <= 0.05
        let reserveBase = 0.14 + (1 - shieldRatio) * 0.4 + max(0, avoidance.danger - stance.dangerThreshold) * 0.14
        let reserveBoost = (shieldRecoveryWindow ? 0.18 : 0) + (lowShield ? 0.14 : 0)
        let bossDiscount = boss != nil && shieldRatio > 0.55 ? 0.14 : 0
        let fireReserve = min(max(reserveBase + reserveBoost - bossDiscount, 0.12), 0.8)
        let bossPressureOverride = boss != nil && shieldRatio > 0.65 && energyRatio > 0.26
        let shouldFire = bossPressureOverride || (energyRatio > fireReserve && !(lowShield && avoidance.danger > 0.38))
        let shouldUseSidekicks = shouldFire && energyRatio > fireReserve + 0.16 && shieldRatio > 0.34

        return WeaponPolicy(
            isFiring: shouldFire,
            isLeftSidekickActive: shouldUseSidekicks && hasEquippedSidekick(simulation.runState.loadout.leftSidekickID),
            isRightSidekickActive: shouldUseSidekicks && hasEquippedSidekick(simulation.runState.loadout.rightSidekickID)
        )
    }

    private func currentBossTarget() -> EnemyState? {
        simulation.enemies.first(where: isBoss)
    }

    private func isBoss(_ enemy: EnemyState) -> Bool {
        (PrototypeData.enemyIndex[enemy.archetypeID] ?? PrototypeData.enemyArchetypes[0]).behavior == .boss
    }
}

private struct AvoidancePlan {
    let vector: CGVector
    let danger: Double
}

private struct AutopilotPlan {
    let vector: CGVector
    let isFiring: Bool
    let isLeftSidekickActive: Bool
    let isRightSidekickActive: Bool
}

private struct WeaponPolicy {
    let isFiring: Bool
    let isLeftSidekickActive: Bool
    let isRightSidekickActive: Bool
}

private struct ShieldCombatStance {
    let aggressionWeight: Double
    let avoidanceWeight: Double
    let dangerThreshold: Double
    let shieldCommitment: Double
}

private extension CGVector {
    func scaled(by value: Double) -> CGVector {
        CGVector(dx: dx * value, dy: dy * value)
    }

    func clampedMagnitude(maximum: Double) -> CGVector {
        let magnitude = hypot(dx, dy)
        guard magnitude > maximum, magnitude > 0 else {
            return self
        }

        let scale = maximum / magnitude
        return CGVector(dx: dx * scale, dy: dy * scale)
    }
}
