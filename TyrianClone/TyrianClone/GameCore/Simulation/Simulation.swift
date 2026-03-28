import CoreGraphics
import Foundation

final class Simulation {
    static let worldWidth = 360.0
    static let worldHeight = 640.0
    static let sideSafePadding = 56.0
    static let topSafePadding = 110.0
    static let bottomSheetPadding = 210.0

    private static let basePlayerSpeed = 228.0
    private static let basePlayerAcceleration = 1220.0
    private static let basePlayerFriction = 1450.0

    private(set) var player: PlayerState
    private(set) var projectiles: [ProjectileState] = []
    private(set) var enemies: [EnemyState] = []
    private(set) var credits: [CreditPickupState] = []
    private(set) var pickups: [MissionPickupState] = []
    private(set) var hazards: [HazardState] = []
    private(set) var effects: [EffectState] = []

    private let stage: StageDefinition
    private(set) var runState: RunState
    private var waves: [WaveCursor]
    private var elapsed = 0.0
    private var stageFinished = false
    private var bossSpawned = false
    private var triggeredEventIDs: Set<String> = []
    private var missionFrontPowerBonus = 0
    private var missionRearPowerBonus = 0
    private var nextEntityID = 1
    private var ship: ShipDefinition
    private var shield: ShieldDefinition
    private var generator: GeneratorDefinition
    private var frontWeapon: WeaponArchetype
    private var rearWeapon: WeaponArchetype
    private var leftSidekick: SidekickArchetype
    private var rightSidekick: SidekickArchetype

    init(runState: RunState, stage: StageDefinition) {
        self.runState = runState
        self.stage = stage
        self.waves = stage.spawns.map { WaveCursor(stageSpawn: $0, spawned: 0) }

        self.ship = TyrianCatalogData.shipIndex[runState.loadout.shipID] ?? TyrianCatalogData.ships[0]
        self.shield = PrototypeData.shieldIndex[runState.loadout.shieldID] ?? PrototypeData.shields[0]
        self.generator = PrototypeData.generatorIndex[runState.loadout.generatorID] ?? PrototypeData.generators[0]
        self.frontWeapon = PrototypeData.frontWeaponIndex[runState.loadout.frontWeaponID] ?? PrototypeData.frontWeapons[0]
        self.rearWeapon = PrototypeData.rearWeaponIndex[runState.loadout.rearWeaponID] ?? PrototypeData.rearWeapons[0]
        self.leftSidekick = PrototypeData.sidekickIndex[runState.loadout.leftSidekickID] ?? PrototypeData.sidekicks[0]
        self.rightSidekick = PrototypeData.sidekickIndex[runState.loadout.rightSidekickID] ?? PrototypeData.sidekicks[0]

        self.player = PlayerState(
            x: Self.worldWidth / 2,
            y: Self.worldHeight - Self.bottomSheetPadding - 24,
            vx: 0,
            vy: 0,
            armor: ship.armorCapacity,
            maxArmor: ship.armorCapacity,
            shield: shield.maxShield,
            maxShield: shield.maxShield,
            shieldRegenPerSecond: shield.regenPerSecond,
            shieldRegenDelay: shield.regenDelay,
            shieldRegenCooldown: 0,
            energy: generator.maxEnergy,
            maxEnergy: generator.maxEnergy,
            energyRegenPerSecond: generator.regenPerSecond,
            frontCooldown: 0,
            rearCooldown: 0,
            leftSidekickCooldown: 0,
            rightSidekickCooldown: 0,
            leftSidekickAmmo: leftSidekick.ammoCapacity,
            rightSidekickAmmo: rightSidekick.ammoCapacity,
            leftSidekickCharge: 0,
            rightSidekickCharge: 0,
            invulnerability: 0,
            rearModeIndex: runState.loadout.rearModeIndex
        )
    }

    var stageTime: Double {
        elapsed
    }

    var rearModeLabel: String {
        weaponModeForRear(rearWeapon, modeIndex: player.rearModeIndex).label
    }

    func update(dt: Double, intent: PlayerIntent) -> StageOutcome? {
        guard !intent.isPaused else {
            return nil
        }

        elapsed += dt

        if intent.didToggleRearMode, rearWeapon.modeB != nil {
            player.rearModeIndex = player.rearModeIndex == 0 ? 1 : 0
            runState.loadout.rearModeIndex = player.rearModeIndex
            spawnEffect(x: player.x, y: player.y - 24, colorHex: rearWeapon.colorHex, kind: .ring, radius: 28, life: 0.32)
        }

        spawnWaves()
        triggerLevelEvents()
        updatePlayer(dt: dt, intent: intent)
        updateEnemies(dt: dt)
        updateProjectiles(dt: dt)
        updateCredits(dt: dt)
        updatePickups(dt: dt)
        updateHazards(dt: dt)
        updateEffects(dt: dt)

        if player.armor <= 0 {
            return StageOutcome(
                kind: .destroyed,
                earned: runState.earnedThisSortie,
                totalCredits: runState.credits,
                sortie: runState.sortie,
                missionID: stage.id,
                nodeID: runState.currentNodeID,
                frontPowerReward: missionFrontPowerBonus,
                rearPowerReward: missionRearPowerBonus
            )
        }

        if !stageFinished, missionIsComplete() {
            stageFinished = true
            return StageOutcome(
                kind: .cleared,
                earned: runState.earnedThisSortie,
                totalCredits: runState.credits,
                sortie: runState.sortie,
                missionID: stage.id,
                nodeID: runState.currentNodeID,
                frontPowerReward: missionFrontPowerBonus,
                rearPowerReward: missionRearPowerBonus
            )
        }

        return nil
    }

