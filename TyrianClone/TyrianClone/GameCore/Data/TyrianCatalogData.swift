import Foundation
import CoreGraphics

enum TyrianCatalogData {
    static let ships: [ShipDefinition] = [
        ShipDefinition(id: "usp-talon", name: "USP Talon", shipGraphicIndex: 233, bigShipGraphicIndex: 32, sourceStatus: "exact", armorCapacity: 90, speedBand: 1.0, shopCost: 0, unlockRule: "starter", notes: "Operational starter baseline from OpenTyrian init."),
        ShipDefinition(id: "gencore-phoenix", name: "Gencore Phoenix", shipGraphicIndex: 157, bigShipGraphicIndex: 28, sourceStatus: "exact", armorCapacity: 110, speedBand: 0.95, shopCost: 900, unlockRule: "savara-port-shop", notes: nil),
        ShipDefinition(id: "gencore-maelstrom", name: "Gencore Maelstrom", shipGraphicIndex: 157, bigShipGraphicIndex: 28, sourceStatus: "exact", armorCapacity: 132, speedBand: 0.88, shopCost: 1450, unlockRule: "deliani-market-shop", notes: nil),
        ShipDefinition(id: "usp-fang", name: "USP Fang", shipGraphicIndex: 233, bigShipGraphicIndex: 32, sourceStatus: "exact", armorCapacity: 84, speedBand: 1.08, shopCost: 1280, unlockRule: "deliani-market-shop", notes: nil)
    ]

    static let frontWeapons: [WeaponPortDefinition] = [
        WeaponPortDefinition(
            id: "pulse-cannon",
            name: "Pulse-Cannon",
            slot: .front,
            sourceStatus: "exact",
            basePrice: 220,
            colorHex: "#7bf1ff",
            modeA: WeaponFireMode(label: "Stream", cooldown: 0.12, energyCost: 4, damage: 16, speed: 540, spread: 0.06, burst: 1),
            frontArc: 0.1,
            powerLevels: powerLevels(from: WeaponFireMode(label: "Stream", cooldown: 0.12, energyCost: 4, damage: 16, speed: 540, spread: 0.06, burst: 1), arc: 0.1)
        ),
        WeaponPortDefinition(
            id: "multi-cannon",
            name: "Multi-Cannon",
            slot: .front,
            sourceStatus: "exact",
            basePrice: 360,
            colorHex: "#ffd76c",
            modeA: WeaponFireMode(label: "Fork", cooldown: 0.18, energyCost: 7, damage: 14, speed: 510, spread: 0.28, burst: 2),
            frontArc: 0.16,
            powerLevels: powerLevels(from: WeaponFireMode(label: "Fork", cooldown: 0.18, energyCost: 7, damage: 14, speed: 510, spread: 0.28, burst: 2), arc: 0.16)
        ),
        WeaponPortDefinition(
            id: "laser",
            name: "Laser",
            slot: .front,
            sourceStatus: "exact",
            basePrice: 460,
            colorHex: "#ff8ab5",
            modeA: WeaponFireMode(label: "Pierce", cooldown: 0.28, energyCost: 10, damage: 38, speed: 660, spread: 0.02, burst: 1),
            frontArc: 0.04,
            powerLevels: powerLevels(from: WeaponFireMode(label: "Pierce", cooldown: 0.28, energyCost: 10, damage: 38, speed: 660, spread: 0.02, burst: 1), arc: 0.04)
        ),
        WeaponPortDefinition(
            id: "zica-laser",
            name: "Zica Laser",
            slot: .front,
            sourceStatus: "exact",
            basePrice: 620,
            colorHex: "#7ff0ff",
            modeA: WeaponFireMode(label: "Refine", cooldown: 0.22, energyCost: 11, damage: 26, speed: 700, spread: 0.03, burst: 2),
            frontArc: 0.05,
            powerLevels: powerLevels(from: WeaponFireMode(label: "Refine", cooldown: 0.22, energyCost: 11, damage: 26, speed: 700, spread: 0.03, burst: 2), arc: 0.05)
        ),
        WeaponPortDefinition(
            id: "vulcan-cannon-front",
            name: "Vulcan Cannon",
            slot: .front,
            sourceStatus: "exact",
            basePrice: 760,
            colorHex: "#ffb866",
            modeA: WeaponFireMode(label: "Chain", cooldown: 0.1, energyCost: 8, damage: 10, speed: 620, spread: 0.12, burst: 3),
            frontArc: 0.12,
            powerLevels: powerLevels(from: WeaponFireMode(label: "Chain", cooldown: 0.1, energyCost: 8, damage: 10, speed: 620, spread: 0.12, burst: 3), arc: 0.12)
        ),
        WeaponPortDefinition(
            id: "lightning-cannon",
            name: "Lightning Cannon",
            slot: .front,
            sourceStatus: "exact",
            basePrice: 980,
            colorHex: "#9ea8ff",
            modeA: WeaponFireMode(label: "Arc", cooldown: 0.18, energyCost: 13, damage: 28, speed: 600, spread: 0.18, burst: 2),
            frontArc: 0.08,
            powerLevels: powerLevels(from: WeaponFireMode(label: "Arc", cooldown: 0.18, energyCost: 13, damage: 28, speed: 600, spread: 0.18, burst: 2), arc: 0.08)
        )
    ]

