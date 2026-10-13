// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "gwm",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "GridCore"),
        .testTarget(name: "GridCoreTests", dependencies: ["GridCore"]),
    ]
)
