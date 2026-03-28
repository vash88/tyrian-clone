import Foundation
import UIKit

struct TyrianShipCompositeMetadata: Decodable {
    struct Atlas: Decodable {
        let width: Int
        let height: Int
        let spriteWidth: Int
        let spriteHeight: Int
        let columns: Int
    }

    struct Source: Decodable {
        let shp: String
        let palette: String
        let paletteIndex: Int
    }

    struct Sheet: Decodable {
        let name: String
        let cellWidth: Int
        let cellHeight: Int
        let columns: Int
        let cellCount: Int
        let compositeWidth: Int
        let compositeHeight: Int
    }

    struct Bounds: Decodable {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }

    struct Composite: Decodable, Identifiable {
        struct Frame: Decodable {
            let x: Int
            let y: Int
            let width: Int
            let height: Int
        }

        let index: Int
        let row: Int
        let column: Int
        let bounds: Bounds?
        let shipGraphicIndex: Int?
        let bankOffset: Int?
        let frame: Frame?

        var id: Int { index }
    }

    let atlas: Atlas?
    let source: Source
    let sheet: Sheet
    let composites: [Composite]
}

enum TyrianShipCompositeResources {
    static let assetFolderName = "TyrianAssets"
    static let folderName = "Ships"

    static func metadata(bundle: Bundle = .main) -> TyrianShipCompositeMetadata? {
        guard let url = metadataURL(bundle: bundle),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return try? JSONDecoder().decode(TyrianShipCompositeMetadata.self, from: data)
    }

    static func compositeURL(for index: Int, bundle: Bundle = .main) -> URL? {
        compositeResourceURL(for: String(format: "composite-%03d", index), withExtension: "png", bundle: bundle)
    }

    static func atlasURL(bundle: Bundle = .main) -> URL? {
        resourceURL(name: "ship-atlas", ext: "png", bundle: bundle)
    }

    static func atlasImage(bundle: Bundle = .main) -> UIImage? {
        guard let url = atlasURL(bundle: bundle),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return UIImage(data: data)
    }

    static func composite(for index: Int, bundle: Bundle = .main) -> TyrianShipCompositeMetadata.Composite? {
        metadata(bundle: bundle)?.composites.first { $0.index == index }
    }

    static func compositeImage(for index: Int, bundle: Bundle = .main) -> UIImage? {
        if let atlasImage = atlasImage(bundle: bundle),
           let composite = composite(for: index, bundle: bundle),
           let frame = composite.frame,
           let cropped = atlasImage.cgImage?.cropping(to: CGRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height)) {
            return UIImage(cgImage: cropped, scale: atlasImage.scale, orientation: .up)
        }

        guard let url = compositeURL(for: index, bundle: bundle),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return UIImage(data: data)
    }

    private static func metadataURL(bundle: Bundle) -> URL? {
        let folderScoped = bundle.resourceURL?
            .appendingPathComponent(assetFolderName)
            .appendingPathComponent(folderName)
            .appendingPathComponent("metadata.json")
        if let folderScoped, FileManager.default.fileExists(atPath: folderScoped.path) {
            return folderScoped
        }

        let legacyFolderScoped = bundle.resourceURL?
            .appendingPathComponent("TyrianOriginalShips")
            .appendingPathComponent("metadata.json")
        if let legacyFolderScoped, FileManager.default.fileExists(atPath: legacyFolderScoped.path) {
            return legacyFolderScoped
        }

        let bundleRoot = bundle.resourceURL?.appendingPathComponent("metadata.json")
        if let bundleRoot, FileManager.default.fileExists(atPath: bundleRoot.path) {
            return bundleRoot
        }

        return nil
    }

    private static func resourceURL(name: String, ext: String, bundle: Bundle) -> URL? {
        let folderScoped = bundle.resourceURL?
            .appendingPathComponent(assetFolderName)
            .appendingPathComponent(folderName)
            .appendingPathComponent("\(name).\(ext)")
        if let folderScoped, FileManager.default.fileExists(atPath: folderScoped.path) {
            return folderScoped
        }

        let legacyFolderScoped = bundle.resourceURL?
            .appendingPathComponent("TyrianOriginalShips")
            .appendingPathComponent("\(name).\(ext)")
        if let legacyFolderScoped, FileManager.default.fileExists(atPath: legacyFolderScoped.path) {
            return legacyFolderScoped
        }

        let bundleRoot = bundle.resourceURL?.appendingPathComponent("\(name).\(ext)")
        if let bundleRoot, FileManager.default.fileExists(atPath: bundleRoot.path) {
            return bundleRoot
        }

        return nil
    }

    private static func compositeResourceURL(for name: String, withExtension ext: String, bundle: Bundle) -> URL? {
        let folderScoped = bundle.resourceURL?
            .appendingPathComponent(assetFolderName)
            .appendingPathComponent(folderName)
            .appendingPathComponent("composites")
            .appendingPathComponent("\(name).\(ext)")
        if let folderScoped, FileManager.default.fileExists(atPath: folderScoped.path) {
            return folderScoped
        }

        let legacyFolderScoped = bundle.resourceURL?
            .appendingPathComponent("TyrianOriginalShips")
            .appendingPathComponent("composites")
            .appendingPathComponent("\(name).\(ext)")
        if let legacyFolderScoped, FileManager.default.fileExists(atPath: legacyFolderScoped.path) {
            return legacyFolderScoped
        }

        let siblingScoped = bundle.resourceURL?
            .appendingPathComponent(assetFolderName)
            .appendingPathComponent(folderName)
            .appendingPathComponent("\(name).\(ext)")
        if let siblingScoped, FileManager.default.fileExists(atPath: siblingScoped.path) {
            return siblingScoped
        }

        let legacySiblingScoped = bundle.resourceURL?
            .appendingPathComponent("TyrianOriginalShips")
            .appendingPathComponent("\(name).\(ext)")
        if let legacySiblingScoped, FileManager.default.fileExists(atPath: legacySiblingScoped.path) {
            return legacySiblingScoped
        }

        let bundleRoot = bundle.resourceURL?.appendingPathComponent("\(name).\(ext)")
        if let bundleRoot, FileManager.default.fileExists(atPath: bundleRoot.path) {
            return bundleRoot
        }

        return nil
    }
}
