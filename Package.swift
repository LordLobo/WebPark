// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "WebPark",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
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
            ]
        ),
        .testTarget(
            name: "WebParkTests",
            dependencies: ["WebPark"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
