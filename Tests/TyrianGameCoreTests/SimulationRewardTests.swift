import XCTest
@testable import TyrianGameCore

final class SimulationRewardTests: XCTestCase {
    func testCreditPickupBuffersMissionCreditsInsteadOfBankingImmediately() {
        var state = RunState.default
        let level = LevelDefinition(
            id: "test-credit-buffer",
            name: "Test Credit Buffer",
            worldID: "test",
            duration: 1.0,
            backgroundTheme: nil,
            waves: [],
            events: [
                LevelEvent(
                    id: "credit-event",
                    triggerTime: 0,
                    triggerProgress: nil,
                    eventType: .grantPickup(pickupID: "credits-small"),
                    notes: nil
                )
            ],
            bossID: nil,
            completionRule: .surviveDuration,
            rewardProfile: nil,
            nextNodeRules: []
        )

        let simulation = Simulation(runState: state, stage: level)
        simulation.debugInjectPickup("credits-small")

        _ = simulation.update(dt: 1.0 / 60.0, intent: PlayerIntent())

        state = simulation.runState
        XCTAssertEqual(state.credits, RunState.default.credits)
        XCTAssertGreaterThan(state.earnedThisSortie, 0)
    }

    func testFrontPowerPickupAppliesAsMissionRewardAndNotImmediatePersistentLoadout() {
        let level = LevelDefinition(
            id: "test-front-power",
            name: "Test Front Power",
            worldID: "test",
            duration: 0.2,
            backgroundTheme: nil,
            waves: [],
            events: [],
            bossID: nil,
            completionRule: .surviveDuration,
            rewardProfile: nil,
            nextNodeRules: []
        )

        let simulation = Simulation(runState: .default, stage: level)
        simulation.debugInjectPickup("front-power")
        var outcome: StageOutcome?

        for _ in 0 ..< 120 {
            if let nextOutcome = simulation.update(dt: 1.0 / 60.0, intent: PlayerIntent()) {
                outcome = nextOutcome
            }
        }

        let hud = simulation.makeHUDSnapshot()

        XCTAssertEqual(simulation.runState.loadout.frontPower, 1)
        XCTAssertEqual(hud.frontPower, 2)
        XCTAssertEqual(outcome?.frontPowerReward, 1)
    }

    func testBossMissionUsesDefeatBossCompletionRule() {
        let level = TyrianCatalogData.levelIndex["gyges-boss"]!
        let simulation = Simulation(runState: .default, stage: level)

        for _ in 0 ..< 520 {
            _ = simulation.update(dt: 1.0 / 60.0, intent: PlayerIntent())
        }

        XCTAssertNotNil(simulation.makeRenderSnapshot().bossLineColorHex)
        XCTAssertFalse(simulation.makeRenderSnapshot().bossWeakPoints.isEmpty)
    }
}
