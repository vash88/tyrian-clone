import XCTest
@testable import TyrianGameCore

final class CampaignGraphRunnerTests: XCTestCase {
    func testDatacubeNodeUnlocksFlagsAndAdvances() {
        let runner = CampaignGraphRunner(catalog: TyrianCatalogData.catalog)
        var state = RunState.default
        state.currentNodeID = "cube-savara-trade-warning-node"
        state.visitedNodeIDs.append("cube-savara-trade-warning-node")

        let next = runner.advanceFromPassiveNode(state)

        XCTAssertTrue(next.datacubeIDs.contains("cube-savara-trade-warning"))
        XCTAssertTrue(next.campaignFlags.contains("unlock.branch.deliani"))
        XCTAssertEqual(next.currentNodeID, "branch-savara-or-deliani")
    }

    func testMissionClearCommitsBufferedCredits() {
        let runner = CampaignGraphRunner(catalog: TyrianCatalogData.catalog)
        var state = RunState.default
        state.currentNodeID = "tyrian-outskirts"
        state.credits = 680
        state.earnedThisSortie = 125

        let next = runner.applyMissionClear(state, missionID: "tyrian-outskirts")

        XCTAssertEqual(next.credits, 805)
        XCTAssertEqual(next.earnedThisSortie, 0)
        XCTAssertEqual(next.currentNodeID, "savara-port-shop")
    }

    func testMissionFailureFallsBackToSafeNodeAndDropsBufferedCredits() {
        let runner = CampaignGraphRunner(catalog: TyrianCatalogData.catalog)
        var state = RunState.default
        state.currentNodeID = "savara-passage"
        state.visitedNodeIDs = ["tyrian-briefing", "tyrian-outskirts", "savara-port-shop", "savara-passage"]
        state.earnedThisSortie = 90

        let next = runner.applyMissionFailure(state, missionID: "savara-passage")

        XCTAssertEqual(next.currentNodeID, "savara-port-shop")
        XCTAssertEqual(next.earnedThisSortie, 0)
        XCTAssertTrue(next.failedMissionIDs.contains("savara-passage"))
    }
}
