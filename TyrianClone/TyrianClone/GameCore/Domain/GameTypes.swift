import CoreGraphics
import Foundation

enum UpgradeSlot: String, CaseIterable, Identifiable {
    case ship
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

enum CampaignDifficulty: String, CaseIterable, Identifiable {
    case easy
    case normal
    case hard
    case impossible

    var id: String { rawValue }
}

enum CampaignNodeType: String, CaseIterable {
    case mission
    case shop
    case datacube
    case textIntermission
    case branch
    case episodeTransition
    case campaignEnd
}

enum ContinuePolicy: String {
    case safeNodeRetry
    case immediateRetry
}

enum LevelCompletionRule: String {
    case surviveDuration
    case defeatBoss
    case clearAllWaves
    case scripted
}

enum PickupKind: String {
    case credits
    case datacube
    case frontPower
    case rearPower
    case armorRepair
    case shieldRestore
    case sidekickAmmo
    case scriptedItem
}

enum PickupApplyMode: String {
    case immediate
    case bankOnMissionEnd
    case scripted
}

enum ShopItemKind: String {
    case ship
    case frontWeapon
    case rearWeapon
    case shield
    case generator
    case sidekick
    case frontPowerUpgrade
    case rearPowerUpgrade
}

enum InventoryReplacementPolicy: String {
    case replaceEquipped
    case addToOwnedAndEquip
    case addToOwnedOnly
}

enum SidekickMountBehavior: String {
    case attached
    case followerTurning
    case forwardMounted
    case followerStatic
    case orbiting
}

enum SidekickBehaviorClass: String {
    case linkedFire
    case chargeUp
    case independentFire
    case ammoLimited
}

enum EnemyTaxonomy: String {
    case fodder
    case formation
    case aimedFire
    case pathing
    case hazard
    case miniboss
    case boss
}

enum EnemyMovementPattern: String {
    case straight
    case sine
    case dive
    case scripted
    case boss
}

enum EnemyAttackPattern: String {
    case none
    case aimed
    case spread
    case boss
    case scripted
}

typealias EnemyBehavior = EnemyMovementPattern
typealias EnemyFirePattern = EnemyAttackPattern

enum EffectKind: String {
    case burst
    case ring
    case flash
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

struct WeaponPowerLevelDefinition: Equatable, Identifiable {
    let level: Int
    let cooldown: Double
    let energyCost: Double
    let damage: Double
    let speed: Double
    let spread: Double
    let burst: Int

    var id: Int { level }
}

struct WeaponPortDefinition: Equatable, Identifiable {
    let id: String
    let name: String
    let slot: UpgradeSlot
    let sourceStatus: String
    let basePrice: Int
    let colorHex: String
    let modeA: WeaponFireMode
    let modeB: WeaponFireMode?
    let frontArc: Double?
    let powerLevels: [WeaponPowerLevelDefinition]
    let itemGraphicRef: String?
    let notes: String?

    init(
        id: String,
        name: String,
        slot: UpgradeSlot,
        sourceStatus: String = "prototype",
        basePrice: Int,
        colorHex: String,
        modeA: WeaponFireMode,
        modeB: WeaponFireMode? = nil,
        frontArc: Double? = nil,
        powerLevels: [WeaponPowerLevelDefinition] = [],
        itemGraphicRef: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.slot = slot
        self.sourceStatus = sourceStatus
        self.basePrice = basePrice
        self.colorHex = colorHex
        self.modeA = modeA
        self.modeB = modeB
        self.frontArc = frontArc
        self.powerLevels = powerLevels
        self.itemGraphicRef = itemGraphicRef
        self.notes = notes
    }
}

typealias WeaponArchetype = WeaponPortDefinition

struct ShieldDefinition: Equatable, Identifiable {
    let id: String
    let name: String
    let sourceStatus: String
    let basePrice: Int
    let maxShield: Double
    let regenPerSecond: Double
    let regenDelay: Double
    let generatorDemand: Double?
    let colorHex: String
    let notes: String?

