// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WebPark",
    platforms: [
        .macOS(.v12),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "WebPark",
            targets: ["WebPark"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "WebPark",
            dependencies: []),
        .testTarget(
            name: "WebParkTests",
            dependencies: ["WebPark"]),
    ]
)
