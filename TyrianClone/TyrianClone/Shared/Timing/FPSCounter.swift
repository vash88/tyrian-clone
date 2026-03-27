import Combine
import QuartzCore
import SwiftUI

@MainActor
final class FPSCounter: ObservableObject {
    @Published private(set) var fps = 0

    private var displayLink: CADisplayLink?
    private var accumulatedFrames = 0
    private var lastTimestamp = 0.0

    init() {
        let displayLink = CADisplayLink(target: self, selector: #selector(step(_:)))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    deinit {
        displayLink?.invalidate()
    }

    @objc
    private func step(_ displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
        }

        accumulatedFrames += 1
        let elapsed = displayLink.timestamp - lastTimestamp

        guard elapsed >= 0.5 else {
            return
        }

        fps = Int((Double(accumulatedFrames) / elapsed).rounded())
        accumulatedFrames = 0
        lastTimestamp = displayLink.timestamp
    }
}
