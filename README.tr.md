<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Data-Visualization/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Data-Visualization/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Data-Visualization/master/.github/brand/banner-light.svg" alt="SwiftUI Data Visualization: iOS ve macOS için Swift Charts üzerine kurulu istatistik, finans ve canlı veri grafikleri."></picture></p>

<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a></p>

# SwiftUI Charts Pro taşındı

Bu proje artık [SwiftUI-Data-Visualization](https://github.com/muhittincamdali/SwiftUI-Data-Visualization) deposunda yaşıyor. Bu depo arşivlendi ve artık değişiklik almıyor.

Box plot, candlestick, heatmap, waterfall, radar ve treemap grafikleri ile canlı ticker, orada Swift 6 ve Swift Charts için yeniden yazıldı ve testlerle desteklendi. Bu depodaki her grafik taşınmadı; hangilerinin dışarıda kaldığını ve nedenini [değişiklik günlüğü](https://github.com/muhittincamdali/SwiftUI-Data-Visualization/blob/master/CHANGELOG.md) listeliyor.

- Grafikler: [Sources/SwiftUIDataVisualization/Charts](https://github.com/muhittincamdali/SwiftUI-Data-Visualization/tree/master/Sources/SwiftUIDataVisualization/Charts)
- Canlı veri: [Sources/SwiftUIDataVisualization/Streaming](https://github.com/muhittincamdali/SwiftUI-Data-Visualization/tree/master/Sources/SwiftUIDataVisualization/Streaming)
- Dokümantasyon: [SwiftUIDataVisualization](https://muhittincamdali.github.io/SwiftUI-Data-Visualization/documentation/swiftuidatavisualization/)

## Yeni paketi kurun

Yeni paket iOS 17+ veya macOS 14+ gerektirir.

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

İki paket arasında tüm public tipler değişti; geçiş import'ları ve çağrı yerlerini yeniden adlandırmayı gerektirir. Eski kod referans için burada olduğu gibi duruyor.
