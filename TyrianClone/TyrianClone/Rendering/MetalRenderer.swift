import CoreGraphics
import MetalKit
import simd

final class MetalRenderer {
    private let context = MetalContext()
    private lazy var pipelineState = makePipelineState()
    private var rgbCache: [String: SIMD3<Float>] = [:]

    var snapshot: RenderSnapshot = .empty

    var device: MTLDevice? {
        context?.device
    }

    func update(snapshot: RenderSnapshot) {
        self.snapshot = snapshot
    }

    func draw(in view: MTKView) {
        guard let context,
              let pipelineState,
              let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = context.commandQueue.makeCommandBuffer()
        else {
            return
        }

        let vertices = buildVertices(targetSize: view.drawableSize)
        guard !vertices.isEmpty,
              let vertexBuffer = context.device.makeBuffer(
                  bytes: vertices,
                  length: MemoryLayout<PrimitiveVertex>.stride * vertices.count,
                  options: .storageModeShared
              ),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setCullMode(.none)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func makePipelineState() -> MTLRenderPipelineState? {
        guard let context,
              let vertexFunction = context.library.makeFunction(name: "primitiveVertex"),
              let fragmentFunction = context.library.makeFunction(name: "primitiveFragment")
        else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? context.device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func buildVertices(targetSize: CGSize) -> [PrimitiveVertex] {
        let transform = RenderTransform(worldSize: snapshot.worldSize, targetSize: targetSize)
        var vertices: [PrimitiveVertex] = []
        vertices.reserveCapacity(4096)

        appendBackground(to: &vertices, transform: transform)
        appendRectOutline(
            CGRect(x: 6, y: 6, width: snapshot.worldSize.width - 12, height: snapshot.worldSize.height - 12),
            thickness: 2,
            color: color(hex: "#98c4f7", alpha: 0.18),
            vertices: &vertices,
            transform: transform
        )

        for pickup in snapshot.credits {
            appendOutlinePolygon(
                centeredAt: pickup.position,
                points: [
                    CGPoint(x: 0, y: -7),
                    CGPoint(x: 6, y: -3),
                    CGPoint(x: 6, y: 3),
                    CGPoint(x: 0, y: 7),
                    CGPoint(x: -6, y: 3),
                    CGPoint(x: -6, y: -3)
                ],
                thickness: 1.5,
                color: color(hex: "#88ffd5"),
                vertices: &vertices,
                transform: transform
            )
        }

        for pickup in snapshot.pickups {
            let pickupColor: SIMD4<Float>
            let points: [CGPoint]

            switch pickup.kind {
            case .frontPower:
                pickupColor = color(hex: "#ffd86a")
                points = [
                    CGPoint(x: 0, y: -10),
                    CGPoint(x: 10, y: 0),
                    CGPoint(x: 0, y: 10),
                    CGPoint(x: -10, y: 0)
                ]
            case .rearPower:
                pickupColor = color(hex: "#7ef0c9")
                points = [
                    CGPoint(x: 0, y: -9),
                    CGPoint(x: 8, y: -2),
                    CGPoint(x: 8, y: 2),
                    CGPoint(x: 0, y: 9),
                    CGPoint(x: -8, y: 2),
                    CGPoint(x: -8, y: -2)
                ]
            case .armorRepair:
                pickupColor = color(hex: "#8fc5ff")
                points = [
                    CGPoint(x: -9, y: -3),
                    CGPoint(x: -3, y: -3),
                    CGPoint(x: -3, y: -9),
                    CGPoint(x: 3, y: -9),
                    CGPoint(x: 3, y: -3),
                    CGPoint(x: 9, y: -3),
                    CGPoint(x: 9, y: 3),
                    CGPoint(x: 3, y: 3),
                    CGPoint(x: 3, y: 9),
                    CGPoint(x: -3, y: 9),
                    CGPoint(x: -3, y: 3),
                    CGPoint(x: -9, y: 3)
                ]
            case .shieldRestore:
                pickupColor = color(hex: "#a3a8ff")
                points = [
                    CGPoint(x: 0, y: -10),
                    CGPoint(x: 9, y: -4),
                    CGPoint(x: 9, y: 4),
                    CGPoint(x: 0, y: 10),
                    CGPoint(x: -9, y: 4),
                    CGPoint(x: -9, y: -4)
                ]
            case .credits, .datacube, .sidekickAmmo, .scriptedItem:
                pickupColor = color(hex: "#ffffff")
                points = [
                    CGPoint(x: 0, y: -8),
                    CGPoint(x: 8, y: 0),
                    CGPoint(x: 0, y: 8),
                    CGPoint(x: -8, y: 0)
                ]
            }

            appendOutlinePolygon(
                centeredAt: pickup.position,
                points: points,
                thickness: 1.75,
                color: pickupColor,
                vertices: &vertices,
                transform: transform
            )
        }

        for hazard in snapshot.hazards {
            appendRectOutline(
                hazard.frame,
                thickness: 2,
                color: color(hex: hazard.colorHex, alpha: 0.45),
                vertices: &vertices,
                transform: transform
            )
        }

        for projectile in snapshot.projectiles {
            let projectileColor = color(hex: projectile.colorHex)
            if projectile.isPlayerOwned {
                appendRing(
                    center: projectile.position,
                    radius: Float(max(projectile.radius, 1)),
                    thickness: 2,
                    color: projectileColor,
                    vertices: &vertices,
                    transform: transform
                )
            } else {
                appendFilledCircle(
                    center: projectile.position,
                    radius: Float(max(projectile.radius, 1)),
                    color: projectileColor,
                    vertices: &vertices,
                    transform: transform
                )
            }
        }

        for enemy in snapshot.enemies {
            let enemyColor = color(hex: enemy.colorHex)
            if enemy.isBoss {
                appendOutlinePolygon(
                    centeredAt: enemy.position,
                    points: [
                        CGPoint(x: -36, y: 0),
                        CGPoint(x: -10, y: -26),
                        CGPoint(x: 10, y: -26),
                        CGPoint(x: 36, y: 0),
                        CGPoint(x: 18, y: 30),
                        CGPoint(x: -18, y: 30)
                    ],
                    thickness: 3,
                    color: enemyColor,
                    vertices: &vertices,
                    transform: transform
                )
            } else {
                appendOutlinePolygon(
                    centeredAt: enemy.position,
                    points: [
                        CGPoint(x: 0, y: -enemy.radius),
                        CGPoint(x: enemy.radius, y: 0),
                        CGPoint(x: 0, y: enemy.radius),
                        CGPoint(x: -enemy.radius, y: 0)
                    ],
                    thickness: 2,
                    color: enemyColor,
                    vertices: &vertices,
                    transform: transform
                )
            }
        }

        for weakPoint in snapshot.bossWeakPoints {
            appendRing(
                center: weakPoint.position,
                radius: 11,
                thickness: 2,
                color: color(hex: weakPoint.colorHex, alpha: 0.9),
                vertices: &vertices,
                transform: transform
            )
        }

        for sidekick in snapshot.sidekicks {
            appendOutlinePolygon(
                centeredAt: sidekick.position,
                points: [
                    CGPoint(x: -8, y: -8),
                    CGPoint(x: 8, y: -8),
                    CGPoint(x: 8, y: 8),
                    CGPoint(x: -8, y: 8)
                ],
                thickness: 1.75,
                color: color(hex: sidekick.colorHex),
                vertices: &vertices,
                transform: transform
            )
        }

        if let player = snapshot.player {
            appendOutlinePolygon(
                centeredAt: player.position,
                points: [
                    CGPoint(x: 0, y: -16),
                    CGPoint(x: 13, y: 14),
                    CGPoint(x: 0, y: 8),
                    CGPoint(x: -13, y: 14)
                ],
                thickness: 2,
                color: color(hex: player.frontWeaponColorHex),
                vertices: &vertices,
                transform: transform
            )

            appendRing(
                center: player.position,
                radius: 22,
                thickness: 2,
                color: color(hex: player.shieldColorHex, alpha: player.shieldActive ? 0.7 : 0.16),
                vertices: &vertices,
                transform: transform
            )

            if player.invulnerability > 0 {
                let alpha = Float(max(0.3, min(0.9, 0.5 + sin(player.invulnerability * 24) * 0.2)))
                appendRing(
                    center: player.position,
                    radius: 28,
                    thickness: 2,
                    color: color(hex: "#ffffff", alpha: alpha),
                    vertices: &vertices,
                    transform: transform
                )
            }
        }

        for effect in snapshot.effects {
            let lifeRatio = Float(effect.maxLife > 0 ? effect.life / effect.maxLife : 0)
            let effectColor = color(hex: effect.colorHex, alpha: max(0, min(1, lifeRatio)))

            switch effect.kind {
            case .flash:
                let radius = Float(effect.radius * (1 - Double(lifeRatio) * 0.45))
                appendFilledCircle(
                    center: effect.position,
                    radius: max(radius, 2),
                    color: effectColor,
                    vertices: &vertices,
                    transform: transform
                )
            case .ring:
                let radius = Float(effect.radius * (1 - Double(lifeRatio)) + 6)
                appendRing(
                    center: effect.position,
                    radius: max(radius, 3),
                    thickness: 2,
                    color: effectColor,
                    vertices: &vertices,
                    transform: transform
                )
            case .burst:
                let radius = Float(effect.radius * (1 - Double(lifeRatio) * 0.55) + 4)
                appendRing(
                    center: effect.position,
                    radius: max(radius, 4),
                    thickness: 3,
                    color: effectColor,
                    vertices: &vertices,
                    transform: transform
                )
            }
        }

        if let bossLineColorHex = snapshot.bossLineColorHex {
            appendSegment(
                from: CGPoint(x: 24, y: 112),
                to: CGPoint(x: snapshot.worldSize.width - 24, y: 112),
                thickness: 2,
                color: color(hex: bossLineColorHex, alpha: 0.18),
                vertices: &vertices,
                transform: transform
            )
        }

        return vertices
    }

    private func appendBackground(to vertices: inout [PrimitiveVertex], transform: RenderTransform) {
        let rect = CGRect(origin: .zero, size: snapshot.worldSize)
        let topColor = color(hex: "#09131c")
        let bottomColor = color(hex: "#02060c")
        appendGradientRect(rect, topColor: topColor, bottomColor: bottomColor, vertices: &vertices, transform: transform)
    }

    private func appendGradientRect(
        _ rect: CGRect,
        topColor: SIMD4<Float>,
        bottomColor: SIMD4<Float>,
        vertices: inout [PrimitiveVertex],
        transform: RenderTransform
    ) {
        let topLeft = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.minX, y: rect.minY)), color: topColor)
        let topRight = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.maxX, y: rect.minY)), color: topColor)
        let bottomLeft = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.minX, y: rect.maxY)), color: bottomColor)
        let bottomRight = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.maxX, y: rect.maxY)), color: bottomColor)

        vertices.append(contentsOf: [topLeft, bottomLeft, topRight, topRight, bottomLeft, bottomRight])
    }

    private func appendRect(
        _ rect: CGRect,
        color: SIMD4<Float>,
        vertices: inout [PrimitiveVertex],
        transform: RenderTransform
    ) {
        let topLeft = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.minX, y: rect.minY)), color: color)
        let topRight = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.maxX, y: rect.minY)), color: color)
        let bottomLeft = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.minX, y: rect.maxY)), color: color)
        let bottomRight = PrimitiveVertex(position: transform.clipPoint(CGPoint(x: rect.maxX, y: rect.maxY)), color: color)

        vertices.append(contentsOf: [topLeft, bottomLeft, topRight, topRight, bottomLeft, bottomRight])
    }

    private func appendRectOutline(
        _ rect: CGRect,
        thickness: Double,
        color: SIMD4<Float>,
        vertices: inout [PrimitiveVertex],
        transform: RenderTransform
    ) {
        appendSegment(
            from: CGPoint(x: rect.minX, y: rect.minY),
            to: CGPoint(x: rect.maxX, y: rect.minY),
            thickness: thickness,
            color: color,
            vertices: &vertices,
            transform: transform
        )
        appendSegment(
            from: CGPoint(x: rect.maxX, y: rect.minY),
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            thickness: thickness,
            color: color,
            vertices: &vertices,
            transform: transform
        )
        appendSegment(
            from: CGPoint(x: rect.maxX, y: rect.maxY),
            to: CGPoint(x: rect.minX, y: rect.maxY),
            thickness: thickness,
            color: color,
            vertices: &vertices,
            transform: transform
        )
        appendSegment(
            from: CGPoint(x: rect.minX, y: rect.maxY),
            to: CGPoint(x: rect.minX, y: rect.minY),
            thickness: thickness,
            color: color,
            vertices: &vertices,
            transform: transform
        )
    }

    private func appendOutlinePolygon(
        centeredAt center: CGPoint,
        points: [CGPoint],
        thickness: Double,
        color: SIMD4<Float>,
        vertices: inout [PrimitiveVertex],
        transform: RenderTransform
    ) {
        guard points.count > 1 else {
            return
        }

        for index in points.indices {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            appendSegment(
                from: CGPoint(x: center.x + current.x, y: center.y + current.y),
                to: CGPoint(x: center.x + next.x, y: center.y + next.y),
                thickness: thickness,
                color: color,
                vertices: &vertices,
                transform: transform
            )
        }
    }

    private func appendSegment(
        from start: CGPoint,
        to end: CGPoint,
        thickness: Double,
        color: SIMD4<Float>,
        vertices: inout [PrimitiveVertex],
        transform: RenderTransform
    ) {
        let startPoint = SIMD2<Float>(Float(start.x), Float(start.y))
        let endPoint = SIMD2<Float>(Float(end.x), Float(end.y))
        let delta = endPoint - startPoint
        let length = simd_length(delta)

        guard length > 0.0001 else {
            return
        }

        let direction = delta / length
        let normal = SIMD2<Float>(-direction.y, direction.x) * Float(thickness) * 0.5

        let a = CGPoint(x: CGFloat(startPoint.x + normal.x), y: CGFloat(startPoint.y + normal.y))
        let b = CGPoint(x: CGFloat(endPoint.x + normal.x), y: CGFloat(endPoint.y + normal.y))
        let c = CGPoint(x: CGFloat(startPoint.x - normal.x), y: CGFloat(startPoint.y - normal.y))
        let d = CGPoint(x: CGFloat(endPoint.x - normal.x), y: CGFloat(endPoint.y - normal.y))

        let va = PrimitiveVertex(position: transform.clipPoint(a), color: color)
        let vb = PrimitiveVertex(position: transform.clipPoint(b), color: color)
        let vc = PrimitiveVertex(position: transform.clipPoint(c), color: color)
        let vd = PrimitiveVertex(position: transform.clipPoint(d), color: color)

        vertices.append(contentsOf: [va, vc, vb, vb, vc, vd])
    }

    private func appendFilledCircle(
        center: CGPoint,
        radius: Float,
        color: SIMD4<Float>,
        vertices: inout [PrimitiveVertex],
        transform: RenderTransform
    ) {
        let segmentCount = max(12, min(32, Int(radius * 1.4)))
        let centerVertex = PrimitiveVertex(position: transform.clipPoint(center), color: color)

        for index in 0 ..< segmentCount {
            let startAngle = (Float(index) / Float(segmentCount)) * .pi * 2
            let endAngle = (Float(index + 1) / Float(segmentCount)) * .pi * 2

            let p1 = CGPoint(
                x: center.x + CGFloat(cos(startAngle) * radius),
                y: center.y + CGFloat(sin(startAngle) * radius)
            )
            let p2 = CGPoint(
                x: center.x + CGFloat(cos(endAngle) * radius),
                y: center.y + CGFloat(sin(endAngle) * radius)
            )

            vertices.append(contentsOf: [
                centerVertex,
                PrimitiveVertex(position: transform.clipPoint(p1), color: color),
                PrimitiveVertex(position: transform.clipPoint(p2), color: color)
            ])
        }
    }

    private func appendRing(
        center: CGPoint,
        radius: Float,
        thickness: Double,
        color: SIMD4<Float>,
        vertices: inout [PrimitiveVertex],
        transform: RenderTransform
    ) {
        let halfThickness = Float(thickness) * 0.5
        let innerRadius = max(radius - halfThickness, 0.5)
        let outerRadius = max(radius + halfThickness, innerRadius + 0.5)
        let segmentCount = max(18, min(40, Int(outerRadius * 1.6)))

        for index in 0 ..< segmentCount {
            let startAngle = (Float(index) / Float(segmentCount)) * .pi * 2
            let endAngle = (Float(index + 1) / Float(segmentCount)) * .pi * 2

            let outerStart = CGPoint(
                x: center.x + CGFloat(cos(startAngle) * outerRadius),
                y: center.y + CGFloat(sin(startAngle) * outerRadius)
            )
            let innerStart = CGPoint(
                x: center.x + CGFloat(cos(startAngle) * innerRadius),
                y: center.y + CGFloat(sin(startAngle) * innerRadius)
            )
            let outerEnd = CGPoint(
                x: center.x + CGFloat(cos(endAngle) * outerRadius),
                y: center.y + CGFloat(sin(endAngle) * outerRadius)
            )
            let innerEnd = CGPoint(
                x: center.x + CGFloat(cos(endAngle) * innerRadius),
                y: center.y + CGFloat(sin(endAngle) * innerRadius)
            )

            let voStart = PrimitiveVertex(position: transform.clipPoint(outerStart), color: color)
            let viStart = PrimitiveVertex(position: transform.clipPoint(innerStart), color: color)
            let voEnd = PrimitiveVertex(position: transform.clipPoint(outerEnd), color: color)
            let viEnd = PrimitiveVertex(position: transform.clipPoint(innerEnd), color: color)

            vertices.append(contentsOf: [voStart, viStart, voEnd, voEnd, viStart, viEnd])
        }
    }

    private func color(hex: String, alpha: Float = 1) -> SIMD4<Float> {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).lowercased()
        let rgb: SIMD3<Float>

        if let cached = rgbCache[sanitized] {
            rgb = cached
        } else {
            var value: UInt64 = 0
            Scanner(string: sanitized).scanHexInt64(&value)
            let parsed = SIMD3<Float>(
                Float((value >> 16) & 0xff) / 255,
                Float((value >> 8) & 0xff) / 255,
                Float(value & 0xff) / 255
            )
            rgbCache[sanitized] = parsed
            rgb = parsed
        }

        return SIMD4<Float>(rgb.x, rgb.y, rgb.z, alpha)
    }
}

private struct RenderTransform {
    let targetSize: SIMD2<Float>
    let scale: Float
    let offset: SIMD2<Float>

    init(worldSize: CGSize, targetSize: CGSize) {
        let world = SIMD2<Float>(Float(max(worldSize.width, 1)), Float(max(worldSize.height, 1)))
        self.targetSize = SIMD2<Float>(Float(max(targetSize.width, 1)), Float(max(targetSize.height, 1)))
        self.scale = max(self.targetSize.x / world.x, self.targetSize.y / world.y)
        self.offset = (self.targetSize - (world * scale)) * 0.5
    }

    func clipPoint(_ point: CGPoint) -> SIMD2<Float> {
        let scaled = SIMD2<Float>(Float(point.x), Float(point.y)) * scale + offset
        return SIMD2<Float>(
            (scaled.x / targetSize.x) * 2 - 1,
            1 - (scaled.y / targetSize.y) * 2
        )
    }
}
