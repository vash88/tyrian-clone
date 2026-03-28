import CoreGraphics
import Foundation

struct RenderSnapshot: Equatable {
    struct PlayerSprite: Equatable {
        var position: CGPoint
        var frontWeaponColorHex: String
        var shieldColorHex: String
        var shieldActive: Bool
        var invulnerability: Double
    }

    struct SidekickSprite: Equatable, Identifiable {
        let id: String
        var position: CGPoint
        var colorHex: String
    }

    struct EnemySprite: Equatable, Identifiable {
        let id: Int
        var position: CGPoint
        var radius: Double
        var colorHex: String
        var isBoss: Bool
    }

    struct ProjectileSprite: Equatable, Identifiable {
        let id: Int
        var position: CGPoint
        var radius: Double
        var colorHex: String
        var isPlayerOwned: Bool
    }

    struct CreditSprite: Equatable, Identifiable {
        let id: Int
        var position: CGPoint
    }

    struct PickupSprite: Equatable, Identifiable {
        let id: Int
        var position: CGPoint
        var kind: PickupKind
    }

    struct HazardSprite: Equatable, Identifiable {
        let id: Int
        var frame: CGRect
        var colorHex: String
    }

    struct WeakPointSprite: Equatable, Identifiable {
        let id: String
        var position: CGPoint
        var colorHex: String
    }

    struct EffectSprite: Equatable, Identifiable {
        let id: Int
        var kind: EffectKind
        var position: CGPoint
        var colorHex: String
        var life: Double
        var maxLife: Double
        var radius: Double
    }

    var worldSize: CGSize
    var stageTime: Double
    var player: PlayerSprite?
    var sidekicks: [SidekickSprite]
    var enemies: [EnemySprite]
    var projectiles: [ProjectileSprite]
    var credits: [CreditSprite]
    var pickups: [PickupSprite]
    var hazards: [HazardSprite]
    var bossWeakPoints: [WeakPointSprite]
    var effects: [EffectSprite]
    var bossLineColorHex: String?

    static let empty = RenderSnapshot(
        worldSize: CGSize(width: Simulation.worldWidth, height: Simulation.worldHeight),
        stageTime: 0,
        player: nil,
        sidekicks: [],
        enemies: [],
        projectiles: [],
        credits: [],
        pickups: [],
        hazards: [],
        bossWeakPoints: [],
        effects: [],
        bossLineColorHex: nil
    )