    func makeHUDSnapshot() -> HUDSnapshot {
        let left = PrototypeData.sidekickIndex[runState.loadout.leftSidekickID] ?? PrototypeData.sidekicks[0]
        let right = PrototypeData.sidekickIndex[runState.loadout.rightSidekickID] ?? PrototypeData.sidekicks[0]

        return HUDSnapshot(
            stageTime: elapsed,
            stageDuration: stage.duration,
            shipName: ship.name,
            armor: player.armor,
            maxArmor: player.maxArmor,
            shield: player.shield,
            maxShield: player.maxShield,
            generatorName: generator.name,
            energy: player.energy,
            maxEnergy: player.maxEnergy,
            rearModeLabel: rearModeLabel,
            frontName: frontWeapon.name,
            frontPower: effectiveFrontPower,
            rearName: rearWeapon.name,
            rearPower: effectiveRearPower,
            leftSidekickName: left.name,
            rightSidekickName: right.name,
            leftSidekickAmmo: player.leftSidekickAmmo,
            rightSidekickAmmo: player.rightSidekickAmmo
        )
    }

    func makeRenderSnapshot() -> RenderSnapshot {
        RenderSnapshot(
            worldSize: CGSize(width: Self.worldWidth, height: Self.worldHeight),
            stageTime: elapsed,
            player: RenderSnapshot.PlayerSprite(
                position: CGPoint(x: player.x, y: player.y),
                frontWeaponColorHex: frontWeapon.colorHex,
                shieldColorHex: (PrototypeData.shieldIndex[runState.loadout.shieldID] ?? PrototypeData.shields[0]).colorHex,
                shieldActive: player.shield > 1,
                invulnerability: player.invulnerability
            ),
            sidekicks: sidekickSprites(),
            enemies: enemies.map { enemy in
                let archetype = PrototypeData.enemyIndex[enemy.archetypeID] ?? PrototypeData.enemyArchetypes[0]
                return RenderSnapshot.EnemySprite(
                    id: enemy.id,
                    position: CGPoint(x: enemy.x, y: enemy.y),
                    radius: enemy.radius,
                    colorHex: archetype.colorHex,
                    isBoss: archetype.behavior == .boss
                )
            },
            projectiles: projectiles.map { projectile in
                RenderSnapshot.ProjectileSprite(
                    id: projectile.id,
                    position: CGPoint(x: projectile.x, y: projectile.y),
                    radius: projectile.radius,
                    colorHex: projectile.colorHex,
                    isPlayerOwned: projectile.owner == .player
                )
            },
            credits: credits.map { RenderSnapshot.CreditSprite(id: $0.id, position: CGPoint(x: $0.x, y: $0.y)) },
            pickups: pickups.map { pickup in
                let definition = TyrianCatalogData.pickupIndex[pickup.pickupID] ?? TyrianCatalogData.pickups[0]
                return RenderSnapshot.PickupSprite(
                    id: pickup.id,
                    position: CGPoint(x: pickup.x, y: pickup.y),
                    kind: definition.kind
                )
            },
            hazards: hazards.map {
                RenderSnapshot.HazardSprite(
                    id: $0.id,
                    frame: CGRect(x: $0.x, y: $0.y, width: $0.width, height: $0.height),
                    colorHex: hazardColor(for: $0.hazardID)
                )
            },
            bossWeakPoints: bossWeakPoints(),
            effects: effects.map {
                RenderSnapshot.EffectSprite(
                    id: $0.id,
                    kind: $0.kind,
                    position: CGPoint(x: $0.x, y: $0.y),
                    colorHex: $0.colorHex,
                    life: $0.life,
                    maxLife: $0.maxLife,
                    radius: $0.radius
                )
            },
            bossLineColorHex: bossIsActive() ? rearWeapon.colorHex : nil
        )
    }

    private func spawnWaves() {
        for index in waves.indices {
            while waves[index].spawned < waves[index].stageSpawn.count,
                  elapsed >= waves[index].stageSpawn.time + waves[index].stageSpawn.interval * Double(waves[index].spawned) {
                let stageSpawn = waves[index].stageSpawn
                spawnEnemy(
                    archetypeID: stageSpawn.archetypeID,
                    lane: stageSpawn.lane,
                    variant: stageSpawn.variant,
                    order: waves[index].spawned,
                    count: stageSpawn.count
                )
                waves[index].spawned += 1
            }
        }
    }

    private func allWavesSpawned() -> Bool {
        waves.allSatisfy { $0.spawned >= $0.stageSpawn.count }
    }

    private func triggerLevelEvents() {
        guard !stage.events.isEmpty else {
            return
        }

        for event in stage.events {
            guard !triggeredEventIDs.contains(event.id) else {
                continue
            }

            let didReachTime = event.triggerTime.map { elapsed >= $0 } ?? false
            let didReachProgress = event.triggerProgress.map { stage.duration > 0 && (elapsed / stage.duration) >= $0 } ?? false
            guard didReachTime || didReachProgress else {
                continue
            }

            triggeredEventIDs.insert(event.id)

            switch event.eventType {
            case let .grantPickup(pickupID):
                spawnPickup(pickupID: pickupID)
            case let .startHazard(hazardID):
                spawnHazard(hazardID: hazardID)
            case let .bossIntro(bossID):
                triggerBossIntro(bossID: bossID)
            default:
                continue
            }
        }
    }

