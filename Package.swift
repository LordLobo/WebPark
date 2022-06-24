// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "WebPark",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "WebPark",
            targets: ["WebPark"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "WebPark",
            dependencies: []),
        .testTarget(
            name: "WebParkTests",
            dependencies: ["WebPark"]),
    ]
)
