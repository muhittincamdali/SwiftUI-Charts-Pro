// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIChartsPro",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "SwiftUIChartsPro",
            targets: ["SwiftUIChartsPro"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIChartsPro",
            path: "Sources/SwiftUIChartsPro"
        ),
        .testTarget(
            name: "SwiftUIChartsProTests",
            dependencies: ["SwiftUIChartsPro"],
            path: "Tests/SwiftUIChartsProTests"
        )
    ]
)
