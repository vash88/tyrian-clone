import MetalKit

final class MetalViewportView: MTKView {
    private let fallbackRenderer = MetalRenderer()
    private let targetFramesPerSecond = 60
    private var displayLink: CADisplayLink?

    var renderer: MetalRenderer? {
        didSet {
            device = renderer?.device ?? fallbackRenderer.device
        }
    }

    init() {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        framebufferOnly = true
        colorPixelFormat = .bgra8Unorm
        autoResizeDrawable = true
        enableSetNeedsDisplay = true
        isPaused = true
        preferredFramesPerSecond = targetFramesPerSecond
        isOpaque = true
        clearsContextBeforeDrawing = false
        contentMode = .scaleAspectFill
        backgroundColor = .clear
        clearColor = MTLClearColorMake(0.02, 0.04, 0.07, 1)
        startDisplayLink()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            displayLink?.isPaused = true
        } else {
            updateDrawableScale()
            startDisplayLink()
            displayLink?.isPaused = false
            draw()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateDrawableScale()
    }

    override func draw(_ rect: CGRect) {
        (renderer ?? fallbackRenderer).draw(in: self)
    }

    @objc
    private func tick() {
        draw()
    }

    private func startDisplayLink() {
        guard displayLink == nil else {
            return
        }

        let displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.preferredFramesPerSecond = targetFramesPerSecond
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    private func updateDrawableScale() {
        let nativeScale = window?.windowScene?.screen.nativeScale ?? window?.screen.nativeScale ?? traitCollection.displayScale
        contentScaleFactor = nativeScale
        drawableSize = CGSize(width: bounds.width * nativeScale, height: bounds.height * nativeScale)
    }
}
