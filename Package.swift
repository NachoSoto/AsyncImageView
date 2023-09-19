// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AsyncImageView",
    platforms: [.iOS(.v13), .tvOS(.v13), .watchOS(.v9)],
    products: [
        .library(name: "AsyncImageView", targets: ["AsyncImageView"]),
    ],
    dependencies: [
				.package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "7.1.0")
    ],
    targets: [
        .target(
            name: "AsyncImageView",
            dependencies: ["ReactiveSwift"],
            path: "AsyncImageView"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
