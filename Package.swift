// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIChartsPro",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
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