    static func preview(from runState: RunState) -> RenderSnapshot {
        let frontWeapon = PrototypeData.frontWeaponIndex[runState.loadout.frontWeaponID] ?? PrototypeData.frontWeapons[0]
        let rearWeapon = PrototypeData.rearWeaponIndex[runState.loadout.rearWeaponID] ?? PrototypeData.rearWeapons[0]
        let shield = PrototypeData.shieldIndex[runState.loadout.shieldID] ?? PrototypeData.shields[0]
        let leftSidekick = PrototypeData.sidekickIndex[runState.loadout.leftSidekickID] ?? PrototypeData.sidekicks[0]
        let rightSidekick = PrototypeData.sidekickIndex[runState.loadout.rightSidekickID] ?? PrototypeData.sidekicks[0]

        let playerPosition = CGPoint(x: Simulation.worldWidth / 2, y: Simulation.worldHeight - Simulation.bottomSheetPadding - 18)
        var sidekicks: [SidekickSprite] = []

        if leftSidekick.id != "empty" {
            sidekicks.append(
                SidekickSprite(
                    id: "left-preview",
                    position: CGPoint(x: playerPosition.x - leftSidekick.orbitRadius * 0.8, y: playerPosition.y + 10),
                    colorHex: leftSidekick.colorHex
                )
            )
        }

        if rightSidekick.id != "empty" {
            sidekicks.append(
                SidekickSprite(
                    id: "right-preview",
                    position: CGPoint(x: playerPosition.x + rightSidekick.orbitRadius * 0.8, y: playerPosition.y + 10),
                    colorHex: rightSidekick.colorHex
                )
            )
        }

        return RenderSnapshot(
            worldSize: CGSize(width: Simulation.worldWidth, height: Simulation.worldHeight),
            stageTime: 9.5,
            player: PlayerSprite(
                position: playerPosition,
                frontWeaponColorHex: frontWeapon.colorHex,
                shieldColorHex: shield.colorHex,
                shieldActive: true,
                invulnerability: 0
            ),
            sidekicks: sidekicks,
            enemies: [
                EnemySprite(id: 1, position: CGPoint(x: 88, y: 160), radius: 14, colorHex: "#7ee7ff", isBoss: false),
                EnemySprite(id: 2, position: CGPoint(x: 180, y: 220), radius: 17, colorHex: "#ffd670", isBoss: false),
                EnemySprite(id: 3, position: CGPoint(x: 278, y: 128), radius: 18, colorHex: "#ff8ab3", isBoss: false)
            ],
            projectiles: [
                ProjectileSprite(id: 10, position: CGPoint(x: playerPosition.x, y: 380), radius: 5, colorHex: frontWeapon.colorHex, isPlayerOwned: true),
                ProjectileSprite(id: 11, position: CGPoint(x: playerPosition.x - 14, y: 408), radius: 5, colorHex: frontWeapon.colorHex, isPlayerOwned: true),
                ProjectileSprite(id: 12, position: CGPoint(x: 178, y: 290), radius: 6, colorHex: rearWeapon.colorHex, isPlayerOwned: false)
            ],
            credits: [
                CreditSprite(id: 20, position: CGPoint(x: 132, y: 332)),
                CreditSprite(id: 21, position: CGPoint(x: 236, y: 298))
            ],
            pickups: [
                PickupSprite(id: 40, position: CGPoint(x: 186, y: 260), kind: .frontPower)
            ],
            hazards: [
                HazardSprite(id: 50, frame: CGRect(x: 72, y: 196, width: 216, height: 20), colorHex: "#9ba9ff")
            ],
            bossWeakPoints: [
                WeakPointSprite(id: "preview-weakpoint", position: CGPoint(x: 278, y: 128), colorHex: "#ff8ab3")
            ],
            effects: [
                EffectSprite(id: 30, kind: .ring, position: CGPoint(x: 180, y: 220), colorHex: "#ffffff", life: 0.4, maxLife: 1, radius: 24),
                EffectSprite(id: 31, kind: .flash, position: CGPoint(x: playerPosition.x, y: 408), colorHex: frontWeapon.colorHex, life: 0.6, maxLife: 1, radius: 12)
            ],
            bossLineColorHex: nil
        )
    }
}

struct HUDSnapshot: Equatable {
    var stageTime: Double
    var stageDuration: Double
    var shipName: String
    var armor: Double
    var maxArmor: Double
    var shield: Double
    var maxShield: Double
    var generatorName: String
    var energy: Double
    var maxEnergy: Double
    var rearModeLabel: String
    var frontName: String
    var frontPower: Int
    var rearName: String
    var rearPower: Int
    var leftSidekickName: String
    var rightSidekickName: String
    var leftSidekickAmmo: Int?
    var rightSidekickAmmo: Int?

    static func idle(from runState: RunState, stageDuration: Double) -> HUDSnapshot {
        let ship = TyrianCatalogData.shipIndex[runState.loadout.shipID] ?? TyrianCatalogData.ships[0]
        let front = PrototypeData.frontWeaponIndex[runState.loadout.frontWeaponID] ?? PrototypeData.frontWeapons[0]
        let rear = PrototypeData.rearWeaponIndex[runState.loadout.rearWeaponID] ?? PrototypeData.rearWeapons[0]
        let shield = PrototypeData.shieldIndex[runState.loadout.shieldID] ?? PrototypeData.shields[0]
        let generator = PrototypeData.generatorIndex[runState.loadout.generatorID] ?? PrototypeData.generators[0]
        let left = PrototypeData.sidekickIndex[runState.loadout.leftSidekickID] ?? PrototypeData.sidekicks[0]
        let right = PrototypeData.sidekickIndex[runState.loadout.rightSidekickID] ?? PrototypeData.sidekicks[0]

        return HUDSnapshot(
            stageTime: 0,
            stageDuration: stageDuration,
            shipName: ship.name,
            armor: ship.armorCapacity,
            maxArmor: ship.armorCapacity,
            shield: shield.maxShield,
            maxShield: shield.maxShield,
            generatorName: generator.name,
            energy: generator.maxEnergy,
            maxEnergy: generator.maxEnergy,
            rearModeLabel: rear.modeA.label,
            frontName: front.name,
            frontPower: runState.loadout.frontPower,
            rearName: rear.name,
            rearPower: runState.loadout.rearPower,
            leftSidekickName: left.name,
            rightSidekickName: right.name,
            leftSidekickAmmo: left.ammoCapacity,
            rightSidekickAmmo: right.ammoCapacity
        )
    }
}