    private func missionIsComplete() -> Bool {
        switch stage.completionRule {
        case .defeatBoss:
            guard bossSpawned else {
                return false
            }
            return !bossIsActive() && credits.isEmpty && pickups.isEmpty
        case .clearAllWaves:
            return enemies.isEmpty && credits.isEmpty && pickups.isEmpty && hazards.isEmpty && allWavesSpawned()
        case .scripted:
            return false
        case .surviveDuration:
            return elapsed >= stage.duration && enemies.isEmpty && credits.isEmpty && pickups.isEmpty && hazards.isEmpty && allWavesSpawned()
        }
    }

    private func spawnEnemy(archetypeID: String, lane: Int, variant: Double, order: Int, count: Int) {
        let archetype = PrototypeData.enemyIndex[archetypeID] ?? PrototypeData.enemyArchetypes[0]
        let x = 56 + Double(lane) * 62 + (count > 1 ? (Double(order) - Double(count - 1) / 2) * 6 : 0)
        let y = archetype.behavior == .boss ? -90.0 : -40.0 - Double(order) * 10

        enemies.append(
            EnemyState(
                id: nextID(),
                archetypeID: archetypeID,
                x: x,
                y: y,
                vx: 0,
                vy: archetype.speed,
                hp: scaledEnemyHP(base: archetype.hp),
                radius: archetype.radius,
                reward: scaledReward(base: archetype.reward),
                contactDamage: archetype.contactDamage,
                elapsed: 0,
                fireCooldown: archetype.fireCooldown * (0.7 + Double.random(in: 0 ... 0.5)),
                variant: variant
            )
        )

        if archetype.behavior == .boss {
            bossSpawned = true
        }
    }

    private func spawnPickup(pickupID: String) {
        let lane = 1 + Int(Double(triggeredEventIDs.count % 4))
        pickups.append(
            MissionPickupState(
                id: nextID(),
                pickupID: pickupID,
                x: 46 + Double(lane) * 56,
                y: -24,
                vx: Double.random(in: -18 ... 18),
                vy: 92,
                radius: 10,
                age: 0
            )
        )
    }

    private func spawnHazard(hazardID: String) {
        switch hazardID {
        case "deliani-crossfire":
            hazards.append(
                HazardState(
                    id: nextID(),
                    hazardID: hazardID,
                    x: 34,
                    y: 248,
                    width: Self.worldWidth - 68,
                    height: 18,
                    vx: 0,
                    vy: 18,
                    damagePerSecond: 22,
                    age: 0,
                    life: 7.5
                )
            )
        case "savara-current-band":
            hazards.append(
                HazardState(
                    id: nextID(),
                    hazardID: hazardID,
                    x: 0,
                    y: 210,
                    width: Self.worldWidth,
                    height: 32,
                    vx: 0,
                    vy: 11,
                    damagePerSecond: 14,
                    age: 0,
                    life: 8.5
                )
            )
        case "gyges-grid", "gyges-boss-grid":
            hazards.append(
                HazardState(
                    id: nextID(),
                    hazardID: hazardID,
                    x: 52,
                    y: 184,
                    width: Self.worldWidth - 104,
                    height: 24,
                    vx: 0,
                    vy: 6,
                    damagePerSecond: hazardID == "gyges-boss-grid" ? 28 : 18,
                    age: 0,
                    life: hazardID == "gyges-boss-grid" ? 10 : 8
                )
            )
        default:
            return
        }
    }

    private func triggerBossIntro(bossID: String) {
        guard let enemy = enemies.first(where: { $0.archetypeID == bossID }) else {
            return
        }

        spawnEffect(x: enemy.x, y: enemy.y, colorHex: "#ffffff", kind: .ring, radius: 92, life: 0.7)
    }

    private func scaledEnemyHP(base: Double) -> Double {
        (base * (1 + Double(runState.sortie - 1) * 0.18)).rounded()
    }

    private func scaledReward(base: Int) -> Int {
        Int((Double(base) * (1 + Double(runState.sortie - 1) * 0.14)).rounded())
    }

    private func updatePlayer(dt: Double, intent: PlayerIntent) {
        let speed = Self.basePlayerSpeed * ship.speedBand
        let acceleration = Self.basePlayerAcceleration * (0.92 + ship.speedBand * 0.12)
        let friction = Self.basePlayerFriction * (0.94 + ship.speedBand * 0.08)
        let targetVX = intent.axisX * speed
        let targetVY = intent.axisY * speed
        let accelX = (intent.axisX == 0 ? friction : acceleration) * dt
        let accelY = (intent.axisY == 0 ? friction : acceleration) * dt

        player.vx = MathHelpers.approach(current: player.vx, target: targetVX, maxDelta: accelX)
        player.vy = MathHelpers.approach(current: player.vy, target: targetVY, maxDelta: accelY)

        player.x = MathHelpers.clamp(
            player.x + player.vx * dt,
            min: Self.sideSafePadding,
            max: Self.worldWidth - Self.sideSafePadding
        )
        player.y = MathHelpers.clamp(player.y + player.vy * dt, min: Self.topSafePadding, max: Self.worldHeight - Self.bottomSheetPadding)

        player.frontCooldown = max(0, player.frontCooldown - dt)
        player.rearCooldown = max(0, player.rearCooldown - dt)
        player.leftSidekickCooldown = max(0, player.leftSidekickCooldown - dt)
        player.rightSidekickCooldown = max(0, player.rightSidekickCooldown - dt)
        player.invulnerability = max(0, player.invulnerability - dt)
        player.energy = MathHelpers.clamp(player.energy + player.energyRegenPerSecond * dt, min: 0, max: player.maxEnergy)

        if intent.isLeftSidekickActive {
            player.leftSidekickCharge = min(player.leftSidekickCharge + dt, maxChargeWindow(for: leftSidekick))
        } else {
            player.leftSidekickCharge = max(0, player.leftSidekickCharge - dt * 0.7)
        }

        if intent.isRightSidekickActive {
            player.rightSidekickCharge = min(player.rightSidekickCharge + dt, maxChargeWindow(for: rightSidekick))
        } else {
            player.rightSidekickCharge = max(0, player.rightSidekickCharge - dt * 0.7)
        }

        if player.shieldRegenCooldown > 0 {
            player.shieldRegenCooldown -= dt
        } else {
            rechargeShieldUsingEnergy(dt: dt)
        }

        if intent.isFiring {
            fireFrontWeapon()
            fireRearWeapon()
        }

        if intent.isLeftSidekickActive {
            fireSidekick(leftSidekick, lane: .left)
        }

        if intent.isRightSidekickActive {
            fireSidekick(rightSidekick, lane: .right)
        }
    }

