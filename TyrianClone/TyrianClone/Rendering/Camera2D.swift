import CoreGraphics

struct Camera2D {
    let worldSize: CGSize

    func aspectFitRect(in container: CGSize) -> CGRect {
        guard worldSize.width > 0, worldSize.height > 0, container.width > 0, container.height > 0 else {
            return CGRect(origin: .zero, size: container)
        }

        let scale = min(container.width / worldSize.width, container.height / worldSize.height)
        let fittedSize = CGSize(width: worldSize.width * scale, height: worldSize.height * scale)
        let origin = CGPoint(
            x: (container.width - fittedSize.width) / 2,
            y: (container.height - fittedSize.height) / 2
        )
        return CGRect(origin: origin, size: fittedSize)
    }
}
