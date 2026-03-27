import Foundation

enum PrototypeData {
    static let frontWeapons: [WeaponArchetype] = [
        WeaponArchetype(
            id: "pulse-lance",
            name: "Pulse Lance",
            slot: .front,
            basePrice: 220,
            colorHex: "#7bf1ff",
            modeA: WeaponFireMode(label: "Stream", cooldown: 0.12, energyCost: 4, damage: 16, speed: 540, spread: 0.06, burst: 1),
            modeB: nil,
            frontArc: 0.1
        ),
        WeaponArchetype(
            id: "split-driver",
            name: "Split Driver",
            slot: .front,
            basePrice: 360,
            colorHex: "#ffd76c",
            modeA: WeaponFireMode(label: "Fork", cooldown: 0.18, energyCost: 7, damage: 14, speed: 510, spread: 0.28, burst: 2),
            modeB: nil,
            frontArc: 0.16
        ),
        WeaponArchetype(
            id: "rail-spike",
            name: "Rail Spike",
            slot: .front,
            basePrice: 520,
            colorHex: "#ff8ab5",
            modeA: WeaponFireMode(label: "Pierce", cooldown: 0.28, energyCost: 10, damage: 38, speed: 660, spread: 0.02, burst: 1),
            modeB: nil,
            frontArc: 0.04
        )
    ]

    static let rearWeapons: [WeaponArchetype] = [
        WeaponArchetype(
            id: "tail-array",
            name: "Tail Array",
            slot: .rear,
            basePrice: 200,
            colorHex: "#a0b7ff",
            modeA: WeaponFireMode(label: "Trace", cooldown: 0.3, energyCost: 7, damage: 18, speed: 430, spread: 0.05, burst: 1),
            modeB: WeaponFireMode(label: "Bloom", cooldown: 0.5, energyCost: 12, damage: 16, speed: 380, spread: 0.42, burst: 3),
            frontArc: nil
        ),
        WeaponArchetype(
            id: "mine-flare",
            name: "Mine Flare",
            slot: .rear,
            basePrice: 340,
            colorHex: "#6dffb2",
            modeA: WeaponFireMode(label: "Drop", cooldown: 0.55, energyCost: 13, damage: 30, speed: 240, spread: 0.03, burst: 1),
            modeB: WeaponFireMode(label: "Spiral", cooldown: 0.45, energyCost: 15, damage: 20, speed: 320, spread: 0.8, burst: 4),
            frontArc: nil
        ),
        WeaponArchetype(
            id: "arc-caster",
            name: "Arc Caster",
            slot: .rear,
            basePrice: 500,
            colorHex: "#ffb866",
            modeA: WeaponFireMode(label: "Volley", cooldown: 0.42, energyCost: 15, damage: 24, speed: 420, spread: 0.22, burst: 2),
            modeB: WeaponFireMode(label: "Needle", cooldown: 0.62, energyCost: 20, damage: 44, speed: 580, spread: 0.04, burst: 1),
            frontArc: nil
        )
    ]

    static let shields: [ShieldArchetype] = [
        ShieldArchetype(id: "mesh-i", name: "Mesh I", basePrice: 160, maxShield: 90, regenPerSecond: 7, regenDelay: 1.7, colorHex: "#78f7ff"),
        ShieldArchetype(id: "mesh-ii", name: "Mesh II", basePrice: 310, maxShield: 130, regenPerSecond: 9, regenDelay: 1.5, colorHex: "#66d6ff"),
        ShieldArchetype(id: "bulwark", name: "Bulwark", basePrice: 520, maxShield: 180, regenPerSecond: 12, regenDelay: 1.3, colorHex: "#8da2ff")
    ]

    static let generators: [GeneratorArchetype] = [
        GeneratorArchetype(id: "reactor-i", name: "Reactor I", basePrice: 150, maxEnergy: 110, regenPerSecond: 34, colorHex: "#a7ff88"),
        GeneratorArchetype(id: "reactor-ii", name: "Reactor II", basePrice: 300, maxEnergy: 145, regenPerSecond: 44, colorHex: "#88ffbd"),
        GeneratorArchetype(id: "reactor-iii", name: "Reactor III", basePrice: 500, maxEnergy: 180, regenPerSecond: 58, colorHex: "#63ffde")
    ]

