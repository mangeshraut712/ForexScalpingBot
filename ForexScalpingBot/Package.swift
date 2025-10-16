// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ForexScalpingBot",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ForexScalpingBot", targets: ["ForexScalpingBot"])
    ],
    dependencies: [
        // Add any SwiftPM dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "ForexScalpingBot",
            dependencies: [],
            path: ".",
            sources: [
                "ForexScalpingBotApp.swift",
                "Models",
                "Services", 
                "ViewModels",
                "Views"
            ],
            resources: []
        )
    ]
)
