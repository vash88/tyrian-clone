// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TyrianCloneCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "TyrianGameCore",
            targets: ["TyrianGameCore"]
        )
    ],
    targets: [
        .target(
            name: "TyrianGameCore",
            path: "TyrianClone/TyrianClone",
            exclude: [
                "App/AppModel.swift",
                "App/TyrianCloneApp.swift",
                "Assets.xcassets",
                "Features",
                "Rendering",
                "Shared/Timing"
            ],
            sources: [
                "App/AppScreen.swift",
                "GameCore",
                "Shared/Math"
            ]
        ),
        .testTarget(
            name: "TyrianGameCoreTests",
            dependencies: ["TyrianGameCore"],
            path: "Tests/TyrianGameCoreTests"
        )
    ]
)
