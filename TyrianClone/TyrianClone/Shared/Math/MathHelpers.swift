import Foundation

enum MathHelpers {
    static func approach(current: Double, target: Double, maxDelta: Double) -> Double {
        if current < target {
            min(target, current + maxDelta)
        } else {
            max(target, current - maxDelta)
        }
    }

    static func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.max(minimum, Swift.min(maximum, value))
    }

    static func distanceSquared(ax: Double, ay: Double, bx: Double, by: Double) -> Double {
        let dx = ax - bx
        let dy = ay - by
        return dx * dx + dy * dy
    }
}
