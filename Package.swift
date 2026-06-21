// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LLMProviderKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "LLMProviderKit",
            targets: ["LLMProviderKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tyh94/Storage.git", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "LLMProviderKit",
            dependencies: [
                "Storage"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LLMProviderKitTests",
            dependencies: ["LLMProviderKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
