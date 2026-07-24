// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "AsyncImageView",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "AsyncImageView", targets: ["AsyncImageView"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "7.1.0")
    ],
    targets: [
        .target(
            name: "AsyncImageView",
            dependencies: ["ReactiveSwift"],
            path: "AsyncImageView",
            swiftSettings: [
                // Work around https://github.com/swiftlang/swift/issues/75453.
                .unsafeFlags(["-disable-dynamic-actor-isolation"])
            ]
        ),
        .testTarget(
            name: "AsyncImageViewTests",
            dependencies: [
                "AsyncImageView"
            ],
            path: "AsyncImageViewTests",
            swiftSettings: [
                // Work around https://github.com/swiftlang/swift/issues/75453.
                .unsafeFlags(["-disable-dynamic-actor-isolation"])
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
