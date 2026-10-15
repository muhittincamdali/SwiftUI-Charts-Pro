<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Data-Visualization/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Data-Visualization/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Data-Visualization/master/.github/brand/banner-light.svg" alt="SwiftUI Data Visualization: Statistical, financial and live charts for SwiftUI on iOS and macOS, built on Swift Charts."></picture></p>

<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a></p>

# SwiftUI Charts Pro has moved

This project now lives in [SwiftUI-Data-Visualization](https://github.com/muhittincamdali/SwiftUI-Data-Visualization). This repository is archived and no longer receives changes.

The box plot, candlestick, heatmap, waterfall, radar and treemap charts, and the live ticker, were rewritten there for Swift 6 and Swift Charts, with tests. Not every chart from this repository was carried over; the [changelog](https://github.com/muhittincamdali/SwiftUI-Data-Visualization/blob/master/CHANGELOG.md) lists which ones were left out and why.

- Charts: [Sources/SwiftUIDataVisualization/Charts](https://github.com/muhittincamdali/SwiftUI-Data-Visualization/tree/master/Sources/SwiftUIDataVisualization/Charts)
- Live data: [Sources/SwiftUIDataVisualization/Streaming](https://github.com/muhittincamdali/SwiftUI-Data-Visualization/tree/master/Sources/SwiftUIDataVisualization/Streaming)
- Documentation: [SwiftUIDataVisualization](https://muhittincamdali.github.io/SwiftUI-Data-Visualization/documentation/swiftuidatavisualization/)

## Install the new package

The new package needs iOS 17+ or macOS 14+.

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftUI-Data-Visualization.git", from: "2.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "SwiftUIDataVisualization", package: "SwiftUI-Data-Visualization")
    ])
]
```

Every public type changed between the two packages, so moving over means renaming imports and call sites. The old code stays here, unchanged, for reference.