    private func fireFrontWeapon() {
        let powerDefinition = powerLevel(for: frontWeapon, level: effectiveFrontPower)
        let fireMode = WeaponFireMode(
            label: frontWeapon.modeA.label,
            cooldown: powerDefinition.cooldown,
            energyCost: powerDefinition.energyCost,
            damage: powerDefinition.damage,
            speed: powerDefinition.speed,
            spread: powerDefinition.spread,
            burst: powerDefinition.burst
        )
        guard player.frontCooldown <= 0, player.energy >= fireMode.energyCost else {
            return
        }

        player.energy -= fireMode.energyCost
        player.frontCooldown = fireMode.cooldown
        emitPattern(
            owner: .player,
            originX: player.x,
            originY: player.y - 16,
            mode: fireMode,
            colorHex: frontWeapon.colorHex,
            direction: -.pi / 2,
            powerScale: 1,
            spreadOverride: powerDefinition.spread == 0 ? (frontWeapon.frontArc ?? 0) : powerDefinition.spread
        )
    }

    private func fireRearWeapon() {
        guard rearWeapon.id != "none" else {
            return
        }

        let mode = weaponModeForRear(rearWeapon, modeIndex: player.rearModeIndex)
        let powerDefinition = powerLevel(for: rearWeapon, level: effectiveRearPower)
        let fireMode = WeaponFireMode(
            label: mode.label,
            cooldown: powerDefinition.cooldown,
            energyCost: powerDefinition.energyCost,
            damage: powerDefinition.damage,
            speed: powerDefinition.speed,
            spread: max(mode.spread, powerDefinition.spread),
            burst: max(mode.burst, powerDefinition.burst)
        )
        guard player.rearCooldown <= 0, player.energy >= fireMode.energyCost else {
            return
        }

        player.energy -= fireMode.energyCost
        player.rearCooldown = fireMode.cooldown
        emitPattern(
            owner: .player,
            originX: player.x,
            originY: player.y + 18,
            mode: fireMode,
            colorHex: rearWeapon.colorHex,
            direction: .pi / 2,
            powerScale: 1,
            spreadOverride: fireMode.spread
        )
    }

    private func fireSidekick(_ sidekick: SidekickArchetype, lane: SidekickFireLane) {
        guard sidekick.id != "empty" else {
            return
        }

        switch lane {
        case .left:
            guard player.leftSidekickCooldown <= 0 else { return }
        case .right:
            guard player.rightSidekickCooldown <= 0 else { return }
        }

        if sidekick.behaviorClass == .ammoLimited {
            let ammo = lane == .left ? player.leftSidekickAmmo : player.rightSidekickAmmo
            guard let ammo, ammo > 0 else { return }
        } else if player.energy < sidekick.energyCost {
            return
        }

        let position = sidekickPosition(for: lane)
        let chargeMultiplier = sidekickChargeMultiplier(for: sidekick, lane: lane)
        let chargeAdjustedCooldown = sidekick.behaviorClass == .chargeUp ? max(0.22, sidekick.cooldown * (0.72 + chargeMultiplier * 0.18)) : sidekick.cooldown
        let chargeAdjustedDamage = sidekick.damage * chargeMultiplier
        let chargeAdjustedBurst = sidekick.behaviorClass == .chargeUp ? max(sidekick.burst, Int(round(Double(sidekick.burst) * chargeMultiplier))) : sidekick.burst

        if lane == .left {
            player.leftSidekickCooldown = chargeAdjustedCooldown
            if sidekick.behaviorClass == .ammoLimited, let ammo = player.leftSidekickAmmo {
                player.leftSidekickAmmo = max(0, ammo - 1)
            }
            player.leftSidekickCharge = 0
        } else {
            player.rightSidekickCooldown = chargeAdjustedCooldown
            if sidekick.behaviorClass == .ammoLimited, let ammo = player.rightSidekickAmmo {
                player.rightSidekickAmmo = max(0, ammo - 1)
            }
            player.rightSidekickCharge = 0
        }

        if sidekick.energyCost > 0 {
            player.energy -= sidekick.energyCost
        }

        emitPattern(
            owner: .player,
            originX: position.x,
            originY: position.y,
            mode: WeaponFireMode(
                label: sidekick.name,
                cooldown: chargeAdjustedCooldown,
                energyCost: sidekick.energyCost,
                damage: chargeAdjustedDamage,
                speed: sidekick.speed,
                spread: sidekick.spread,
                burst: chargeAdjustedBurst
            ),
            colorHex: sidekick.colorHex,
            direction: -.pi / 2,
            powerScale: 1,
            spreadOverride: sidekick.spread
        )
    }