    static let rearWeapons: [WeaponPortDefinition] = [
        WeaponPortDefinition(
            id: "none",
            name: "None",
            slot: .rear,
            sourceStatus: "exact",
            basePrice: 0,
            colorHex: "#6b7a91",
            modeA: WeaponFireMode(label: "Idle", cooldown: 999, energyCost: 0, damage: 0, speed: 0, spread: 0, burst: 0),
            powerLevels: powerLevels(from: WeaponFireMode(label: "Idle", cooldown: 999, energyCost: 0, damage: 0, speed: 0, spread: 0, burst: 0), arc: nil)
        ),
        WeaponPortDefinition(
            id: "starburst",
            name: "Starburst",
            slot: .rear,
            sourceStatus: "exact",
            basePrice: 200,
            colorHex: "#a0b7ff",
            modeA: WeaponFireMode(label: "Trace", cooldown: 0.3, energyCost: 7, damage: 18, speed: 430, spread: 0.05, burst: 1),
            modeB: WeaponFireMode(label: "Bloom", cooldown: 0.5, energyCost: 12, damage: 16, speed: 380, spread: 0.42, burst: 3),
            powerLevels: powerLevels(from: WeaponFireMode(label: "Trace", cooldown: 0.3, energyCost: 7, damage: 18, speed: 430, spread: 0.05, burst: 1), arc: nil)
        ),
        WeaponPortDefinition(
            id: "sonic-wave",
            name: "Sonic Wave",
            slot: .rear,
            sourceStatus: "exact",
            basePrice: 340,
            colorHex: "#6dffb2",
            modeA: WeaponFireMode(label: "Drop", cooldown: 0.55, energyCost: 13, damage: 30, speed: 240, spread: 0.03, burst: 1),
            modeB: WeaponFireMode(label: "Spiral", cooldown: 0.45, energyCost: 15, damage: 20, speed: 320, spread: 0.8, burst: 4),
            powerLevels: powerLevels(from: WeaponFireMode(label: "Drop", cooldown: 0.55, energyCost: 13, damage: 30, speed: 240, spread: 0.03, burst: 1), arc: nil)
        ),
        WeaponPortDefinition(
            id: "wild-ball",
            name: "Wild Ball",
            slot: .rear,
            sourceStatus: "exact",
            basePrice: 500,
            colorHex: "#ffb866",
            modeA: WeaponFireMode(label: "Volley", cooldown: 0.42, energyCost: 15, damage: 24, speed: 420, spread: 0.22, burst: 2),
            modeB: WeaponFireMode(label: "Needle", cooldown: 0.62, energyCost: 20, damage: 44, speed: 580, spread: 0.04, burst: 1),
            powerLevels: powerLevels(from: WeaponFireMode(label: "Volley", cooldown: 0.42, energyCost: 15, damage: 24, speed: 420, spread: 0.22, burst: 2), arc: nil)
        ),
        WeaponPortDefinition(
            id: "vulcan-cannon-rear",
            name: "Vulcan Cannon",
            slot: .rear,
            sourceStatus: "exact",
            basePrice: 660,
            colorHex: "#ffb866",
            modeA: WeaponFireMode(label: "Chain", cooldown: 0.16, energyCost: 10, damage: 11, speed: 520, spread: 0.2, burst: 3),
            modeB: WeaponFireMode(label: "Needle", cooldown: 0.32, energyCost: 13, damage: 22, speed: 560, spread: 0.08, burst: 1),
            powerLevels: powerLevels(from: WeaponFireMode(label: "Chain", cooldown: 0.16, energyCost: 10, damage: 11, speed: 520, spread: 0.2, burst: 3), arc: nil)
        )
    ]

    static let shields: [ShieldDefinition] = [
        ShieldDefinition(id: "advanced-integrity-field", name: "Advanced Integrity Field", sourceStatus: "exact", basePrice: 160, maxShield: 90, regenPerSecond: 7, regenDelay: 1.7, generatorDemand: 7, colorHex: "#78f7ff"),
        ShieldDefinition(id: "gencore-low-energy-shield", name: "Gencore Low Energy Shield", sourceStatus: "exact", basePrice: 310, maxShield: 130, regenPerSecond: 9, regenDelay: 1.5, generatorDemand: 9, colorHex: "#66d6ff"),
        ShieldDefinition(id: "gencore-high-energy-shield", name: "Gencore High Energy Shield", sourceStatus: "exact", basePrice: 520, maxShield: 180, regenPerSecond: 12, regenDelay: 1.3, generatorDemand: 12, colorHex: "#8da2ff"),
        ShieldDefinition(id: "microcorp-lxs-class-a", name: "MicroCorp LXS Class A", sourceStatus: "exact", basePrice: 760, maxShield: 220, regenPerSecond: 14, regenDelay: 1.2, generatorDemand: 13, colorHex: "#9db2ff"),
        ShieldDefinition(id: "microcorp-hxs-class-a", name: "MicroCorp HXS Class A", sourceStatus: "exact", basePrice: 980, maxShield: 260, regenPerSecond: 15, regenDelay: 1.15, generatorDemand: 15, colorHex: "#c0caff")
    ]

