// swift-tools-version: 6.2
// 6.2 is the minimum that provides the `.v26` platform constants used below. Do not raise
// this to match whatever Xcode is installed locally: Swift 6.4 ships only with Xcode 27,
// which is not available on GitHub-hosted runners or as a public Docker image, so a higher
// tools version makes the package unbuildable in CI.
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
