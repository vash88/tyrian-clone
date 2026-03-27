import Foundation

struct PlayerIntent: Equatable {
    var axisX: Double = 0
    var axisY: Double = 0
    var isFiring = false
    var isLeftSidekickActive = false
    var isRightSidekickActive = false
    var didToggleRearMode = false
    var isPaused = false
}
