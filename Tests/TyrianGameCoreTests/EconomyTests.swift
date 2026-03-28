import XCTest
@testable import TyrianGameCore

final class EconomyTests: XCTestCase {
    func testWeaponUpgradeCostUsesTriangularProgression() {
        XCTAssertEqual(Economy.nextWeaponUpgradeCost(basePrice: 100, currentPower: 1), 100)
        XCTAssertEqual(Economy.nextWeaponUpgradeCost(basePrice: 100, currentPower: 2), 300)
        XCTAssertEqual(Economy.nextWeaponUpgradeCost(basePrice: 100, currentPower: 3), 600)
    }

    func testWeaponPowerCapMatchesTyrianSpec() {
        XCTAssertEqual(Economy.maxWeaponPower(), 11)
    }
}
