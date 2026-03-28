import Foundation
import UIKit

struct TyrianPickupAtlasMetadata: Decodable {
    struct Atlas: Decodable {
        let width: Int
        let height: Int
        let cellWidth: Int?
        let cellHeight: Int?
        let sourceCellWidth: Int?
        let sourceCellHeight: Int?
        let layout: String?
        let padding: Int?
    }

    struct Frame: Decodable {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }

    struct Sprite: Decodable, Identifiable {
        struct Bounds: Decodable {
            let x: Int
            let y: Int
            let width: Int
            let height: Int
        }

        let name: String
        let section: Int
        let index: Int
        let frame: Frame
        let bounds: Bounds?
        let sourceBounds: Bounds?

        var id: String { name }
    }

    let atlas: Atlas
    let sprites: [Sprite]
}

enum TyrianPickupAtlasResources {
    static let assetFolderName = "TyrianAssets"
    static let folderName = "Pickups"

    static func metadata(bundle: Bundle = .main) -> TyrianPickupAtlasMetadata? {
        guard let url = metadataURL(bundle: bundle),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return try? JSONDecoder().decode(TyrianPickupAtlasMetadata.self, from: data)
    }

    static func atlasURL(bundle: Bundle = .main) -> URL? {
        resourceURL(name: "pickup-atlas", ext: "png", bundle: bundle)
    }

    static func atlasImage(bundle: Bundle = .main) -> UIImage? {
        guard let url = atlasURL(bundle: bundle),
              let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return UIImage(data: data)
    }

    private static func metadataURL(bundle: Bundle) -> URL? {
        resourceURL(name: "pickup-metadata", ext: "json", bundle: bundle)
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
            .appendingPathComponent("TyrianOriginalPickups")
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
}
