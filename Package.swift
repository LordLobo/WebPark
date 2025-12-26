// swift-tools-version: 6.2
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
    dependencies: [ ],
    targets: [
        .target(
            name: "WebPark",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "WebParkTests",
            dependencies: ["WebPark"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