    static let generators: [GeneratorDefinition] = [
        GeneratorDefinition(id: "standard-mr-9", name: "Standard MR-9", sourceStatus: "exact", basePrice: 150, maxEnergy: 110, regenPerSecond: 34, colorHex: "#a7ff88"),
        GeneratorDefinition(id: "advanced-mr-12", name: "Advanced MR-12", sourceStatus: "exact", basePrice: 300, maxEnergy: 145, regenPerSecond: 44, colorHex: "#88ffbd"),
        GeneratorDefinition(id: "gencore-custom-mr-12", name: "Gencore Custom MR-12", sourceStatus: "exact", basePrice: 500, maxEnergy: 180, regenPerSecond: 58, colorHex: "#63ffde"),
        GeneratorDefinition(id: "standard-microfusion", name: "Standard MicroFusion", sourceStatus: "exact", basePrice: 720, maxEnergy: 210, regenPerSecond: 68, colorHex: "#73f8d0"),
        GeneratorDefinition(id: "advanced-mircofusion", name: "Advanced MircoFusion", sourceStatus: "exact", basePrice: 920, maxEnergy: 240, regenPerSecond: 78, colorHex: "#60f1d8"),
        GeneratorDefinition(id: "gravitron-pulse-wave", name: "Gravitron Pulse-Wave", sourceStatus: "exact", basePrice: 1180, maxEnergy: 275, regenPerSecond: 92, colorHex: "#7afef0")
    ]

    static let sidekicks: [SidekickDefinition] = [
        SidekickDefinition(id: "empty", name: "None", sourceStatus: "exact", basePrice: 0, colorHex: "#6b7a91", fireLane: .left, cooldown: 0.8, energyCost: 0, damage: 0, speed: 0, spread: 0, burst: 0, orbitRadius: 34, mountBehavior: .orbiting, behaviorClass: .linkedFire),
        SidekickDefinition(id: "single-shot-option", name: "Single Shot Option", sourceStatus: "exact", basePrice: 190, colorHex: "#7affd9", fireLane: .left, cooldown: 0.4, energyCost: 9, damage: 16, speed: 470, spread: 0.08, burst: 1, orbitRadius: 42, mountBehavior: .attached, behaviorClass: .linkedFire),
        SidekickDefinition(id: "companion-ship-warfly", name: "Companion Ship Warfly", sourceStatus: "exact", basePrice: 280, colorHex: "#ffe570", fireLane: .left, cooldown: 0.6, energyCost: 12, damage: 18, speed: 420, spread: 0.2, burst: 2, orbitRadius: 54, mountBehavior: .followerStatic, behaviorClass: .linkedFire),
        SidekickDefinition(id: "charge-cannon", name: "Charge Cannon", sourceStatus: "exact", basePrice: 420, colorHex: "#ff8cc5", fireLane: .left, cooldown: 0.85, energyCost: 16, damage: 36, speed: 560, spread: 0.05, burst: 1, orbitRadius: 58, mountBehavior: .orbiting, behaviorClass: .chargeUp, chargeStages: 3),
        SidekickDefinition(id: "microbomb-ammo-60", name: "MicroBomb Ammo 60", sourceStatus: "exact", basePrice: 520, colorHex: "#ffc86d", fireLane: .left, cooldown: 1.1, energyCost: 0, damage: 48, speed: 320, spread: 0.35, burst: 1, orbitRadius: 56, mountBehavior: .orbiting, behaviorClass: .ammoLimited, ammoCapacity: 60)
    ]

    static let enemies: [EnemyDefinition] = [
        EnemyDefinition(id: "tyrian-scout", name: "Tyrian Scout", sourceStatus: "approximation", taxonomy: .fodder, behavior: .straight, firePattern: .none, speed: 110, hp: 28, radius: 14, reward: 22, colorHex: "#7ee7ff", contactDamage: 18, fireCooldown: 99, projectileSpeed: 0),
        EnemyDefinition(id: "savara-diver", name: "Savara Diver", sourceStatus: "approximation", taxonomy: .pathing, behavior: .sine, firePattern: .aimed, speed: 96, hp: 46, radius: 17, reward: 34, colorHex: "#ffd670", contactDamage: 24, fireCooldown: 1.35, projectileSpeed: 190),
        EnemyDefinition(id: "microsol-interceptor", name: "Microsol Interceptor", sourceStatus: "approximation", taxonomy: .formation, behavior: .dive, firePattern: .spread, speed: 132, hp: 64, radius: 18, reward: 48, colorHex: "#ff8ab3", contactDamage: 30, fireCooldown: 1.9, projectileSpeed: 210),
        EnemyDefinition(id: "deliani-tower-turret", name: "Deliani Tower Turret", sourceStatus: "approximation", taxonomy: .hazard, behavior: .straight, firePattern: .aimed, speed: 70, hp: 78, radius: 20, reward: 54, colorHex: "#9dd7ff", contactDamage: 32, fireCooldown: 1.0, projectileSpeed: 220),
        EnemyDefinition(id: "gyges-gate-drone", name: "Gyges Gate Drone", sourceStatus: "approximation", taxonomy: .aimedFire, behavior: .sine, firePattern: .spread, speed: 118, hp: 84, radius: 20, reward: 70, colorHex: "#9bf4db", contactDamage: 34, fireCooldown: 1.1, projectileSpeed: 240),
        EnemyDefinition(id: "gyges-gate-controller", name: "Gyges Gate Controller", sourceStatus: "approximation", taxonomy: .boss, behavior: .boss, firePattern: .boss, speed: 38, hp: 1180, radius: 42, reward: 620, colorHex: "#9ba9ff", contactDamage: 44, fireCooldown: 0.55, projectileSpeed: 220)
    ]

