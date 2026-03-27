import Foundation

struct PlayerLoadout: Equatable {
    var frontWeaponID: String
    var rearWeaponID: String
    var shieldID: String
    var generatorID: String
    var leftSidekickID: String
    var rightSidekickID: String
    var frontPower: Int
    var rearPower: Int
    var rearModeIndex: Int
}

struct RunState: Equatable {
    var sortie: Int
    var credits: Int
    var earnedThisSortie: Int
    var loadout: PlayerLoadout

    static let `default` = RunState(
        sortie: 1,
        credits: 680,
        earnedThisSortie: 0,
        loadout: PlayerLoadout(
            frontWeaponID: "pulse-lance",
            rearWeaponID: "tail-array",
            shieldID: "mesh-i",
            generatorID: "reactor-i",
            leftSidekickID: "empty",
            rightSidekickID: "empty",
            frontPower: 1,
            rearPower: 1,
            rearModeIndex: 0
        )
    )
}

struct PlayerState: Equatable {
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
    var invulnerability: Double
    var rearModeIndex: Int
}

struct EnemyState: Equatable, Identifiable {
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

struct StageOutcome: Equatable {
    enum Kind {
        case cleared
        case destroyed
    }

    let kind: Kind
    let earned: Int
    let totalCredits: Int
    let sortie: Int
}
