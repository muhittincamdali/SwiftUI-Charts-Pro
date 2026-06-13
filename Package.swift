// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUIChartsPro",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SwiftUIChartsPro", targets: ["SwiftUIChartsPro"]),
    ],
    targets: [
        .target(
            name: "SwiftUIChartsPro",
            path: "Sources/SwiftUIChartsPro",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftUIChartsProTests",
            dependencies: ["SwiftUIChartsPro"]
        )
    ]
)