    static let bossPhases: [BossPhaseDefinition] = [
        BossPhaseDefinition(
            id: "gyges-gate-controller-phase-1",
            bossID: "gyges-gate-controller",
            phaseIndex: 0,
            minHealthRatio: 0.67,
            maxHealthRatio: 1.0,
            movementPattern: "anchored-sweep",
            attackSet: ["fan-5", "escort-release"],
            horizontalAmplitude: 94,
            fireCooldownMultiplier: 1.0,
            projectileSpeedBonus: 0,
            burstBonus: 0,
            weakPointOffsets: [CGPoint(x: 0, y: 18)],
            rewardTrigger: nil
        ),
        BossPhaseDefinition(
            id: "gyges-gate-controller-phase-2",
            bossID: "gyges-gate-controller",
            phaseIndex: 1,
            minHealthRatio: 0.34,
            maxHealthRatio: 0.66,
            movementPattern: "wide-sweep",
            attackSet: ["fan-6", "pressure-spread"],
            horizontalAmplitude: 116,
            fireCooldownMultiplier: 0.82,
            projectileSpeedBonus: 24,
            burstBonus: 1,
            weakPointOffsets: [CGPoint(x: -20, y: 10), CGPoint(x: 20, y: 10)],
            rewardTrigger: nil
        ),
        BossPhaseDefinition(
            id: "gyges-gate-controller-phase-3",
            bossID: "gyges-gate-controller",
            phaseIndex: 2,
            minHealthRatio: 0.0,
            maxHealthRatio: 0.33,
            movementPattern: "tight-sweep",
            attackSet: ["fan-8", "needle-center"],
            horizontalAmplitude: 132,
            fireCooldownMultiplier: 0.68,
            projectileSpeedBonus: 46,
            burstBonus: 2,
            weakPointOffsets: [CGPoint(x: -26, y: 12), CGPoint(x: 0, y: 24), CGPoint(x: 26, y: 12)],
            rewardTrigger: "onDestroy"
        )
    ]

