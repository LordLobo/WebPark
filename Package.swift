// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "WebLeopard",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "WebLeopard",
            targets: ["WebLeopard"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "WebLeopard",
            dependencies: []),
        .testTarget(
            name: "WebLeopardTests",
            dependencies: ["WebLeopard"]),
    ]
)