    private func emitPattern(
        owner: ProjectileState.Owner,
        originX: Double,
        originY: Double,
        mode: WeaponFireMode,
        colorHex: String,
        direction: Double,
        powerScale: Double,
        spreadOverride: Double
    ) {
        let burst = max(1, mode.burst)
        for index in 0 ..< burst {
            let offset = burst == 1 ? 0 : Double(index) / Double(burst - 1) - 0.5
            let angle = direction + offset * spreadOverride
            let speed = mode.speed * (owner == .player ? 1 : 0.92)
            projectiles.append(
                ProjectileState(
                    id: nextID(),
                    owner: owner,
                    x: originX,
                    y: originY,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    damage: mode.damage * powerScale,
                    radius: owner == .player ? 5 : 6,
                    colorHex: colorHex,
                    life: owner == .player ? 2.2 : 4
                )
            )
        }

        spawnEffect(x: originX, y: originY, colorHex: colorHex, kind: .flash, radius: 12, life: 0.14)
    }

    private func rechargeShieldUsingEnergy(dt: Double) {
        let missingShield = max(0, player.maxShield - player.shield)
        guard missingShield > 0, player.energy > 0 else {
            return
        }

        let effectiveShieldDemand = shield.generatorDemand ?? shield.regenPerSecond
        let rechargeBudget = min(player.energyRegenPerSecond, effectiveShieldDemand) * dt

        let shieldRecovery = min(
            player.shieldRegenPerSecond * dt,
            missingShield,
            player.energy,
            rechargeBudget
        )

        guard shieldRecovery > 0 else {
            return
        }

        player.shield += shieldRecovery
        player.energy -= shieldRecovery
    }

    private func updateEnemies(dt: Double) {
        for index in enemies.indices {
            var enemy = enemies[index]
            let archetype = PrototypeData.enemyIndex[enemy.archetypeID] ?? PrototypeData.enemyArchetypes[0]
            enemy.elapsed += dt
            enemy.fireCooldown -= dt

            switch archetype.behavior {
            case .straight:
                enemy.y += archetype.speed * dt
            case .sine:
                enemy.y += archetype.speed * dt
                enemy.x += sin(enemy.elapsed * 3.2 + enemy.variant) * 64 * dt
            case .dive:
                enemy.y += archetype.speed * 0.72 * dt
                enemy.x += sin(enemy.elapsed * 4.1 + enemy.variant) * 120 * dt
                if enemy.elapsed > 1.25 {
                    enemy.y += archetype.speed * 0.9 * dt
                }
            case .scripted:
                enemy.y += archetype.speed * dt
            case .boss:
                let phase = bossPhase(for: enemy, archetype: archetype)
                enemy.y = min(114 + Double(phase.phaseIndex) * 6, enemy.y + archetype.speed * dt)
                enemy.x = Self.worldWidth / 2 + sin(enemy.elapsed * (0.8 + Double(phase.phaseIndex) * 0.22)) * phase.horizontalAmplitude
            }

            if enemy.fireCooldown <= 0 {
                fireEnemyWeapon(enemy: enemy, archetype: archetype)
                enemy.fireCooldown = enemyFireCooldown(for: enemy, archetype: archetype)
            }

            if MathHelpers.distanceSquared(ax: enemy.x, ay: enemy.y, bx: player.x, by: player.y) <= pow(enemy.radius + 14, 2) {
                damagePlayer(amount: enemy.contactDamage)
                enemy.hp = 0
            }

            enemies[index] = enemy
        }

        for index in enemies.indices.reversed() {
            let enemy = enemies[index]
            if enemy.hp <= 0 {
                destroyEnemy(enemy)
                enemies.remove(at: index)
                continue
            }

            if enemy.y > Self.worldHeight + 70 || enemy.x < -80 || enemy.x > Self.worldWidth + 80 {
                enemies.remove(at: index)
            }
        }
    }

    private func fireEnemyWeapon(enemy: EnemyState, archetype: EnemyArchetype) {
        switch archetype.firePattern {
        case .none:
            return
        case .aimed:
            let angle = atan2(player.y - enemy.y, player.x - enemy.x)
            emitPattern(
                owner: .enemy,
                originX: enemy.x,
                originY: enemy.y + 10,
                mode: WeaponFireMode(label: "Aimed", cooldown: archetype.fireCooldown, energyCost: 0, damage: 12 + Double(runState.sortie * 2), speed: archetype.projectileSpeed, spread: 0, burst: 1),
                colorHex: archetype.colorHex,
                direction: angle,
                powerScale: 1,
                spreadOverride: 0
            )
        case .spread:
            emitPattern(
                owner: .enemy,
                originX: enemy.x,
                originY: enemy.y + 12,
                mode: WeaponFireMode(label: "Spread", cooldown: archetype.fireCooldown, energyCost: 0, damage: 10 + Double(runState.sortie * 2), speed: archetype.projectileSpeed, spread: 0.48, burst: 3),
                colorHex: archetype.colorHex,
                direction: .pi / 2,
                powerScale: 1,
                spreadOverride: 0.48
            )
        case .boss:
            let phase = bossPhase(for: enemy, archetype: archetype)
            emitPattern(
                owner: .enemy,
                originX: enemy.x,
                originY: enemy.y + 20,
                mode: WeaponFireMode(
                    label: "Boss Fan",
                    cooldown: archetype.fireCooldown * phase.fireCooldownMultiplier,
                    energyCost: 0,
                    damage: 13 + Double(runState.sortie * 2) + Double(phase.phaseIndex) * 4,
                    speed: archetype.projectileSpeed + phase.projectileSpeedBonus,
                    spread: 1.25 + Double(phase.phaseIndex) * 0.12,
                    burst: (enemy.elapsed.truncatingRemainder(dividingBy: 4) < 2 ? 5 : 7) + phase.burstBonus
                ),
                colorHex: archetype.colorHex,
                direction: .pi / 2,
                powerScale: 1,
                spreadOverride: 1.25 + Double(phase.phaseIndex) * 0.12
            )
        case .scripted:
            return
        }
    }