    static let levels: [LevelDefinition] = [
        LevelDefinition(id: "tyrian-outskirts", name: "Tyrian Outskirts", worldID: "tyrian", duration: 42, backgroundTheme: "tyrian", waves: [
            StageSpawn(time: 1.5, archetypeID: "tyrian-scout", lane: 0, count: 5, interval: 0.4, variant: 0),
            StageSpawn(time: 5.2, archetypeID: "tyrian-scout", lane: 4, count: 5, interval: 0.4, variant: 0),
            StageSpawn(time: 10.5, archetypeID: "savara-diver", lane: 1, count: 3, interval: 0.9, variant: -1),
            StageSpawn(time: 16.4, archetypeID: "tyrian-scout", lane: 2, count: 8, interval: 0.28, variant: 0),
            StageSpawn(time: 23.8, archetypeID: "microsol-interceptor", lane: 1, count: 2, interval: 1.8, variant: 1),
            StageSpawn(time: 27.4, archetypeID: "microsol-interceptor", lane: 3, count: 2, interval: 1.8, variant: -1),
            StageSpawn(time: 34.2, archetypeID: "savara-diver", lane: 2, count: 4, interval: 0.7, variant: 1)
        ], events: [
            LevelEvent(id: "tyrian-outskirts-front-power", triggerTime: 14, triggerProgress: nil, eventType: .grantPickup(pickupID: "front-power"), notes: "Early weapon spike."),
            LevelEvent(id: "tyrian-outskirts-armor", triggerTime: 30, triggerProgress: nil, eventType: .grantPickup(pickupID: "armor-repair"), notes: nil)
        ], nextNodeRules: ["savara-port-shop"]),
        LevelDefinition(id: "savara-passage", name: "Savara Passage", worldID: "savara", duration: 48, backgroundTheme: "savara", waves: [
            StageSpawn(time: 1.2, archetypeID: "tyrian-scout", lane: 0, count: 6, interval: 0.35, variant: 0),
            StageSpawn(time: 6.1, archetypeID: "savara-diver", lane: 2, count: 4, interval: 0.75, variant: 0),
            StageSpawn(time: 12.6, archetypeID: "microsol-interceptor", lane: 4, count: 3, interval: 1.0, variant: -1),
            StageSpawn(time: 18.2, archetypeID: "savara-diver", lane: 1, count: 4, interval: 0.7, variant: 1),
            StageSpawn(time: 26.8, archetypeID: "tyrian-scout", lane: 2, count: 10, interval: 0.22, variant: 0),
            StageSpawn(time: 34.0, archetypeID: "microsol-interceptor", lane: 0, count: 3, interval: 1.4, variant: 1),
            StageSpawn(time: 40.0, archetypeID: "gyges-gate-drone", lane: 2, count: 1, interval: 0.1, variant: 0)
        ], events: [
            LevelEvent(id: "savara-passage-rear-power", triggerTime: 21, triggerProgress: nil, eventType: .grantPickup(pickupID: "rear-power"), notes: nil),
            LevelEvent(id: "savara-passage-shield", triggerTime: 38, triggerProgress: nil, eventType: .grantPickup(pickupID: "shield-restore"), notes: nil)
        ], nextNodeRules: ["cube-savara-trade-warning-node"]),
        LevelDefinition(id: "deliani-run", name: "Deliani Run", worldID: "deliani", duration: 54, backgroundTheme: "deliani", waves: [
            StageSpawn(time: 1.0, archetypeID: "deliani-tower-turret", lane: 1, count: 2, interval: 1.2, variant: 0),
            StageSpawn(time: 4.5, archetypeID: "savara-diver", lane: 2, count: 4, interval: 0.65, variant: 1),
            StageSpawn(time: 9.0, archetypeID: "deliani-tower-turret", lane: 3, count: 2, interval: 1.2, variant: 0),
            StageSpawn(time: 14.0, archetypeID: "microsol-interceptor", lane: 0, count: 4, interval: 0.9, variant: 1),
            StageSpawn(time: 24.0, archetypeID: "deliani-tower-turret", lane: 2, count: 3, interval: 1.0, variant: 0),
            StageSpawn(time: 33.0, archetypeID: "gyges-gate-drone", lane: 2, count: 3, interval: 1.1, variant: 0),
            StageSpawn(time: 44.0, archetypeID: "microsol-interceptor", lane: 4, count: 5, interval: 0.55, variant: -1)
        ], events: [
            LevelEvent(id: "deliani-run-hazard-crossfire", triggerTime: 11, triggerProgress: nil, eventType: .startHazard(hazardID: "deliani-crossfire"), notes: "Lane pressure."),
            LevelEvent(id: "deliani-run-front-power", triggerTime: 18, triggerProgress: nil, eventType: .grantPickup(pickupID: "front-power"), notes: nil),
            LevelEvent(id: "deliani-run-armor", triggerTime: 36, triggerProgress: nil, eventType: .grantPickup(pickupID: "armor-repair"), notes: nil)
        ], nextNodeRules: ["deliani-market-shop"]),
        LevelDefinition(id: "savara-depths", name: "Savara Depths", worldID: "savara", duration: 52, backgroundTheme: "savara-depths", waves: [
            StageSpawn(time: 1.0, archetypeID: "tyrian-scout", lane: 0, count: 7, interval: 0.28, variant: 0),
            StageSpawn(time: 5.8, archetypeID: "savara-diver", lane: 1, count: 5, interval: 0.8, variant: 1),
            StageSpawn(time: 14.0, archetypeID: "tyrian-scout", lane: 4, count: 7, interval: 0.28, variant: 0),
            StageSpawn(time: 22.0, archetypeID: "microsol-interceptor", lane: 2, count: 4, interval: 1.1, variant: 0),
            StageSpawn(time: 30.0, archetypeID: "savara-diver", lane: 3, count: 4, interval: 0.85, variant: -1),
            StageSpawn(time: 39.0, archetypeID: "gyges-gate-drone", lane: 1, count: 2, interval: 1.5, variant: 1)
        ], events: [
            LevelEvent(id: "savara-depths-hazard-current", triggerTime: 16, triggerProgress: nil, eventType: .startHazard(hazardID: "savara-current-band"), notes: nil),
            LevelEvent(id: "savara-depths-shield", triggerTime: 19, triggerProgress: nil, eventType: .grantPickup(pickupID: "shield-restore"), notes: nil),
            LevelEvent(id: "savara-depths-rear-power", triggerTime: 34, triggerProgress: nil, eventType: .grantPickup(pickupID: "rear-power"), notes: nil)
        ], nextNodeRules: ["gyges-prep-shop"]),
        LevelDefinition(id: "gyges-gate", name: "Gyges Gate", worldID: "gyges", duration: 42, backgroundTheme: "gyges", waves: [
            StageSpawn(time: 2.0, archetypeID: "gyges-gate-drone", lane: 1, count: 3, interval: 0.9, variant: 0),
            StageSpawn(time: 7.2, archetypeID: "microsol-interceptor", lane: 3, count: 4, interval: 0.85, variant: -1),
            StageSpawn(time: 15.8, archetypeID: "deliani-tower-turret", lane: 2, count: 2, interval: 1.0, variant: 0),
            StageSpawn(time: 24.2, archetypeID: "gyges-gate-drone", lane: 2, count: 4, interval: 0.8, variant: 1),
            StageSpawn(time: 33.0, archetypeID: "microsol-interceptor", lane: 0, count: 5, interval: 0.6, variant: 1)
        ], events: [
            LevelEvent(id: "gyges-gate-grid", triggerTime: 14, triggerProgress: nil, eventType: .startHazard(hazardID: "gyges-grid"), notes: nil),
            LevelEvent(id: "gyges-gate-sidekick-ammo", triggerTime: 20, triggerProgress: nil, eventType: .grantPickup(pickupID: "sidekick-ammo-small"), notes: nil)
        ], nextNodeRules: ["cube-gyges-lab-intel-node"]),
        LevelDefinition(id: "gyges-boss", name: "Gyges Gate Controller", worldID: "gyges", duration: 64, backgroundTheme: "gyges-boss", waves: [
            StageSpawn(time: 3.0, archetypeID: "gyges-gate-drone", lane: 1, count: 2, interval: 1.0, variant: 0),
            StageSpawn(time: 7.0, archetypeID: "gyges-gate-controller", lane: 2, count: 1, interval: 0.1, variant: 0)
        ], events: [
            LevelEvent(id: "gyges-boss-intro", triggerTime: 7, triggerProgress: nil, eventType: .bossIntro("gyges-gate-controller"), notes: "Boss arrival."),
            LevelEvent(id: "gyges-boss-shield", triggerTime: 12, triggerProgress: nil, eventType: .grantPickup(pickupID: "shield-restore"), notes: nil),
            LevelEvent(id: "gyges-boss-grid", triggerTime: 26, triggerProgress: nil, eventType: .startHazard(hazardID: "gyges-boss-grid"), notes: nil),
            LevelEvent(id: "gyges-boss-front-power", triggerTime: 30, triggerProgress: nil, eventType: .grantPickup(pickupID: "front-power"), notes: nil)
        ], bossID: "gyges-gate-controller", completionRule: .defeatBoss, nextNodeRules: ["episode-slice-end"])
    ]