    init(
        id: String,
        name: String,
        sourceStatus: String = "prototype",
        basePrice: Int,
        maxShield: Double,
        regenPerSecond: Double,
        regenDelay: Double,
        generatorDemand: Double? = nil,
        colorHex: String,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sourceStatus = sourceStatus
        self.basePrice = basePrice
        self.maxShield = maxShield
        self.regenPerSecond = regenPerSecond
        self.regenDelay = regenDelay
        self.generatorDemand = generatorDemand
        self.colorHex = colorHex
        self.notes = notes
    }
}

typealias ShieldArchetype = ShieldDefinition

struct GeneratorDefinition: Equatable, Identifiable {
    let id: String
    let name: String
    let sourceStatus: String
    let basePrice: Int
    let maxEnergy: Double
    let regenPerSecond: Double
    let colorHex: String
    let notes: String?

    init(
        id: String,
        name: String,
        sourceStatus: String = "prototype",
        basePrice: Int,
        maxEnergy: Double,
        regenPerSecond: Double,
        colorHex: String,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sourceStatus = sourceStatus
        self.basePrice = basePrice
        self.maxEnergy = maxEnergy
        self.regenPerSecond = regenPerSecond
        self.colorHex = colorHex
        self.notes = notes
    }
}

typealias GeneratorArchetype = GeneratorDefinition

struct SidekickDefinition: Equatable, Identifiable {
    let id: String
    let name: String
    let sourceStatus: String
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
    let mountBehavior: SidekickMountBehavior
    let behaviorClass: SidekickBehaviorClass
    let ammoCapacity: Int?
    let chargeStages: Int?
    let notes: String?

    init(
        id: String,
        name: String,
        sourceStatus: String = "prototype",
        basePrice: Int,
        colorHex: String,
        fireLane: SidekickFireLane,
        cooldown: Double,
        energyCost: Double,
        damage: Double,
        speed: Double,
        spread: Double,
        burst: Int,
        orbitRadius: Double,
        mountBehavior: SidekickMountBehavior = .orbiting,
        behaviorClass: SidekickBehaviorClass = .linkedFire,
        ammoCapacity: Int? = nil,
        chargeStages: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sourceStatus = sourceStatus
        self.basePrice = basePrice
        self.colorHex = colorHex
        self.fireLane = fireLane
        self.cooldown = cooldown
        self.energyCost = energyCost
        self.damage = damage
        self.speed = speed
        self.spread = spread
        self.burst = burst
        self.orbitRadius = orbitRadius
        self.mountBehavior = mountBehavior
        self.behaviorClass = behaviorClass
        self.ammoCapacity = ammoCapacity
        self.chargeStages = chargeStages
        self.notes = notes
    }
}

typealias SidekickArchetype = SidekickDefinition

struct ShipDefinition: Equatable, Identifiable {
    let id: String
    let name: String
    let sourceStatus: String
    let armorCapacity: Double
    let speedBand: Double
    let shopCost: Int
    let unlockRule: String?
    let notes: String?
}

struct EnemyDefinition: Equatable, Identifiable {
    let id: String
    let name: String
    let sourceStatus: String
    let taxonomy: EnemyTaxonomy
    let behavior: EnemyMovementPattern
    let firePattern: EnemyAttackPattern
    let speed: Double
    let hp: Double
    let radius: Double
    let reward: Int
    let colorHex: String
    let contactDamage: Double
    let fireCooldown: Double
    let projectileSpeed: Double
    let notes: String?

    init(
        id: String,
        name: String,
        sourceStatus: String = "prototype",
        taxonomy: EnemyTaxonomy = .fodder,
        behavior: EnemyMovementPattern,
        firePattern: EnemyAttackPattern,
        speed: Double,
        hp: Double,
        radius: Double,
        reward: Int,
        colorHex: String,
        contactDamage: Double,
        fireCooldown: Double,
        projectileSpeed: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sourceStatus = sourceStatus
        self.taxonomy = taxonomy
        self.behavior = behavior
        self.firePattern = firePattern
        self.speed = speed
        self.hp = hp
        self.radius = radius
        self.reward = reward
        self.colorHex = colorHex
        self.contactDamage = contactDamage
        self.fireCooldown = fireCooldown
        self.projectileSpeed = projectileSpeed
        self.notes = notes
    }
}

typealias EnemyArchetype = EnemyDefinition

struct BossPhaseDefinition: Equatable, Identifiable {
    let id: String
    let bossID: String
    let phaseIndex: Int
    let minHealthRatio: Double
    let maxHealthRatio: Double
    let movementPattern: String
    let attackSet: [String]
    let horizontalAmplitude: Double
    let fireCooldownMultiplier: Double
    let projectileSpeedBonus: Double
    let burstBonus: Int
    let weakPointOffsets: [CGPoint]
    let rewardTrigger: String?
}

struct WaveDefinition: Equatable, Identifiable {
    let id: String
    let enemyIDs: [String]
    let entryPattern: String
    let spawnOffsets: [Double]
    let dropOverride: String?
    let difficultyModifiers: [String]
}

struct LevelEvent: Equatable, Identifiable {
    enum EventType: Equatable {
        case spawnWave(waveID: String)
        case grantPickup(pickupID: String)
        case revealDatacube(datacubeID: String)
        case startHazard(hazardID: String)
        case setFlag(String)
        case bossIntro(String)
        case scripted(String)
    }