    private func updateProjectiles(dt: Double) {
        for index in projectiles.indices {
            projectiles[index].x += projectiles[index].vx * dt
            projectiles[index].y += projectiles[index].vy * dt
            projectiles[index].life -= dt
        }

        for index in projectiles.indices.reversed() {
            let projectile = projectiles[index]
            if projectile.life <= 0 ||
                projectile.x < -40 ||
                projectile.x > Self.worldWidth + 40 ||
                projectile.y < -60 ||
                projectile.y > Self.worldHeight + 60 {
                projectiles.remove(at: index)
                continue
            }

            if projectile.owner == .player {
                if let hitIndex = enemies.firstIndex(where: {
                    MathHelpers.distanceSquared(ax: projectile.x, ay: projectile.y, bx: $0.x, by: $0.y) <= pow(projectile.radius + $0.radius, 2)
                }) {
                    enemies[hitIndex].hp -= projectile.damage
                    spawnEffect(x: projectile.x, y: projectile.y, colorHex: projectile.colorHex, kind: .burst, radius: 14, life: 0.22)
                    projectiles.remove(at: index)
                }
            } else if MathHelpers.distanceSquared(ax: projectile.x, ay: projectile.y, bx: player.x, by: player.y) <= pow(projectile.radius + 12, 2) {
                damagePlayer(amount: projectile.damage)
                spawnEffect(x: projectile.x, y: projectile.y, colorHex: projectile.colorHex, kind: .flash, radius: 16, life: 0.18)
                projectiles.remove(at: index)
            }
        }
    }

    private func damagePlayer(amount: Double) {
        guard player.invulnerability <= 0 else {
            return
        }

        var remainingDamage = amount
        if player.shield > 0 {
            let absorbed = min(player.shield, remainingDamage)
            player.shield -= absorbed
            remainingDamage -= absorbed
        }

        if remainingDamage > 0 {
            player.armor = max(0, player.armor - remainingDamage)
        }

        player.shieldRegenCooldown = player.shieldRegenDelay
        player.invulnerability = 0.55
        spawnEffect(x: player.x, y: player.y, colorHex: "#ffffff", kind: .ring, radius: 26, life: 0.35)
    }

    private func destroyEnemy(_ enemy: EnemyState) {
        let archetype = PrototypeData.enemyIndex[enemy.archetypeID] ?? PrototypeData.enemyArchetypes[0]
        let isBoss = archetype.behavior == .boss
        let shards = isBoss ? 12 : max(2, Int(round(Double(enemy.reward) / 16)))
        let eachValue = max(4, Int(round(Double(enemy.reward) / Double(shards))))

        for shard in 0 ..< shards {
            let angle = (Double.pi * 2 * Double(shard)) / Double(shards)
            credits.append(
                CreditPickupState(
                    id: nextID(),
                    x: enemy.x,
                    y: enemy.y,
                    vx: cos(angle) * (40 + Double.random(in: 0 ... 50)),
                    vy: sin(angle) * (24 + Double.random(in: 0 ... 40)),
                    value: eachValue,
                    radius: 7,
                    age: 0
                )
            )
        }

        spawnEffect(x: enemy.x, y: enemy.y, colorHex: archetype.colorHex, kind: .burst, radius: isBoss ? 50 : 24, life: isBoss ? 0.7 : 0.42)
        spawnEffect(x: enemy.x, y: enemy.y, colorHex: "#ffffff", kind: .ring, radius: isBoss ? 78 : 28, life: isBoss ? 0.95 : 0.32)
    }

    private func updateCredits(dt: Double) {
        for index in credits.indices {
            var pickup = credits[index]
            pickup.age += dt
            pickup.vy += 40 * dt

            let dx = player.x - pickup.x
            let dy = player.y - pickup.y
            let pull = MathHelpers.clamp(420 / max(1, sqrt(dx * dx + dy * dy)), min: 0, max: 260)
            pickup.vx += (dx == 0 ? 0 : (dx / abs(dx)) * pull) * dt
            pickup.vy += (dy == 0 ? 0 : (dy / abs(dy)) * pull) * dt
            pickup.x += pickup.vx * dt
            pickup.y += pickup.vy * dt
            credits[index] = pickup
        }

        for index in credits.indices.reversed() {
            let pickup = credits[index]
            if MathHelpers.distanceSquared(ax: pickup.x, ay: pickup.y, bx: player.x, by: player.y) <= pow(pickup.radius + 14, 2) {
                runState.earnedThisSortie += pickup.value
                spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#88ffd5", kind: .flash, radius: 14, life: 0.14)
                credits.remove(at: index)
                continue
            }

            if pickup.age > 6 || pickup.y > Self.worldHeight + 30 {
                credits.remove(at: index)
            }
        }
    }

