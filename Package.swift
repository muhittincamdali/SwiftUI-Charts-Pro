// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIChartsPro",
    platforms: [
        .iOS(.v15),          // iOS 15+ backward compatibility (Apple Charts requires iOS 16+)
        .macOS(.v12),        // macOS 12+ support
        .watchOS(.v8),       // watchOS 8+ support
        .tvOS(.v15),         // tvOS 15+ support
        .visionOS(.v1)       // visionOS support
    ],
    products: [
        .library(
            name: "SwiftUIChartsPro",
            targets: ["SwiftUIChartsPro"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftUIChartsPro",
            dependencies: [],
            path: "Sources/SwiftUIChartsPro",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftUIChartsProTests",
            dependencies: ["SwiftUIChartsPro"],
            path: "Tests/SwiftUIChartsProTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
