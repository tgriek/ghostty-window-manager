// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "gwm",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(name: "GridCore"),
        .executableTarget(
            name: "gwm",
            dependencies: [
                "GridCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            // AppKit/AX globals and NSAppleScript are main-thread APIs; the CLI is
            // single-threaded, so Swift 5 mode avoids actor-isolation noise.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "GridCoreTests", dependencies: ["GridCore"]),
    ]
)
