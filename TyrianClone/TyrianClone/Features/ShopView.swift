import SwiftUI

struct ShopView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        let frontWeapon = appModel.catalog.frontWeapons.first(where: { $0.id == appModel.runState.loadout.frontWeaponID })
        let rearWeapon = appModel.catalog.rearWeapons.first(where: { $0.id == appModel.runState.loadout.rearWeaponID })
        let frontUpgradePrice = Economy.nextWeaponUpgradeCost(basePrice: frontWeapon?.basePrice ?? 0, currentPower: appModel.runState.loadout.frontPower)
        let rearUpgradePrice = Economy.nextWeaponUpgradeCost(basePrice: rearWeapon?.basePrice ?? 0, currentPower: appModel.runState.loadout.rearPower)
        let earned = appModel.lastOutcome?.earned ?? 0

        Group {
            Section("Hangar") {
                Text("Stage cleared. You banked \(earned) credits this run and now have \(appModel.runState.credits) credits ready to spend.")
                Button("Front Power \(appModel.runState.loadout.frontPower)/\(Economy.maxWeaponPower()) · \(frontUpgradePrice) cr") {
                    appModel.upgradeFrontPower()
                }
                .disabled(appModel.runState.loadout.frontPower >= Economy.maxWeaponPower() || appModel.runState.credits < frontUpgradePrice)

                Button("Rear Power \(appModel.runState.loadout.rearPower)/\(Economy.maxWeaponPower()) · \(rearUpgradePrice) cr") {
                    appModel.upgradeRearPower()
                }
                .disabled(appModel.runState.loadout.rearPower >= Economy.maxWeaponPower() || appModel.runState.credits < rearUpgradePrice)

                Button("Continue Sortie") {
                    appModel.continueToNextSortie()
                }

                Button("Reset Campaign", role: .destructive) {
                    appModel.restartCampaign()
                }
            }

            shopSection(title: "Front Weapon", slot: .front, currentID: appModel.runState.loadout.frontWeaponID, items: appModel.catalog.frontWeapons)
            shopSection(title: "Rear Weapon", slot: .rear, currentID: appModel.runState.loadout.rearWeaponID, items: appModel.catalog.rearWeapons)
            shopSection(title: "Shield", slot: .shield, currentID: appModel.runState.loadout.shieldID, items: appModel.catalog.shields)
            shopSection(title: "Generator", slot: .generator, currentID: appModel.runState.loadout.generatorID, items: appModel.catalog.generators)
            shopSection(title: "Left Sidekick", slot: .leftSidekick, currentID: appModel.runState.loadout.leftSidekickID, items: appModel.catalog.sidekicks)
            shopSection(title: "Right Sidekick", slot: .rightSidekick, currentID: appModel.runState.loadout.rightSidekickID, items: appModel.catalog.sidekicks)
        }
    }

    private func shopSection<Item: Identifiable & Equatable>(title: String, slot: UpgradeSlot, currentID: String, items: [Item]) -> some View where Item.ID == String {
        Section(title) {
            LabeledContent("Current", value: currentID)

            ForEach(items, id: \.id) { item in
                if let shopItem = shopItemViewModel(for: item) {
                    let isOwned = currentID == shopItem.id
                    Button {
                        appModel.purchase(slot: slot, itemID: shopItem.id)
                    } label: {
                        LabeledContent(shopItem.name, value: isOwned ? "Equipped" : "\(shopItem.basePrice) cr")
                    }
                    .disabled(isOwned || appModel.runState.credits < shopItem.basePrice)
                }
            }
        }
    }

    private func shopItemViewModel<Item>(for item: Item) -> (id: String, name: String, basePrice: Int)? {
        switch item {
        case let weapon as WeaponArchetype:
            return (weapon.id, weapon.name, weapon.basePrice)
        case let shield as ShieldArchetype:
            return (shield.id, shield.name, shield.basePrice)
        case let generator as GeneratorArchetype:
            return (generator.id, generator.name, generator.basePrice)
        case let sidekick as SidekickArchetype:
            return (sidekick.id, sidekick.name, sidekick.basePrice)
        default:
            return nil
        }
    }
}
