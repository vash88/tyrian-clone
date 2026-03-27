import Foundation

enum UpgradeSlot: String, CaseIterable, Identifiable {
    case front
    case rear
    case shield
    case generator
    case leftSidekick
    case rightSidekick

    var id: String { rawValue }
}

enum SidekickFireLane: String {
    case left
    case right
}

enum EnemyBehavior: String {
    case straight
    case sine
    case dive
    case boss
}

enum EnemyFirePattern: String {
    case none
    case aimed
    case spread
    case boss
}

enum EffectKind: String {
    case burst
    case ring
    case flash
}

struct StageSpawn: Identifiable, Equatable {
    let time: Double
    let archetypeID: String
    let lane: Int
    let count: Int
    let interval: Double
    let variant: Double

    var id: String {
        "\(archetypeID)-\(time)-\(lane)-\(count)"
    }
}

struct StageDefinition: Equatable {
    let id: String
    let name: String
    let duration: Double
    let spawns: [StageSpawn]
}

struct EnemyArchetype: Equatable, Identifiable {
    let id: String
    let name: String
    let behavior: EnemyBehavior
    let firePattern: EnemyFirePattern
    let speed: Double
    let hp: Double
    let radius: Double
    let reward: Int
    let colorHex: String
    let contactDamage: Double
    let fireCooldown: Double
    let projectileSpeed: Double
}

struct WeaponFireMode: Equatable {
    let label: String
    let cooldown: Double
    let energyCost: Double
    let damage: Double
    let speed: Double
    let spread: Double
    let burst: Int
}

struct WeaponArchetype: Equatable, Identifiable {
    let id: String
    let name: String
    let slot: UpgradeSlot
    let basePrice: Int
    let colorHex: String
    let modeA: WeaponFireMode
    let modeB: WeaponFireMode?
    let frontArc: Double?
}

struct ShieldArchetype: Equatable, Identifiable {
    let id: String
    let name: String
    let basePrice: Int
    let maxShield: Double
    let regenPerSecond: Double
    let regenDelay: Double
    let colorHex: String
}

struct GeneratorArchetype: Equatable, Identifiable {
    let id: String
    let name: String
    let basePrice: Int
    let maxEnergy: Double
    let regenPerSecond: Double
    let colorHex: String
}

struct SidekickArchetype: Equatable, Identifiable {
    let id: String
    let name: String
    let basePrice: Int
    let colorHex: String
    let fireLane: SidekickFireLane
    let cooldown: Double
    let energyCost: Double
    let damage: Double
    let speed: Double
    let spread: Double
    let burst: Int
    let orbitRadius: Double
}

struct UpgradeCatalog: Equatable {
    let frontWeapons: [WeaponArchetype]
    let rearWeapons: [WeaponArchetype]
    let shields: [ShieldArchetype]
    let generators: [GeneratorArchetype]
    let sidekicks: [SidekickArchetype]
}

struct ShopSection<Item> {
    let title: String
    let slot: UpgradeSlot
    let currentID: String
    let items: [Item]
}
