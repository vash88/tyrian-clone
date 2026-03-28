import SwiftUI
import UIKit

struct TyrianShipAtlasDebugView: View {
    private let entries = TyrianShipAtlasDebugData.entries

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "Ship Folder Missing",
                        systemImage: "photo",
                        description: Text("Could not load `TyrianAssets/Ships` from bundled resources.")
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220), spacing: 16, alignment: .top)],
                        spacing: 16
                    ) {
                        ForEach(entries) { entry in
                            TyrianShipAtlasDebugCard(entry: entry)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Ship Atlas Debug")
        }
    }
}

private struct TyrianShipAtlasDebugCard: View {
    let entry: TyrianShipAtlasDebugEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("#\(entry.id)")
                .font(.headline.monospacedDigit())

            TyrianShipAtlasDebugCanvas(entry: entry)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("Composite Grid: row \(entry.row), col \(entry.column)")

                if let bounds = entry.bounds {
                    Text("Bounds: x \(Int(bounds.minX)), y \(Int(bounds.minY)), w \(Int(bounds.width)), h \(Int(bounds.height))")
                    Text("Center: \(format(bounds.midX)), \(format(bounds.midY))")
                } else {
                    Text("Bounds: empty")
                }

                Text("Tyrian Anchor: (5, 7)")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func format(_ value: CGFloat) -> String {
        String(format: "%.1f", value)
    }
}

private struct TyrianShipAtlasDebugCanvas: View {
    let entry: TyrianShipAtlasDebugEntry

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / TyrianShipAtlasDebugData.spriteSize.width,
                            proxy.size.height / TyrianShipAtlasDebugData.spriteSize.height)
            let drawnSize = CGSize(
                width: TyrianShipAtlasDebugData.spriteSize.width * scale,
                height: TyrianShipAtlasDebugData.spriteSize.height * scale
            )
            let origin = CGPoint(
                x: (proxy.size.width - drawnSize.width) / 2,
                y: (proxy.size.height - drawnSize.height) / 2
            )

            ZStack(alignment: .topLeading) {
                if let image = entry.image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .antialiased(false)
                        .frame(width: drawnSize.width, height: drawnSize.height)
                        .position(x: origin.x + drawnSize.width / 2, y: origin.y + drawnSize.height / 2)
                }

                Rectangle()
                    .stroke(.red, lineWidth: 1)
                    .frame(width: drawnSize.width, height: drawnSize.height)
                    .position(x: origin.x + drawnSize.width / 2, y: origin.y + drawnSize.height / 2)

                if let bounds = entry.bounds {
                    Rectangle()
                        .stroke(.green, lineWidth: 1)
                        .frame(
                            width: bounds.width * scale,
                            height: bounds.height * scale
                        )
                        .position(
                            x: origin.x + bounds.midX * scale,
                            y: origin.y + bounds.midY * scale
                        )
                }

                TyrianShipAnchorMarker()
                    .stroke(.blue, lineWidth: 1.25)
                    .frame(width: 10, height: 10)
                    .position(
                        x: origin.x + TyrianShipAtlasDebugData.anchor.x * scale,
                        y: origin.y + TyrianShipAtlasDebugData.anchor.y * scale
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct TyrianShipAnchorMarker: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private struct TyrianShipAtlasDebugEntry: Identifiable {
    let id: Int
    let row: Int
    let column: Int
    let image: UIImage?
    let bounds: CGRect?
}

private enum TyrianShipAtlasDebugData {
    static let columns = 19
    static let cellSize = CGSize(width: 12, height: 14)
    static let spriteSize = CGSize(width: 24, height: 28)
    static let anchor = CGPoint(x: 5, y: 7)

    static let entries: [TyrianShipAtlasDebugEntry] = loadEntries()

    private static func loadEntries() -> [TyrianShipAtlasDebugEntry] {
        guard let metadata = TyrianShipCompositeResources.metadata()
        else {
            return []
        }

        return metadata.composites.map { composite in
            let image = TyrianShipCompositeResources.compositeImage(for: composite.index)
            let bounds = composite.bounds.map {
                CGRect(x: $0.x, y: $0.y, width: $0.width, height: $0.height)
            } ?? image?.cgImage.flatMap(alphaBounds(in:))

            return TyrianShipAtlasDebugEntry(
                id: composite.index,
                row: composite.row,
                column: composite.column,
                image: image,
                bounds: bounds
            )
        }
    }

    private nonisolated static func alphaBounds(in image: CGImage) -> CGRect? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(image, in: drawRect)

        guard let data = context.data else {
            return nil
        }

        let pixels = data.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)
        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let alpha = pixels[offset + 3]

                if alpha > 0 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard maxX >= minX, maxY >= minY else {
            return nil
        }

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }
}

#Preview {
    TyrianShipAtlasDebugView()
        .preferredColorScheme(.dark)
}