    static let sidekicks: [SidekickArchetype] = [
        SidekickArchetype(
            id: "empty",
            name: "Empty",
            basePrice: 0,
            colorHex: "#6b7a91",
            fireLane: .left,
            cooldown: 0.8,
            energyCost: 0,
            damage: 0,
            speed: 0,
            spread: 0,
            burst: 0,
            orbitRadius: 34
        ),
        SidekickArchetype(
            id: "mirror-drone",
            name: "Mirror Drone",
            basePrice: 190,
            colorHex: "#7affd9",
            fireLane: .left,
            cooldown: 0.4,
            energyCost: 9,
            damage: 16,
            speed: 470,
            spread: 0.08,
            burst: 1,
            orbitRadius: 42
        ),
        SidekickArchetype(
            id: "orbit-gun",
            name: "Orbit Gun",
            basePrice: 280,
            colorHex: "#ffe570",
            fireLane: .left,
            cooldown: 0.6,
            energyCost: 12,
            damage: 18,
            speed: 420,
            spread: 0.2,
            burst: 2,
            orbitRadius: 54
        ),
        SidekickArchetype(
            id: "lance-pod",
            name: "Lance Pod",
            basePrice: 420,
            colorHex: "#ff8cc5",
            fireLane: .left,
            cooldown: 0.85,
            energyCost: 16,
            damage: 36,
            speed: 560,
            spread: 0.05,
            burst: 1,
            orbitRadius: 58
        )
    ]

    static let enemyArchetypes: [EnemyArchetype] = [
        EnemyArchetype(
            id: "dart",
            name: "Dart",
            behavior: .straight,
            firePattern: .none,
            speed: 110,
            hp: 28,
            radius: 14,
            reward: 22,
            colorHex: "#7ee7ff",
            contactDamage: 18,
            fireCooldown: 99,
            projectileSpeed: 0
        ),
        EnemyArchetype(
            id: "waver",
            name: "Waver",
            behavior: .sine,
            firePattern: .aimed,
            speed: 96,
            hp: 46,
            radius: 17,
            reward: 34,
            colorHex: "#ffd670",
            contactDamage: 24,
            fireCooldown: 1.35,
            projectileSpeed: 190
        ),
        EnemyArchetype(
            id: "lancer",
            name: "Lancer",
            behavior: .dive,
            firePattern: .spread,
            speed: 132,
            hp: 64,
            radius: 18,
            reward: 48,
            colorHex: "#ff8ab3",
            contactDamage: 30,
            fireCooldown: 1.9,
            projectileSpeed: 210
        ),
        EnemyArchetype(
            id: "vault-core",
            name: "Vault Core",
            behavior: .boss,
            firePattern: .boss,
            speed: 38,
            hp: 960,
            radius: 38,
            reward: 420,
            colorHex: "#9ba9ff",
            contactDamage: 40,
            fireCooldown: 0.6,
            projectileSpeed: 220
        )
    ]

    static let catalog = UpgradeCatalog(
        frontWeapons: frontWeapons,
        rearWeapons: rearWeapons,
        shields: shields,
        generators: generators,
        sidekicks: sidekicks
    )

    static let stage = StageDefinition(
        id: "glass-run",
        name: "Glass Run",
        duration: 64,
        spawns: [
            StageSpawn(time: 1.5, archetypeID: "dart", lane: 0, count: 5, interval: 0.4, variant: 0),
            StageSpawn(time: 5.2, archetypeID: "dart", lane: 4, count: 5, interval: 0.4, variant: 0),
            StageSpawn(time: 10.5, archetypeID: "waver", lane: 1, count: 3, interval: 0.9, variant: -1),
            StageSpawn(time: 14.2, archetypeID: "waver", lane: 3, count: 3, interval: 0.9, variant: 1),
            StageSpawn(time: 20.5, archetypeID: "dart", lane: 2, count: 8, interval: 0.28, variant: 0),
            StageSpawn(time: 27.4, archetypeID: "lancer", lane: 0, count: 2, interval: 1.8, variant: 1),
            StageSpawn(time: 29.8, archetypeID: "lancer", lane: 4, count: 2, interval: 1.8, variant: -1),
            StageSpawn(time: 35.4, archetypeID: "waver", lane: 2, count: 4, interval: 0.7, variant: 1),
            StageSpawn(time: 42.4, archetypeID: "dart", lane: 0, count: 10, interval: 0.2, variant: 0),
            StageSpawn(time: 45.6, archetypeID: "dart", lane: 4, count: 10, interval: 0.2, variant: 0),
            StageSpawn(time: 52.8, archetypeID: "vault-core", lane: 2, count: 1, interval: 0.1, variant: 0)
        ]
    )

    static let enemyIndex = Dictionary(uniqueKeysWithValues: enemyArchetypes.map { ($0.id, $0) })
    static let frontWeaponIndex = Dictionary(uniqueKeysWithValues: frontWeapons.map { ($0.id, $0) })
    static let rearWeaponIndex = Dictionary(uniqueKeysWithValues: rearWeapons.map { ($0.id, $0) })
    static let shieldIndex = Dictionary(uniqueKeysWithValues: shields.map { ($0.id, $0) })
    static let generatorIndex = Dictionary(uniqueKeysWithValues: generators.map { ($0.id, $0) })
    static let sidekickIndex = Dictionary(uniqueKeysWithValues: sidekicks.map { ($0.id, $0) })
}
