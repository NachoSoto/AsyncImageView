// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AsyncImageView",
    platforms: [.iOS(.v13), .tvOS(.v13), .watchOS(.v9)],
    products: [
        .library(name: "AsyncImageView", targets: ["AsyncImageView"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "7.1.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.4.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "12.2.0")
    ],
    targets: [
        .target(
            name: "AsyncImageView",
            dependencies: ["ReactiveSwift"],
            path: "AsyncImageView"
        ),
        .testTarget(
            name: "AsyncImageViewTests",
            dependencies: [
                "AsyncImageView",
                "Quick",
                "Nimble"
            ],
            path: "AsyncImageViewTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
