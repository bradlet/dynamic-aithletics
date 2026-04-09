// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AICoachCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AICoachCore", targets: ["AICoachCore"]),
    ],
    targets: [
        .target(name: "AICoachCore"),
        .testTarget(
            name: "AICoachCoreTests",
            dependencies: ["AICoachCore"]
        ),
    ]
)
