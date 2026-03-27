import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var screen: AppScreen = .briefing
    @Published private(set) var runState: RunState = .default
    @Published private(set) var hudSnapshot: HUDSnapshot = .idle(from: .default)
    @Published private(set) var lastOutcome: StageOutcome?
    @Published private(set) var gameplayViewModel: GameplayViewModel?

    let catalog = PrototypeData.catalog
    let stage = PrototypeData.stage

    func launchSortie() {
        runState.earnedThisSortie = 0
        lastOutcome = nil
        screen = .stage

        let viewModel = GameplayViewModel(runState: runState, stage: stage)
        viewModel.onStateChanged = { [weak self] runState, hudSnapshot in
            guard let self else { return }
            self.runState = runState
            self.hudSnapshot = hudSnapshot
        }
        viewModel.onOutcome = { [weak self] outcome, runState in
            guard let self else { return }
            self.lastOutcome = outcome
            self.runState = runState
            self.hudSnapshot = .idle(from: runState)
            self.gameplayViewModel?.stop()
            self.gameplayViewModel = nil
            self.screen = outcome.kind == .cleared ? .shop : .destroyed
        }

        gameplayViewModel?.stop()
        gameplayViewModel = viewModel
        hudSnapshot = viewModel.hudSnapshot
        viewModel.start()
    }

    func restartCampaign() {
        gameplayViewModel?.stop()
        gameplayViewModel = nil
        runState = .default
        lastOutcome = nil
        screen = .briefing
        hudSnapshot = .idle(from: runState)
    }

    func returnToBriefing() {
        gameplayViewModel?.stop()
        gameplayViewModel = nil
        screen = .briefing
        hudSnapshot = .idle(from: runState)
    }

    func continueToNextSortie() {
        runState.sortie += 1
        launchSortie()
    }

    func purchase(slot: UpgradeSlot, itemID: String) {
        guard screen == .shop else {
            return
        }

        guard currentItemID(for: slot) != itemID else {
            return
        }

        let price = Economy.basePrice(in: catalog, slot: slot, itemID: itemID)
        guard price > 0, runState.credits >= price else {
            return
        }

        runState.credits -= price
        setCurrentItemID(for: slot, itemID: itemID)
        hudSnapshot = .idle(from: runState)
    }

    func upgradeFrontPower() {
        upgradeWeaponPower(slot: .front)
    }

    func upgradeRearPower() {
        upgradeWeaponPower(slot: .rear)
    }

    func shopSections() -> [ShopSection<any Equatable>] {
        [
            ShopSection(title: "Front Weapon", slot: .front, currentID: runState.loadout.frontWeaponID, items: catalog.frontWeapons),
            ShopSection(title: "Rear Weapon", slot: .rear, currentID: runState.loadout.rearWeaponID, items: catalog.rearWeapons),
            ShopSection(title: "Shield", slot: .shield, currentID: runState.loadout.shieldID, items: catalog.shields),
            ShopSection(title: "Generator", slot: .generator, currentID: runState.loadout.generatorID, items: catalog.generators),
            ShopSection(title: "Left Sidekick", slot: .leftSidekick, currentID: runState.loadout.leftSidekickID, items: catalog.sidekicks),
            ShopSection(title: "Right Sidekick", slot: .rightSidekick, currentID: runState.loadout.rightSidekickID, items: catalog.sidekicks)
        ]
    }

    func currentItemID(for slot: UpgradeSlot) -> String {
        switch slot {
        case .front:
            runState.loadout.frontWeaponID
        case .rear:
            runState.loadout.rearWeaponID
        case .shield:
            runState.loadout.shieldID
        case .generator:
            runState.loadout.generatorID
        case .leftSidekick:
            runState.loadout.leftSidekickID
        case .rightSidekick:
            runState.loadout.rightSidekickID
        }
    }

    private func setCurrentItemID(for slot: UpgradeSlot, itemID: String) {
        switch slot {
        case .front:
            runState.loadout.frontWeaponID = itemID
        case .rear:
            runState.loadout.rearWeaponID = itemID
        case .shield:
            runState.loadout.shieldID = itemID
        case .generator:
            runState.loadout.generatorID = itemID
        case .leftSidekick:
            runState.loadout.leftSidekickID = itemID
        case .rightSidekick:
            runState.loadout.rightSidekickID = itemID
        }
    }

    private func upgradeWeaponPower(slot: UpgradeSlot) {
        guard screen == .shop else {
            return
        }

        let currentID: String
        let currentPower: Int
        let catalogItem: WeaponArchetype?

        switch slot {
        case .front:
            currentID = runState.loadout.frontWeaponID
            currentPower = runState.loadout.frontPower
            catalogItem = catalog.frontWeapons.first(where: { $0.id == currentID })
        case .rear:
            currentID = runState.loadout.rearWeaponID
            currentPower = runState.loadout.rearPower
            catalogItem = catalog.rearWeapons.first(where: { $0.id == currentID })
        default:
            return
        }

        guard let weapon = catalogItem, currentPower < Economy.maxWeaponPower() else {
            return
        }

        let cost = Economy.nextWeaponUpgradeCost(basePrice: weapon.basePrice, currentPower: currentPower)
        guard runState.credits >= cost else {
            return
        }

        runState.credits -= cost
        if slot == .front {
            runState.loadout.frontPower += 1
        } else {
            runState.loadout.rearPower += 1
        }
        hudSnapshot = .idle(from: runState)
    }
}
