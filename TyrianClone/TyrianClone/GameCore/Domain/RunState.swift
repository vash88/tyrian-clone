import Foundation

struct PlayerLoadout: Equatable {
    var shipID: String
    var frontWeaponID: String
    var rearWeaponID: String
    var shieldID: String
    var generatorID: String
    var leftSidekickID: String
    var rightSidekickID: String
    var specialID: String
    var frontPower: Int
    var rearPower: Int
    var rearModeIndex: Int

    init(
        shipID: String = "usp-talon",
        frontWeaponID: String,
        rearWeaponID: String,
        shieldID: String,
        generatorID: String,
        leftSidekickID: String,
        rightSidekickID: String,
        specialID: String = "none",
        frontPower: Int,
        rearPower: Int,
        rearModeIndex: Int
    ) {
        self.shipID = shipID
        self.frontWeaponID = frontWeaponID
        self.rearWeaponID = rearWeaponID
        self.shieldID = shieldID
        self.generatorID = generatorID
        self.leftSidekickID = leftSidekickID
        self.rightSidekickID = rightSidekickID
        self.specialID = specialID
        self.frontPower = frontPower
        self.rearPower = rearPower
        self.rearModeIndex = rearModeIndex
    }
}

struct CampaignState: Equatable {
    var campaignID: String
    var episodeID: String
    var currentNodeID: String
    var visitedNodeIDs: [String]
    var completedMissionIDs: [String]
    var failedMissionIDs: [String]
    var unlockedNodeIDs: [String]
    var ownedItemIDs: [String]
    var datacubeIDs: [String]
    var campaignFlags: [String]
    var continuePolicy: ContinuePolicy
    var difficulty: CampaignDifficulty
    var sortie: Int
    var credits: Int
    var earnedThisSortie: Int
    var loadout: PlayerLoadout

    static let `default` = CampaignState(
        campaignID: "full-game-first-pass",
        episodeID: "episode-1-slice",
        currentNodeID: "tyrian-briefing",
        visitedNodeIDs: ["tyrian-briefing"],
        completedMissionIDs: [],
        failedMissionIDs: [],
        unlockedNodeIDs: ["tyrian-briefing", "tyrian-outskirts"],
        ownedItemIDs: ["usp-talon", "pulse-cannon", "none", "gencore-high-energy-shield", "advanced-mr-12", "empty"],
        datacubeIDs: [],
        campaignFlags: [],
        continuePolicy: .safeNodeRetry,
        difficulty: .normal,
        sortie: 1,
        credits: 680,
        earnedThisSortie: 0,
        loadout: PlayerLoadout(
            shipID: "usp-talon",
            frontWeaponID: "pulse-cannon",
            rearWeaponID: "none",
            shieldID: "gencore-high-energy-shield",
            generatorID: "advanced-mr-12",
            leftSidekickID: "empty",
            rightSidekickID: "empty",
            specialID: "none",
            frontPower: 1,
            rearPower: 1,
            rearModeIndex: 0
        )
    )
}

typealias RunState = CampaignState

struct MissionState: Equatable {
    enum Status: Equatable {
        case briefing
        case inProgress
        case cleared
        case destroyed
        case aborted
    }

    var missionID: String
    var sourceNodeID: String
    var elapsedTime: Double
    var scrollProgress: Double
    var player: PlayerCombatState
    var activeEnemies: [EnemyInstanceState]
    var activeProjectiles: [ProjectileState]
    var activeCreditPickups: [CreditPickupState]
    var activeEffects: [EffectState]
    var rewardBufferCredits: Int
    var rewardBufferDatacubeIDs: [String]
    var status: Status
}

struct PlayerCombatState: Equatable {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var armor: Double
    var maxArmor: Double
    var shield: Double
    var maxShield: Double
    var shieldRegenPerSecond: Double
    var shieldRegenDelay: Double
    var shieldRegenCooldown: Double
    var energy: Double
    var maxEnergy: Double
    var energyRegenPerSecond: Double
    var frontCooldown: Double
    var rearCooldown: Double
    var leftSidekickCooldown: Double
    var rightSidekickCooldown: Double
    var leftSidekickAmmo: Int?
    var rightSidekickAmmo: Int?
    var leftSidekickCharge: Double
    var rightSidekickCharge: Double
    var invulnerability: Double
    var rearModeIndex: Int
}

typealias PlayerState = PlayerCombatState

struct EnemyInstanceState: Equatable, Identifiable {
    let id: Int
    let archetypeID: String
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var hp: Double
    var radius: Double
    var reward: Int
    var contactDamage: Double
    var elapsed: Double
    var fireCooldown: Double
    var variant: Double
}

typealias EnemyState = EnemyInstanceState

struct ProjectileState: Equatable, Identifiable {
    enum Owner {
        case player
        case enemy
    }

    let id: Int
    let owner: Owner
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var damage: Double
    var radius: Double
    var colorHex: String
    var life: Double
}

struct CreditPickupState: Equatable, Identifiable {
    let id: Int
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var value: Int
    var radius: Double
    var age: Double
}

struct MissionPickupState: Equatable, Identifiable {
    let id: Int
    let pickupID: String
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var radius: Double
    var age: Double
}

struct HazardState: Equatable, Identifiable {
    let id: Int
    let hazardID: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var vx: Double
    var vy: Double
    var damagePerSecond: Double
    var age: Double
    var life: Double
}

struct EffectState: Equatable, Identifiable {
    let id: Int
    let kind: EffectKind
    var x: Double
    var y: Double
    var colorHex: String
    var life: Double
    var maxLife: Double
    var radius: Double
}

struct WaveCursor: Equatable {
    let stageSpawn: StageSpawn
    var spawned: Int
}

struct MissionOutcome: Equatable {
    enum Kind {
        case cleared
        case destroyed
    }

    let kind: Kind
    let earned: Int
    let totalCredits: Int
    let sortie: Int
    let missionID: String?
    let nodeID: String?
    let frontPowerReward: Int
    let rearPowerReward: Int

    init(
        kind: Kind,
        earned: Int,
        totalCredits: Int,
        sortie: Int,
        missionID: String? = nil,
        nodeID: String? = nil,
        frontPowerReward: Int = 0,
        rearPowerReward: Int = 0
    ) {
        self.kind = kind
        self.earned = earned
        self.totalCredits = totalCredits
        self.sortie = sortie
        self.missionID = missionID
        self.nodeID = nodeID
        self.frontPowerReward = frontPowerReward
        self.rearPowerReward = rearPowerReward
    }
}

typealias StageOutcome = MissionOutcome