    let id: String
    let triggerTime: Double?
    let triggerProgress: Double?
    let eventType: EventType
    let notes: String?
}

struct LevelDefinition: Equatable, Identifiable {
    let id: String
    let name: String
    let worldID: String?
    let duration: Double
    let backgroundTheme: String?
    let waves: [StageSpawn]
    let events: [LevelEvent]
    let bossID: String?
    let completionRule: LevelCompletionRule
    let rewardProfile: String?
    let nextNodeRules: [String]

    var spawns: [StageSpawn] {
        waves
    }

    init(
        id: String,
        name: String,
        worldID: String? = nil,
        duration: Double,
        backgroundTheme: String? = nil,
        waves: [StageSpawn] = [],
        events: [LevelEvent] = [],
        bossID: String? = nil,
        completionRule: LevelCompletionRule = .surviveDuration,
        rewardProfile: String? = nil,
        nextNodeRules: [String] = []
    ) {
        self.id = id
        self.name = name
        self.worldID = worldID
        self.duration = duration
        self.backgroundTheme = backgroundTheme
        self.waves = waves
        self.events = events
        self.bossID = bossID
        self.completionRule = completionRule
        self.rewardProfile = rewardProfile
        self.nextNodeRules = nextNodeRules
    }

    init(
        id: String,
        name: String,
        duration: Double,
        spawns: [StageSpawn]
    ) {
        self.init(
            id: id,
            name: name,
            worldID: nil,
            duration: duration,
            backgroundTheme: nil,
            waves: spawns,
            events: [],
            bossID: nil,
            completionRule: .surviveDuration,
            rewardProfile: nil,
            nextNodeRules: []
        )
    }
}

typealias StageDefinition = LevelDefinition

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

struct NavNodeDefinition: Equatable, Identifiable {
    let id: String
    let nodeType: CampaignNodeType
    let title: String
    let worldID: String?
    let entryConditions: [String]
    let outputs: [String]
    let payloadRef: String?
    let notes: String?
}

struct DatacubeDefinition: Equatable, Identifiable {
    let id: String
    let title: String
    let textRef: String
    let sourceNodeID: String
    let unlockEffects: [String]
    let sourceStatus: String
}

struct PickupDefinition: Equatable, Identifiable {
    let id: String
    let kind: PickupKind
    let presentationRef: String?
    let applyMode: PickupApplyMode
    let value: Int?
    let persistOnFailure: Bool
    let notes: String?
}

struct ShopInventoryRule: Equatable, Identifiable {
    let id: String
    let nodeID: String
    let itemKind: ShopItemKind
    let itemID: String
    let availabilityConditions: [String]
    let basePrice: Int
    let priceFormula: String?
    let replacementPolicy: InventoryReplacementPolicy
    let notes: String?
}

struct TyrianCatalog: Equatable {
    let ships: [ShipDefinition]
    let frontWeapons: [WeaponPortDefinition]
    let rearWeapons: [WeaponPortDefinition]
    let shields: [ShieldDefinition]
    let generators: [GeneratorDefinition]
    let sidekicks: [SidekickDefinition]
    let enemies: [EnemyDefinition]
    let bossPhases: [BossPhaseDefinition]
    let levels: [LevelDefinition]
    let navNodes: [NavNodeDefinition]
    let datacubes: [DatacubeDefinition]
    let shopRules: [ShopInventoryRule]
    let pickups: [PickupDefinition]
}

struct UpgradeCatalog: Equatable {
    let ships: [ShipDefinition]
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