    private func updatePickups(dt: Double) {
        for index in pickups.indices {
            var pickup = pickups[index]
            pickup.age += dt
            pickup.vy += 24 * dt

            let dx = player.x - pickup.x
            let dy = player.y - pickup.y
            let attraction = MathHelpers.clamp(360 / max(1, sqrt(dx * dx + dy * dy)), min: 0, max: 210)
            pickup.vx += (dx == 0 ? 0 : (dx / abs(dx)) * attraction) * dt
            pickup.vy += (dy == 0 ? 0 : (dy / abs(dy)) * attraction) * dt
            pickup.x += pickup.vx * dt
            pickup.y += pickup.vy * dt
            pickups[index] = pickup
        }

        for index in pickups.indices.reversed() {
            let pickup = pickups[index]
            if MathHelpers.distanceSquared(ax: pickup.x, ay: pickup.y, bx: player.x, by: player.y) <= pow(pickup.radius + 14, 2) {
                applyPickup(pickup)
                pickups.remove(at: index)
                continue
            }

            if pickup.age > 8 || pickup.y > Self.worldHeight + 40 {
                pickups.remove(at: index)
            }
        }
    }

    private func updateHazards(dt: Double) {
        for index in hazards.indices {
            hazards[index].age += dt
            hazards[index].x += hazards[index].vx * dt
            hazards[index].y += hazards[index].vy * dt
            hazards[index].life -= dt

            let frame = CGRect(x: hazards[index].x, y: hazards[index].y, width: hazards[index].width, height: hazards[index].height).insetBy(dx: -10, dy: -10)
            if frame.contains(CGPoint(x: player.x, y: player.y)) {
                damagePlayer(amount: hazards[index].damagePerSecond * dt)
            }
        }

        for index in hazards.indices.reversed() {
            if hazards[index].life <= 0 || hazards[index].y > Self.worldHeight + 80 {
                hazards.remove(at: index)
            }
        }
    }

    private func applyPickup(_ pickup: MissionPickupState) {
        guard let definition = TyrianCatalogData.pickupIndex[pickup.pickupID] else {
            return
        }

        let value = definition.value ?? 0

        switch definition.kind {
        case .credits:
            runState.earnedThisSortie += value
            spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#88ffd5", kind: .flash, radius: 16, life: 0.16)
        case .frontPower:
            missionFrontPowerBonus = min(Economy.maxWeaponPower() - runState.loadout.frontPower, missionFrontPowerBonus + max(1, value))
            spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#ffd86a", kind: .ring, radius: 18, life: 0.24)
        case .rearPower:
            missionRearPowerBonus = min(Economy.maxWeaponPower() - runState.loadout.rearPower, missionRearPowerBonus + max(1, value))
            spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#7ef0c9", kind: .ring, radius: 18, life: 0.24)
        case .armorRepair:
            player.armor = min(player.maxArmor, player.armor + Double(value))
            spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#8fc5ff", kind: .ring, radius: 18, life: 0.24)
        case .shieldRestore:
            player.shield = min(player.maxShield, player.shield + Double(value))
            spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#a3a8ff", kind: .ring, radius: 18, life: 0.24)
        case .sidekickAmmo:
            if leftSidekick.behaviorClass == .ammoLimited, let ammo = player.leftSidekickAmmo {
                player.leftSidekickAmmo = ammo + value
            }
            if rightSidekick.behaviorClass == .ammoLimited, let ammo = player.rightSidekickAmmo {
                player.rightSidekickAmmo = ammo + value
            }
            spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#ffc86d", kind: .ring, radius: 18, life: 0.24)
        case .datacube, .scriptedItem:
            spawnEffect(x: pickup.x, y: pickup.y, colorHex: "#ffffff", kind: .ring, radius: 20, life: 0.24)
        }
    }

    private func updateEffects(dt: Double) {
        for index in effects.indices.reversed() {
            effects[index].life -= dt
            if effects[index].life <= 0 {
                effects.remove(at: index)
            }
        }
    }

    private func spawnEffect(x: Double, y: Double, colorHex: String, kind: EffectKind, radius: Double, life: Double) {
        effects.append(
            EffectState(
                id: nextID(),
                kind: kind,
                x: x,
                y: y,
                colorHex: colorHex,
                life: life,
                maxLife: life,
                radius: radius
            )
        )
    }

    private func sidekickSprites() -> [RenderSnapshot.SidekickSprite] {
        var sprites: [RenderSnapshot.SidekickSprite] = []
        if leftSidekick.id != "empty" {
            let position = sidekickPosition(for: .left)
            sprites.append(RenderSnapshot.SidekickSprite(id: "left", position: position, colorHex: leftSidekick.colorHex))
        }
        if rightSidekick.id != "empty" {
            let position = sidekickPosition(for: .right)
            sprites.append(RenderSnapshot.SidekickSprite(id: "right", position: position, colorHex: rightSidekick.colorHex))
        }
        return sprites
    }

    private func sidekickPosition(for lane: SidekickFireLane) -> CGPoint {
        let sidekick = lane == .left ? leftSidekick : rightSidekick
        let horizontalDirection = lane == .left ? -1.0 : 1.0

        switch sidekick.mountBehavior {
        case .attached:
            return CGPoint(x: player.x + horizontalDirection * 34, y: player.y - 8)
        case .followerStatic:
            return CGPoint(x: player.x + horizontalDirection * 46, y: player.y + 18)
        case .forwardMounted:
            return CGPoint(x: player.x + horizontalDirection * 26, y: player.y - 30)
        case .followerTurning:
            return CGPoint(x: player.x + horizontalDirection * 40, y: player.y + sin(elapsed * 2.6) * 10)
        case .orbiting:
            let phase = lane == .left ? Double.pi * 0.9 : Double.pi * 0.1
            return CGPoint(
                x: player.x + cos(elapsed * 3 + phase) * sidekick.orbitRadius,
                y: player.y + sin(elapsed * 3 + phase) * 18
            )
        }
    }

