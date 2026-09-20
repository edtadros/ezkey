// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ezkey",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "ezkey", targets: ["ezkey"]),
        .library(name: "EZKeyCore", targets: ["EZKeyCore"]),
    ],
    targets: [
        .target(
            name: "EZKeyCore",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Security"),
            ]
        ),
        .executableTarget(
            name: "ezkey",
            dependencies: ["EZKeyCore"]
        ),
        .testTarget(
            name: "EZKeyCoreTests",
            dependencies: ["EZKeyCore"]
        ),
    ]
)
