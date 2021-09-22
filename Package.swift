// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "AsyncImageView",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "AsyncImageView", targets: ["AsyncImageView"]),
    ],
    dependencies: [
				.package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.1.0")
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
