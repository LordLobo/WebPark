// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "WebLeopard",
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
