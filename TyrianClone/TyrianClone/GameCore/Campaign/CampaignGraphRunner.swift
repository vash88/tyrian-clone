import Foundation

struct CampaignGraphRunner {
    let catalog: TyrianCatalog

    private var navNodeIndex: [String: NavNodeDefinition] {
        Dictionary(uniqueKeysWithValues: catalog.navNodes.map { ($0.id, $0) })
    }

    private var levelIndex: [String: LevelDefinition] {
        Dictionary(uniqueKeysWithValues: catalog.levels.map { ($0.id, $0) })
    }

    private var datacubeIndex: [String: DatacubeDefinition] {
        Dictionary(uniqueKeysWithValues: catalog.datacubes.map { ($0.id, $0) })
    }

    func currentNode(in state: CampaignState) -> NavNodeDefinition? {
        navNodeIndex[state.currentNodeID]
    }

    func currentLevel(in state: CampaignState) -> LevelDefinition? {
        guard let node = currentNode(in: state), node.nodeType == .mission, let payloadRef = node.payloadRef else {
            return nil
        }
        return levelIndex[payloadRef]
    }

    func currentDatacube(in state: CampaignState) -> DatacubeDefinition? {
        guard let node = currentNode(in: state), node.nodeType == .datacube, let payloadRef = node.payloadRef else {
            return nil
        }
        return datacubeIndex[payloadRef]
    }

    func shopRules(in state: CampaignState) -> [ShopInventoryRule] {
        catalog.shopRules.filter { $0.nodeID == state.currentNodeID }
    }

    func branchOptions(in state: CampaignState) -> [NavNodeDefinition] {
        guard let node = currentNode(in: state), node.nodeType == .branch else {
            return []
        }

        return node.outputs.compactMap { navNodeIndex[$0] }
    }

    func currentNodeDisplayTitle(in state: CampaignState) -> String {
        currentNode(in: state)?.title ?? "Tyrian"
    }

    func screen(for state: CampaignState) -> AppScreen {
        guard let node = currentNode(in: state) else {
            return .intermission
        }

        switch node.nodeType {
        case .mission:
            return .intermission
        case .shop:
            return .shop
        case .datacube:
            return .datacube
        case .textIntermission:
            return .intermission
        case .branch:
            return .branch
        case .episodeTransition:
            return .episodeTransition
        case .campaignEnd:
            return .episodeTransition
        }
    }

    func advanceFromPassiveNode(_ state: CampaignState) -> CampaignState {
        var nextState = state

        if let datacube = currentDatacube(in: state), !nextState.datacubeIDs.contains(datacube.id) {
            nextState.datacubeIDs.append(datacube.id)
            for effect in datacube.unlockEffects where !nextState.campaignFlags.contains(effect) {
                nextState.campaignFlags.append(effect)
            }
        }

        guard let node = currentNode(in: state) else {
            return nextState
        }

        guard let nextNodeID = node.outputs.first else {
            return nextState
        }

        return move(nextState, to: nextNodeID)
    }

    func chooseBranch(_ nextNodeID: String, in state: CampaignState) -> CampaignState {
        guard branchOptions(in: state).contains(where: { $0.id == nextNodeID }) else {
            return state
        }

        return move(state, to: nextNodeID)
    }

    func applyMissionClear(_ state: CampaignState, missionID: String?) -> CampaignState {
        var nextState = state

        if let missionID, !nextState.completedMissionIDs.contains(missionID) {
            nextState.completedMissionIDs.append(missionID)
        }

        nextState.credits += nextState.earnedThisSortie
        nextState.earnedThisSortie = 0
        nextState.sortie += 1

        guard let node = currentNode(in: state), let nextNodeID = node.outputs.first else {
            return nextState
        }

        return move(nextState, to: nextNodeID)
    }

    func applyMissionFailure(_ state: CampaignState, missionID: String?) -> CampaignState {
        var nextState = state

        if let missionID, !nextState.failedMissionIDs.contains(missionID) {
            nextState.failedMissionIDs.append(missionID)
        }

        nextState.earnedThisSortie = 0

        let fallbackNodeID = state.visitedNodeIDs.reversed().compactMap { navNodeIndex[$0] }.first(where: {
            $0.nodeType != .mission && $0.nodeType != .branch
        })?.id ?? "tyrian-briefing"

        return move(nextState, to: fallbackNodeID)
    }

    private func move(_ state: CampaignState, to nextNodeID: String) -> CampaignState {
        var nextState = state
        nextState.currentNodeID = nextNodeID
        if !nextState.visitedNodeIDs.contains(nextNodeID) {
            nextState.visitedNodeIDs.append(nextNodeID)
        }
        if !nextState.unlockedNodeIDs.contains(nextNodeID) {
            nextState.unlockedNodeIDs.append(nextNodeID)
        }
        return nextState
    }
}
