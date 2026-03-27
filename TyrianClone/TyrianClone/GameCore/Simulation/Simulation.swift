import CoreGraphics
import Foundation

final class Simulation {
    static let worldWidth = 360.0
    static let worldHeight = 640.0
    static let sideSafePadding = 56.0
    static let topSafePadding = 110.0
    static let bottomSheetPadding = 210.0

    private static let playerSpeed = 228.0
    private static let playerAcceleration = 1220.0
    private static let playerFriction = 1450.0

    private static var nextEntityID = 1

    private(set) var player: PlayerState
    private(set) var projectiles: [ProjectileState] = []
    private(set) var enemies: [EnemyState] = []
    private(set) var credits: [CreditPickupState] = []
    private(set) var effects: [EffectState] = []

    private let stage: StageDefinition
    private(set) var runState: RunState
    private var waves: [WaveCursor]
    private var elapsed = 0.0
    private var stageFinished = false
    private var bossSpawned = false
    private var frontWeapon: WeaponArchetype
    private var rearWeapon: WeaponArchetype
    private var leftSidekick: SidekickArchetype
    private var rightSidekick: SidekickArchetype

    init(runState: RunState, stage: StageDefinition) {
        self.runState = runState
        self.stage = stage
        self.waves = stage.spawns.map { WaveCursor(stageSpawn: $0, spawned: 0) }

        let shield = PrototypeData.shieldIndex[runState.loadout.shieldID] ?? PrototypeData.shields[0]
        let generator = PrototypeData.generatorIndex[runState.loadout.generatorID] ?? PrototypeData.generators[0]
        self.frontWeapon = PrototypeData.frontWeaponIndex[runState.loadout.frontWeaponID] ?? PrototypeData.frontWeapons[0]
        self.rearWeapon = PrototypeData.rearWeaponIndex[runState.loadout.rearWeaponID] ?? PrototypeData.rearWeapons[0]
        self.leftSidekick = PrototypeData.sidekickIndex[runState.loadout.leftSidekickID] ?? PrototypeData.sidekicks[0]
        self.rightSidekick = PrototypeData.sidekickIndex[runState.loadout.rightSidekickID] ?? PrototypeData.sidekicks[0]

        self.player = PlayerState(
            x: Self.worldWidth / 2,
            y: Self.worldHeight - 90,
            vx: 0,
            vy: 0,
            armor: 90,
            maxArmor: 90,
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
        updatePlayer(dt: dt, intent: intent)
        updateEnemies(dt: dt)
        updateProjectiles(dt: dt)
        updateCredits(dt: dt)
        updateEffects(dt: dt)

        if player.armor <= 0 {
            return StageOutcome(kind: .destroyed, earned: runState.earnedThisSortie, totalCredits: runState.credits, sortie: runState.sortie)
        }

        if !stageFinished, elapsed >= stage.duration, enemies.isEmpty, credits.isEmpty, allWavesSpawned() {
            stageFinished = true
            return StageOutcome(kind: .cleared, earned: runState.earnedThisSortie, totalCredits: runState.credits, sortie: runState.sortie)
        }

        return nil
    }

    func makeHUDSnapshot() -> HUDSnapshot {
        let left = PrototypeData.sidekickIndex[runState.loadout.leftSidekickID] ?? PrototypeData.sidekicks[0]
        let right = PrototypeData.sidekickIndex[runState.loadout.rightSidekickID] ?? PrototypeData.sidekicks[0]

        return HUDSnapshot(
            stageTime: elapsed,
            stageDuration: stage.duration,
            armor: player.armor,
            maxArmor: player.maxArmor,
            shield: player.shield,
            maxShield: player.maxShield,
            energy: player.energy,
            maxEnergy: player.maxEnergy,
            rearModeLabel: rearModeLabel,
            frontName: frontWeapon.name,
            frontPower: runState.loadout.frontPower,
            rearName: rearWeapon.name,
            rearPower: runState.loadout.rearPower,
            leftSidekickName: left.name,
            rightSidekickName: right.name
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

    private func scaledEnemyHP(base: Double) -> Double {
        (base * (1 + Double(runState.sortie - 1) * 0.18)).rounded()
    }

    private func scaledReward(base: Int) -> Int {
        Int((Double(base) * (1 + Double(runState.sortie - 1) * 0.14)).rounded())
    }

    private func updatePlayer(dt: Double, intent: PlayerIntent) {
        let targetVX = intent.axisX * Self.playerSpeed
        let targetVY = intent.axisY * Self.playerSpeed
        let accelX = (intent.axisX == 0 ? Self.playerFriction : Self.playerAcceleration) * dt
        let accelY = (intent.axisY == 0 ? Self.playerFriction : Self.playerAcceleration) * dt

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
        let powerScale = 1 + Double(runState.loadout.frontPower - 1) * 0.18
        guard player.frontCooldown <= 0, player.energy >= frontWeapon.modeA.energyCost else {
            return
        }

        player.energy -= frontWeapon.modeA.energyCost
        player.frontCooldown = frontWeapon.modeA.cooldown / powerScale
        emitPattern(
            owner: .player,
            originX: player.x,
            originY: player.y - 16,
            mode: frontWeapon.modeA,
            colorHex: frontWeapon.colorHex,
            direction: -.pi / 2,
            powerScale: powerScale,
            spreadOverride: frontWeapon.frontArc ?? 0
        )
    }

    private func fireRearWeapon() {
        let mode = weaponModeForRear(rearWeapon, modeIndex: player.rearModeIndex)
        let powerScale = 1 + Double(runState.loadout.rearPower - 1) * 0.16
        guard player.rearCooldown <= 0, player.energy >= mode.energyCost else {
            return
        }

        player.energy -= mode.energyCost
        player.rearCooldown = mode.cooldown / powerScale
        emitPattern(
            owner: .player,
            originX: player.x,
            originY: player.y + 18,
            mode: mode,
            colorHex: rearWeapon.colorHex,
            direction: .pi / 2,
            powerScale: powerScale,
            spreadOverride: mode.spread
        )
    }

    private func fireSidekick(_ sidekick: SidekickArchetype, lane: SidekickFireLane) {
        guard sidekick.id != "empty", sidekick.energyCost > 0 else {
            return
        }

        switch lane {
        case .left:
            guard player.leftSidekickCooldown <= 0, player.energy >= sidekick.energyCost else { return }
        case .right:
            guard player.rightSidekickCooldown <= 0, player.energy >= sidekick.energyCost else { return }
        }

        let orbitAngle = lane == .left ? Double.pi * 0.9 : Double.pi * 0.1
        let originX = player.x + cos(elapsed * 3 + orbitAngle) * sidekick.orbitRadius
        let originY = player.y + sin(elapsed * 3 + orbitAngle) * 18

        player.energy -= sidekick.energyCost
        if lane == .left {
            player.leftSidekickCooldown = sidekick.cooldown
        } else {
            player.rightSidekickCooldown = sidekick.cooldown
        }

        emitPattern(
            owner: .player,
            originX: originX,
            originY: originY,
            mode: WeaponFireMode(
                label: sidekick.name,
                cooldown: sidekick.cooldown,
                energyCost: sidekick.energyCost,
                damage: sidekick.damage,
                speed: sidekick.speed,
                spread: sidekick.spread,
                burst: sidekick.burst
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

        let shieldRecovery = min(
            player.shieldRegenPerSecond * dt,
            missingShield,
            player.energy
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
            case .boss:
                enemy.y = min(114, enemy.y + archetype.speed * dt)
                enemy.x = Self.worldWidth / 2 + sin(enemy.elapsed * 0.8) * 94
            }

            if enemy.fireCooldown <= 0 {
                fireEnemyWeapon(enemy: enemy, archetype: archetype)
                enemy.fireCooldown = archetype.fireCooldown
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
            emitPattern(
                owner: .enemy,
                originX: enemy.x,
                originY: enemy.y + 20,
                mode: WeaponFireMode(label: "Boss Fan", cooldown: archetype.fireCooldown, energyCost: 0, damage: 13 + Double(runState.sortie * 2), speed: archetype.projectileSpeed, spread: 1.25, burst: enemy.elapsed.truncatingRemainder(dividingBy: 4) < 2 ? 5 : 7),
                colorHex: archetype.colorHex,
                direction: .pi / 2,
                powerScale: 1,
                spreadOverride: 1.25
            )
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
                runState.credits += pickup.value
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
        let phase = lane == .left ? Double.pi * 0.9 : Double.pi * 0.1
        return CGPoint(
            x: player.x + cos(elapsed * 3 + phase) * sidekick.orbitRadius,
            y: player.y + sin(elapsed * 3 + phase) * 18
        )
    }

    private func bossIsActive() -> Bool {
        bossSpawned && enemies.contains { (PrototypeData.enemyIndex[$0.archetypeID] ?? PrototypeData.enemyArchetypes[0]).behavior == .boss }
    }

    private func weaponModeForRear(_ weapon: WeaponArchetype, modeIndex: Int) -> WeaponFireMode {
        if modeIndex == 1, let alternate = weapon.modeB {
            return alternate
        }
        return weapon.modeA
    }

    private func nextID() -> Int {
        Self.nextEntityID += 1
        return Self.nextEntityID
    }
}
