import Foundation

enum Economy {
    static func triangular(_ step: Int) -> Int {
        (step * (step + 1)) / 2
    }

    static func nextWeaponUpgradeCost(basePrice: Int, currentPower: Int) -> Int {
        basePrice * triangular(currentPower)
    }

    static func maxWeaponPower() -> Int {
        11
    }

    static func slotLabel(_ slot: UpgradeSlot) -> String {
        switch slot {
        case .ship:
            "Ship"
        case .front:
            "Front Weapon"
        case .rear:
            "Rear Weapon"
        case .shield:
            "Shield"
        case .generator:
            "Generator"
        case .leftSidekick:
            "Left Sidekick"
        case .rightSidekick:
            "Right Sidekick"
        }
    }

    static func basePrice(in catalog: UpgradeCatalog, slot: UpgradeSlot, itemID: String) -> Int {
        switch slot {
        case .ship:
            catalog.ships.first(where: { $0.id == itemID })?.shopCost ?? 0
        case .front:
            catalog.frontWeapons.first(where: { $0.id == itemID })?.basePrice ?? 0
        case .rear:
            catalog.rearWeapons.first(where: { $0.id == itemID })?.basePrice ?? 0
        case .shield:
            catalog.shields.first(where: { $0.id == itemID })?.basePrice ?? 0
        case .generator:
            catalog.generators.first(where: { $0.id == itemID })?.basePrice ?? 0
        case .leftSidekick, .rightSidekick:
            catalog.sidekicks.first(where: { $0.id == itemID })?.basePrice ?? 0
        }
    }
}