    static let navNodes: [NavNodeDefinition] = [
        NavNodeDefinition(id: "tyrian-briefing", nodeType: .textIntermission, title: "Tyrian Briefing", worldID: "tyrian", entryConditions: [], outputs: ["tyrian-outskirts"], payloadRef: "briefing.tyrian", notes: "Campaign start."),
        NavNodeDefinition(id: "tyrian-outskirts", nodeType: .mission, title: "Tyrian Outskirts", worldID: "tyrian", entryConditions: [], outputs: ["savara-port-shop"], payloadRef: "tyrian-outskirts", notes: nil),
        NavNodeDefinition(id: "savara-port-shop", nodeType: .shop, title: "Savara Port", worldID: "savara", entryConditions: [], outputs: ["savara-passage"], payloadRef: "savara-port-shop", notes: nil),
        NavNodeDefinition(id: "savara-passage", nodeType: .mission, title: "Savara Passage", worldID: "savara", entryConditions: [], outputs: ["cube-savara-trade-warning-node"], payloadRef: "savara-passage", notes: nil),
        NavNodeDefinition(id: "cube-savara-trade-warning-node", nodeType: .datacube, title: "Datacube: Trade Warning", worldID: "savara", entryConditions: [], outputs: ["branch-savara-or-deliani"], payloadRef: "cube-savara-trade-warning", notes: nil),
        NavNodeDefinition(id: "branch-savara-or-deliani", nodeType: .branch, title: "Route Choice", worldID: nil, entryConditions: [], outputs: ["deliani-run", "savara-depths"], payloadRef: nil, notes: "First branch."),
        NavNodeDefinition(id: "deliani-run", nodeType: .mission, title: "Deliani Run", worldID: "deliani", entryConditions: [], outputs: ["deliani-market-shop"], payloadRef: "deliani-run", notes: nil),
        NavNodeDefinition(id: "deliani-market-shop", nodeType: .shop, title: "Deliani Market", worldID: "deliani", entryConditions: [], outputs: ["gyges-prep-shop"], payloadRef: "deliani-market-shop", notes: nil),
        NavNodeDefinition(id: "savara-depths", nodeType: .mission, title: "Savara Depths", worldID: "savara", entryConditions: [], outputs: ["gyges-prep-shop"], payloadRef: "savara-depths", notes: nil),
        NavNodeDefinition(id: "gyges-prep-shop", nodeType: .shop, title: "Gyges Prep", worldID: "gyges", entryConditions: [], outputs: ["gyges-gate"], payloadRef: "gyges-prep-shop", notes: nil),
        NavNodeDefinition(id: "gyges-gate", nodeType: .mission, title: "Gyges Gate", worldID: "gyges", entryConditions: [], outputs: ["cube-gyges-lab-intel-node"], payloadRef: "gyges-gate", notes: nil),
        NavNodeDefinition(id: "cube-gyges-lab-intel-node", nodeType: .datacube, title: "Datacube: Lab Intel", worldID: "gyges", entryConditions: [], outputs: ["gyges-boss"], payloadRef: "cube-gyges-lab-intel", notes: nil),
        NavNodeDefinition(id: "gyges-boss", nodeType: .mission, title: "Gyges Gate Controller", worldID: "gyges", entryConditions: [], outputs: ["episode-slice-end"], payloadRef: "gyges-boss", notes: nil),
        NavNodeDefinition(id: "episode-slice-end", nodeType: .episodeTransition, title: "Slice Complete", worldID: nil, entryConditions: [], outputs: [], payloadRef: "episode-slice-end", notes: nil)
    ]

