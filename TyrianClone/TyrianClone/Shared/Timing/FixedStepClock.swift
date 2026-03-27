import QuartzCore

@MainActor
final class FixedStepClock {
    private let step: CFTimeInterval
    private let maxFrameDelta: CFTimeInterval
    private let preferredFramesPerSecond: Int
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var accumulator: CFTimeInterval = 0
    private let onStep: (Double) -> Void

    init(
        step: CFTimeInterval,
        preferredFramesPerSecond: Int = 60,
        maxFrameDelta: CFTimeInterval = 0.05,
        onStep: @escaping (Double) -> Void
    ) {
        self.step = step
        self.preferredFramesPerSecond = preferredFramesPerSecond
        self.maxFrameDelta = maxFrameDelta
        self.onStep = onStep
    }

    func start() {
        guard displayLink == nil else {
            return
        }

        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.preferredFramesPerSecond = preferredFramesPerSecond
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
        accumulator = 0
    }

    @objc private func handleDisplayLink(_ link: CADisplayLink) {
        guard let lastTimestamp else {
            self.lastTimestamp = link.timestamp
            return
        }

        let delta = min(maxFrameDelta, link.timestamp - lastTimestamp)
        self.lastTimestamp = link.timestamp
        accumulator += delta

        while accumulator >= step {
            accumulator -= step
            onStep(step)
        }
    }

    deinit {
        displayLink?.invalidate()
    }
}
