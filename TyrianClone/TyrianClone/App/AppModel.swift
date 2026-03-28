import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var screen: AppScreen
    @Published private(set) var runState: RunState
    @Published private(set) var hudSnapshot: HUDSnapshot
    @Published private(set) var lastOutcome: StageOutcome?
    @Published private(set) var gameplayViewModel: GameplayViewModel?

    let catalog = TyrianCatalogData.upgradeCatalog
    let tyrianCatalog = TyrianCatalogData.catalog

    private let campaign = CampaignGraphRunner(catalog: TyrianCatalogData.catalog)

    init() {
        let initialState = RunState.default
        runState = initialState
        screen = campaign.screen(for: initialState)
        hudSnapshot = .idle(from: initialState, stageDuration: TyrianCatalogData.levels.first?.duration ?? 0)
    }

    var currentNode: NavNodeDefinition? {
        campaign.currentNode(in: runState)
    }

    var currentLevel: LevelDefinition? {
        campaign.currentLevel(in: runState)
    }

    var currentDatacube: DatacubeDefinition? {
        campaign.currentDatacube(in: runState)
    }

    var currentBranchOptions: [NavNodeDefinition] {
        campaign.branchOptions(in: runState)
    }

    var currentNodeTitle: String {
        campaign.currentNodeDisplayTitle(in: runState)
    }

    var currentNodeBody: String {
        switch currentNode?.id {
        case "tyrian-briefing":
            return "Microsol pressure is closing around Tyrian. Push through the outskirts, bank credits, and make your first port stop at Savara before the route opens wider."
        case "episode-slice-end":
            return "The first route slice is complete. The campaign graph, shop flow, branch logic, and boss progression are now driving the parity build instead of a single sortie loop."
        default:
            return "Proceed to the next campaign node."
        }
    }

    func launchSortie() {
        launchCurrentMission()
    }

    func launchCurrentMission() {
        guard let level = currentLevel else {
            continueFromCurrentNode()
            return
        }

        runState.earnedThisSortie = 0
        lastOutcome = nil
        screen = .stage

        let viewModel = GameplayViewModel(runState: runState, stage: level)
        viewModel.onStateChanged = { [weak self] runState, hudSnapshot in
            guard let self else { return }
            self.runState = runState
            self.hudSnapshot = hudSnapshot
        }
        viewModel.onOutcome = { [weak self] outcome, updatedRunState in
            guard let self else { return }
            self.handleMissionOutcome(outcome, updatedRunState: updatedRunState, levelID: level.id)
        }

        gameplayViewModel?.stop()
        gameplayViewModel = viewModel
        hudSnapshot = viewModel.hudSnapshot
        viewModel.start()
    }

    func continueFromCurrentNode() {
        gameplayViewModel?.stop()
        gameplayViewModel = nil
        runState = campaign.advanceFromPassiveNode(runState)
        syncPassiveState()

        if currentLevel != nil {
            launchCurrentMission()
        }
    }

    func chooseBranch(nextNodeID: String) {
        gameplayViewModel?.stop()
        gameplayViewModel = nil
        runState = campaign.chooseBranch(nextNodeID, in: runState)
        syncPassiveState()

        if currentLevel != nil {
            launchCurrentMission()
        }
    }

    func restartCampaign() {
        gameplayViewModel?.stop()
        gameplayViewModel = nil
        runState = .default
        lastOutcome = nil
        syncPassiveState()
    }

    func returnToBriefing() {
        gameplayViewModel?.stop()
        gameplayViewModel = nil
        runState.currentNodeID = "tyrian-briefing"
        if !runState.visitedNodeIDs.contains("tyrian-briefing") {
            runState.visitedNodeIDs.append("tyrian-briefing")
        }
        lastOutcome = nil
        syncPassiveState()
    }

    func purchase(slot: UpgradeSlot, itemID: String) {
        guard screen == .shop else {
            return
        }

        guard currentItemID(for: slot) != itemID else {
            return
        }

        guard let rule = activeShopRules().first(where: { $0.itemID == itemID && slotFor(itemKind: $0.itemKind) == slot }) else {
            return
        }

        let alreadyOwned = runState.ownedItemIDs.contains(itemID) || rule.basePrice == 0
        if !alreadyOwned {
            guard runState.credits >= rule.basePrice else {
                return
            }
            runState.credits -= rule.basePrice
            runState.ownedItemIDs.append(itemID)
        }

        setCurrentItemID(for: slot, itemID: itemID)
        hudSnapshot = .idle(from: runState, stageDuration: currentLevel?.duration ?? TyrianCatalogData.levels.first?.duration ?? 0)
    }

    func upgradeFrontPower() {
        upgradeWeaponPower(slot: .front)
    }

    func upgradeRearPower() {
        upgradeWeaponPower(slot: .rear)
    }

    func shopSections() -> [ShopSection<any Equatable>] {
        let rules = activeShopRules()
        var sections: [ShopSection<any Equatable>] = []

        if !rules.filter({ $0.itemKind == .ship }).isEmpty {
            sections.append(
                ShopSection(
                    title: "Ship",
                    slot: .ship,
                    currentID: runState.loadout.shipID,
                    items: rules.filter { $0.itemKind == .ship }.compactMap { TyrianCatalogData.shipIndex[$0.itemID] }
                )
            )
        }

        if !rules.filter({ $0.itemKind == .frontWeapon }).isEmpty {
            sections.append(
                ShopSection(
                    title: "Front Weapon",
                    slot: .front,
                    currentID: runState.loadout.frontWeaponID,
                    items: rules.filter { $0.itemKind == .frontWeapon }.compactMap { TyrianCatalogData.frontWeaponIndex[$0.itemID] }
                )
            )
        }

        if !rules.filter({ $0.itemKind == .rearWeapon }).isEmpty {
            sections.append(
                ShopSection(
                    title: "Rear Weapon",
                    slot: .rear,
                    currentID: runState.loadout.rearWeaponID,
                    items: rules.filter { $0.itemKind == .rearWeapon }.compactMap { TyrianCatalogData.rearWeaponIndex[$0.itemID] }
                )
            )
        }

        if !rules.filter({ $0.itemKind == .shield }).isEmpty {
            sections.append(
                ShopSection(
                    title: "Shield",
                    slot: .shield,
                    currentID: runState.loadout.shieldID,
                    items: rules.filter { $0.itemKind == .shield }.compactMap { TyrianCatalogData.shieldIndex[$0.itemID] }
                )
            )
        }

        if !rules.filter({ $0.itemKind == .generator }).isEmpty {
            sections.append(
                ShopSection(
                    title: "Generator",
                    slot: .generator,
                    currentID: runState.loadout.generatorID,
                    items: rules.filter { $0.itemKind == .generator }.compactMap { TyrianCatalogData.generatorIndex[$0.itemID] }
                )
            )
        }

        if !rules.filter({ $0.itemKind == .sidekick }).isEmpty {
            let sidekickItems = rules.filter { $0.itemKind == .sidekick }.compactMap { TyrianCatalogData.sidekickIndex[$0.itemID] }
            sections.append(
                ShopSection(title: "Left Sidekick", slot: .leftSidekick, currentID: runState.loadout.leftSidekickID, items: sidekickItems)
            )
            sections.append(
                ShopSection(title: "Right Sidekick", slot: .rightSidekick, currentID: runState.loadout.rightSidekickID, items: sidekickItems)
            )
        }

        return sections
    }

    func isOwned(itemID: String) -> Bool {
        runState.ownedItemIDs.contains(itemID)
    }

    func currentItemID(for slot: UpgradeSlot) -> String {
        switch slot {
        case .ship:
            runState.loadout.shipID
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

    private func activeShopRules() -> [ShopInventoryRule] {
        campaign.shopRules(in: runState)
    }

    private func slotFor(itemKind: ShopItemKind) -> UpgradeSlot {
        switch itemKind {
        case .ship:
            .ship
        case .frontWeapon, .frontPowerUpgrade:
            .front
        case .rearWeapon, .rearPowerUpgrade:
            .rear
        case .shield:
            .shield
        case .generator:
            .generator
        case .sidekick:
            .leftSidekick
        }
    }

    private func handleMissionOutcome(_ outcome: StageOutcome, updatedRunState: RunState, levelID: String) {
        lastOutcome = outcome
        gameplayViewModel?.stop()
        gameplayViewModel = nil

        if outcome.kind == .cleared {
            var clearedState = updatedRunState
            clearedState.loadout.frontPower = min(Economy.maxWeaponPower(), clearedState.loadout.frontPower + outcome.frontPowerReward)
            clearedState.loadout.rearPower = min(Economy.maxWeaponPower(), clearedState.loadout.rearPower + outcome.rearPowerReward)
            runState = campaign.applyMissionClear(clearedState, missionID: levelID)
            syncPassiveState()
        } else {
            runState = campaign.applyMissionFailure(updatedRunState, missionID: levelID)
            screen = .destroyed
            hudSnapshot = .idle(from: runState, stageDuration: currentLevel?.duration ?? TyrianCatalogData.levels.first?.duration ?? 0)
        }
    }

    private func setCurrentItemID(for slot: UpgradeSlot, itemID: String) {
        switch slot {
        case .ship:
            runState.loadout.shipID = itemID
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
        hudSnapshot = .idle(from: runState, stageDuration: currentLevel?.duration ?? TyrianCatalogData.levels.first?.duration ?? 0)
    }

    private func syncPassiveState() {
        screen = campaign.screen(for: runState)
        hudSnapshot = .idle(from: runState, stageDuration: currentLevel?.duration ?? TyrianCatalogData.levels.first?.duration ?? 0)
    }
}
