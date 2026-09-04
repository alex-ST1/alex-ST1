// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SavingsTracker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SavingsTrackerCore",
            targets: ["SavingsTrackerCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SavingsTrackerCore",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SavingsTrackerTests",
            dependencies: ["SavingsTrackerCore"],
            path: "Tests"
        )
    ]
)