    static let datacubes: [DatacubeDefinition] = [
        DatacubeDefinition(id: "cube-savara-trade-warning", title: "Trade Warning", textRef: "Savara remains the only free world in the sector, but Microsol activity is rising around its trade routes. The next route choice determines whether you push toward Deliani's city lanes or stay in Savara's wider corridors.", sourceNodeID: "cube-savara-trade-warning-node", unlockEffects: ["unlock.branch.deliani", "unlock.branch.savara-depths"], sourceStatus: "approximation"),
        DatacubeDefinition(id: "cube-gyges-lab-intel", title: "Lab Intel", textRef: "Gyges is still saturated with Microsol infrastructure. Expect tunnel-gate escorts and a hardened controller platform guarding the facility core. Commit while shields are healthy, then back off to let the generator recover.", sourceNodeID: "cube-gyges-lab-intel-node", unlockEffects: ["hint.gyges-boss"], sourceStatus: "approximation")
    ]

    static let pickups: [PickupDefinition] = [
        PickupDefinition(id: "credits-small", kind: .credits, presentationRef: "credits-small", applyMode: .immediate, value: 25, persistOnFailure: true, notes: "Original spriteSheet11 gem cell."),
        PickupDefinition(id: "front-power", kind: .frontPower, presentationRef: "front-power", applyMode: .immediate, value: 1, persistOnFailure: false, notes: "Original spriteSheet10 powerup cell."),
        PickupDefinition(id: "rear-power", kind: .rearPower, presentationRef: "rear-power", applyMode: .immediate, value: 1, persistOnFailure: false, notes: "Original spriteSheet10 powerup cell."),
        PickupDefinition(id: "armor-repair", kind: .armorRepair, presentationRef: "armor-repair", applyMode: .immediate, value: 20, persistOnFailure: false, notes: "Original spriteSheet11 gem cell."),
        PickupDefinition(id: "shield-restore", kind: .shieldRestore, presentationRef: "shield-restore", applyMode: .immediate, value: 28, persistOnFailure: false, notes: "Original spriteSheet11 gem cell."),
        PickupDefinition(id: "sidekick-ammo-small", kind: .sidekickAmmo, presentationRef: "sidekick-ammo-small", applyMode: .immediate, value: 10, persistOnFailure: false, notes: "Original spriteSheet11 supply cell.")
    ]

    static let shopRules: [ShopInventoryRule] = [
        shopRule(nodeID: "savara-port-shop", itemKind: .ship, itemID: "gencore-phoenix", price: 900),
        shopRule(nodeID: "savara-port-shop", itemKind: .frontWeapon, itemID: "pulse-cannon", price: 220),
        shopRule(nodeID: "savara-port-shop", itemKind: .frontWeapon, itemID: "multi-cannon", price: 360),
        shopRule(nodeID: "savara-port-shop", itemKind: .frontWeapon, itemID: "laser", price: 460),
        shopRule(nodeID: "savara-port-shop", itemKind: .rearWeapon, itemID: "none", price: 0),
        shopRule(nodeID: "savara-port-shop", itemKind: .rearWeapon, itemID: "starburst", price: 200),
        shopRule(nodeID: "savara-port-shop", itemKind: .rearWeapon, itemID: "sonic-wave", price: 340),
        shopRule(nodeID: "savara-port-shop", itemKind: .shield, itemID: "advanced-integrity-field", price: 160),
        shopRule(nodeID: "savara-port-shop", itemKind: .shield, itemID: "gencore-low-energy-shield", price: 310),
        shopRule(nodeID: "savara-port-shop", itemKind: .shield, itemID: "gencore-high-energy-shield", price: 520),
        shopRule(nodeID: "savara-port-shop", itemKind: .generator, itemID: "standard-mr-9", price: 150),
        shopRule(nodeID: "savara-port-shop", itemKind: .generator, itemID: "advanced-mr-12", price: 300),
        shopRule(nodeID: "savara-port-shop", itemKind: .generator, itemID: "gencore-custom-mr-12", price: 500),
        shopRule(nodeID: "savara-port-shop", itemKind: .sidekick, itemID: "single-shot-option", price: 190),
        shopRule(nodeID: "savara-port-shop", itemKind: .sidekick, itemID: "companion-ship-warfly", price: 280),

        shopRule(nodeID: "deliani-market-shop", itemKind: .ship, itemID: "gencore-maelstrom", price: 1450),
        shopRule(nodeID: "deliani-market-shop", itemKind: .ship, itemID: "usp-fang", price: 1280),
        shopRule(nodeID: "deliani-market-shop", itemKind: .frontWeapon, itemID: "zica-laser", price: 620),
        shopRule(nodeID: "deliani-market-shop", itemKind: .frontWeapon, itemID: "vulcan-cannon-front", price: 760),
        shopRule(nodeID: "deliani-market-shop", itemKind: .rearWeapon, itemID: "wild-ball", price: 500),
        shopRule(nodeID: "deliani-market-shop", itemKind: .rearWeapon, itemID: "vulcan-cannon-rear", price: 660),
        shopRule(nodeID: "deliani-market-shop", itemKind: .shield, itemID: "microcorp-lxs-class-a", price: 760),
        shopRule(nodeID: "deliani-market-shop", itemKind: .generator, itemID: "standard-microfusion", price: 720),
        shopRule(nodeID: "deliani-market-shop", itemKind: .sidekick, itemID: "charge-cannon", price: 420),

        shopRule(nodeID: "gyges-prep-shop", itemKind: .frontWeapon, itemID: "lightning-cannon", price: 980),
        shopRule(nodeID: "gyges-prep-shop", itemKind: .shield, itemID: "microcorp-hxs-class-a", price: 980),
        shopRule(nodeID: "gyges-prep-shop", itemKind: .generator, itemID: "advanced-mircofusion", price: 920),
        shopRule(nodeID: "gyges-prep-shop", itemKind: .generator, itemID: "gravitron-pulse-wave", price: 1180),
        shopRule(nodeID: "gyges-prep-shop", itemKind: .sidekick, itemID: "microbomb-ammo-60", price: 520)
    ]