    private func sidekickChargeMultiplier(for sidekick: SidekickArchetype, lane: SidekickFireLane) -> Double {
        guard sidekick.behaviorClass == .chargeUp else {
            return 1
        }

        let storedCharge = lane == .left ? player.leftSidekickCharge : player.rightSidekickCharge
        let stageCount = max(1, sidekick.chargeStages ?? 1)
        let stageDuration = max(0.15, sidekick.cooldown * 0.65)
        let stageIndex = min(stageCount - 1, Int(storedCharge / stageDuration))
        return 1 + Double(stageIndex) * 0.7
    }

    private func maxChargeWindow(for sidekick: SidekickArchetype) -> Double {
        guard sidekick.behaviorClass == .chargeUp else {
            return sidekick.cooldown
        }

        return sidekick.cooldown * Double(max(1, sidekick.chargeStages ?? 1))
    }

    private func powerLevel(for weapon: WeaponArchetype, level: Int) -> WeaponPowerLevelDefinition {
        guard let exact = weapon.powerLevels.first(where: { $0.level == level }) else {
            return weapon.powerLevels.last ?? WeaponPowerLevelDefinition(
                level: level,
                cooldown: weapon.modeA.cooldown,
                energyCost: weapon.modeA.energyCost,
                damage: weapon.modeA.damage,
                speed: weapon.modeA.speed,
                spread: weapon.modeA.spread,
                burst: weapon.modeA.burst
            )
        }

        return exact
    }

    private var effectiveFrontPower: Int {
        min(Economy.maxWeaponPower(), runState.loadout.frontPower + missionFrontPowerBonus)
    }

    private var effectiveRearPower: Int {
        min(Economy.maxWeaponPower(), runState.loadout.rearPower + missionRearPowerBonus)
    }

    private func bossPhase(for enemy: EnemyState, archetype: EnemyArchetype) -> BossPhaseDefinition {
        let phases = TyrianCatalogData.bossPhaseIndex[archetype.id] ?? []
        guard !phases.isEmpty else {
            return BossPhaseDefinition(
                id: "\(archetype.id)-fallback-phase",
                bossID: archetype.id,
                phaseIndex: 0,
                minHealthRatio: 0,
                maxHealthRatio: 1,
                movementPattern: "fallback",
                attackSet: [],
                horizontalAmplitude: 94,
                fireCooldownMultiplier: 1,
                projectileSpeedBonus: 0,
                burstBonus: 0,
                weakPointOffsets: [CGPoint(x: 0, y: 18)],
                rewardTrigger: nil
            )
        }

        let ratio = archetype.hp > 0 ? enemy.hp / archetype.hp : 0
        return phases.first(where: { ratio >= $0.minHealthRatio && ratio <= $0.maxHealthRatio }) ?? phases.sorted(by: { $0.phaseIndex < $1.phaseIndex }).last!
    }

    private func enemyFireCooldown(for enemy: EnemyState, archetype: EnemyArchetype) -> Double {
        guard archetype.behavior == .boss else {
            return archetype.fireCooldown
        }

        let phase = bossPhase(for: enemy, archetype: archetype)
        return max(0.24, archetype.fireCooldown * phase.fireCooldownMultiplier)
    }

    private func bossWeakPoints() -> [RenderSnapshot.WeakPointSprite] {
        guard let boss = enemies.first(where: {
            let archetype = PrototypeData.enemyIndex[$0.archetypeID] ?? PrototypeData.enemyArchetypes[0]
            return archetype.taxonomy == .boss
        }) else {
            return []
        }

        let archetype = PrototypeData.enemyIndex[boss.archetypeID] ?? PrototypeData.enemyArchetypes[0]
        let phase = bossPhase(for: boss, archetype: archetype)
        return phase.weakPointOffsets.enumerated().map { index, offset in
            RenderSnapshot.WeakPointSprite(
                id: "\(phase.id)-\(index)",
                position: CGPoint(x: boss.x + offset.x, y: boss.y + offset.y),
                colorHex: archetype.colorHex
            )
        }
    }

    private func hazardColor(for hazardID: String) -> String {
        switch hazardID {
        case "deliani-crossfire":
            return "#9dd7ff"
        case "savara-current-band":
            return "#7ff0c9"
        case "gyges-grid", "gyges-boss-grid":
            return "#9ba9ff"
        default:
            return "#ffffff"
        }
    }

    private func bossIsActive() -> Bool {
        bossSpawned && enemies.contains { (PrototypeData.enemyIndex[$0.archetypeID] ?? PrototypeData.enemyArchetypes[0]).taxonomy == .boss }
    }

    private func weaponModeForRear(_ weapon: WeaponArchetype, modeIndex: Int) -> WeaponFireMode {
        if modeIndex == 1, let alternate = weapon.modeB {
            return alternate
        }
        return weapon.modeA
    }

    private func nextID() -> Int {
        nextEntityID += 1
        return nextEntityID
    }
}

#if DEBUG
extension Simulation {
    func debugInjectPickup(_ pickupID: String, x: Double? = nil, y: Double? = nil) {
        pickups.append(
            MissionPickupState(
                id: nextID(),
                pickupID: pickupID,
                x: x ?? player.x,
                y: y ?? player.y,
                vx: 0,
                vy: 0,
                radius: 10,
                age: 0
            )
        )
    }
}
#endif