    static let upgradeCatalog = UpgradeCatalog(
        ships: ships,
        frontWeapons: frontWeapons,
        rearWeapons: rearWeapons,
        shields: shields,
        generators: generators,
        sidekicks: sidekicks
    )

    static let catalog = TyrianCatalog(
        ships: ships,
        frontWeapons: frontWeapons,
        rearWeapons: rearWeapons,
        shields: shields,
        generators: generators,
        sidekicks: sidekicks,
        enemies: enemies,
        bossPhases: bossPhases,
        levels: levels,
        navNodes: navNodes,
        datacubes: datacubes,
        shopRules: shopRules,
        pickups: pickups
    )

    static let shipIndex = Dictionary(uniqueKeysWithValues: ships.map { ($0.id, $0) })
    static let frontWeaponIndex = Dictionary(uniqueKeysWithValues: frontWeapons.map { ($0.id, $0) })
    static let rearWeaponIndex = Dictionary(uniqueKeysWithValues: rearWeapons.map { ($0.id, $0) })
    static let shieldIndex = Dictionary(uniqueKeysWithValues: shields.map { ($0.id, $0) })
    static let generatorIndex = Dictionary(uniqueKeysWithValues: generators.map { ($0.id, $0) })
    static let sidekickIndex = Dictionary(uniqueKeysWithValues: sidekicks.map { ($0.id, $0) })
    static let enemyIndex = Dictionary(uniqueKeysWithValues: enemies.map { ($0.id, $0) })
    static let bossPhaseIndex = Dictionary(grouping: bossPhases, by: \.bossID)
    static let levelIndex = Dictionary(uniqueKeysWithValues: levels.map { ($0.id, $0) })
    static let navNodeIndex = Dictionary(uniqueKeysWithValues: navNodes.map { ($0.id, $0) })
    static let datacubeIndex = Dictionary(uniqueKeysWithValues: datacubes.map { ($0.id, $0) })
    static let pickupIndex = Dictionary(uniqueKeysWithValues: pickups.map { ($0.id, $0) })

    private static func powerLevels(from baseMode: WeaponFireMode, arc: Double?) -> [WeaponPowerLevelDefinition] {
        (1...11).map { level in
            let damageScale = 1 + Double(level - 1) * 0.18
            let cadenceScale = max(0.4, 1 - Double(level - 1) * 0.04)
            return WeaponPowerLevelDefinition(
                level: level,
                cooldown: baseMode.cooldown * cadenceScale,
                energyCost: baseMode.energyCost + Double(level - 1) * 0.5,
                damage: baseMode.damage * damageScale,
                speed: baseMode.speed + Double(level - 1) * 12,
                spread: arc ?? baseMode.spread,
                burst: baseMode.burst + (level >= 5 && baseMode.burst > 0 ? 1 : 0)
            )
        }
    }

    private static func shopRule(nodeID: String, itemKind: ShopItemKind, itemID: String, price: Int) -> ShopInventoryRule {
        ShopInventoryRule(
            id: "\(nodeID)-\(itemKind.rawValue)-\(itemID)",
            nodeID: nodeID,
            itemKind: itemKind,
            itemID: itemID,
            availabilityConditions: [],
            basePrice: price,
            priceFormula: nil,
            replacementPolicy: .addToOwnedAndEquip,
            notes: nil
        )
    }
}
