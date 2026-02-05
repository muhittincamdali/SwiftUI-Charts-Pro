# SwiftUI Charts Pro

<p align="center">
  <img src="https://img.shields.io/badge/iOS-15.0+-blue?style=for-the-badge&logo=apple" alt="iOS 15+">
  <img src="https://img.shields.io/badge/macOS-12.0+-blue?style=for-the-badge&logo=apple" alt="macOS 12+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge&logo=swift" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
</p>

<p align="center">
  <strong>The most comprehensive charting library for SwiftUI</strong><br>
  20+ chart types • iOS 15+ support • 1M+ data points • Real-time streaming
</p>

---

## Why SwiftUI Charts Pro?

| Feature | Apple Charts | SwiftUI Charts Pro |
|---------|:------------:|:------------------:|
| Minimum iOS | 16.0 | **15.0** ✅ |
| Chart Types | 5 | **20+** ✅ |
| Real-time Streaming | ❌ | ✅ |
| 1M+ Data Points | ❌ | ✅ |
| Export (PNG/PDF/SVG) | ❌ | ✅ |
| Interactive Zoom/Pan | Limited | **Full** ✅ |
| Audio Graphs (A11y) | ❌ | ✅ |
| Custom Themes | Limited | **Unlimited** ✅ |

## Chart Types

### Basic Charts
- **LineChart** - Animated multi-series line charts with gradients
- **BarChart** - Grouped, stacked, and percent-stacked bars
- **PieChart** - Pie and donut charts with labels
- **AreaChart** - Stacked, overlapped, and stream graphs
- **ScatterPlot** - Scatter plots with trend lines and clustering

### Advanced Charts
- **RadarChart** - Spider/radar charts for comparison
- **CandlestickChart** - Financial OHLC charts
- **HeatmapChart** - 2D heatmaps with color scales
- **TreemapChart** - Hierarchical space-filling visualization
- **SankeyChart** - Flow diagrams for value transfer
- **FunnelChart** - Conversion funnel analysis
- **GaugeChart** - Circular and linear gauges
- **BoxPlotChart** - Statistical distribution visualization
- **BubbleChart** - Multi-dimensional bubble charts
- **WaterfallChart** - Cumulative effect analysis
- **GanttChart** - Project timeline visualization
- **SunburstChart** - Hierarchical radial visualization
- **ChordDiagram** - Relationship flow visualization
- **ViolinChart** - Distribution density visualization
- **ParallelCoordinates** - Multi-variate comparison

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/muhittinc/SwiftUI-Charts-Pro.git", from: "2.0.0")
]
```

### CocoaPods

```ruby
pod 'SwiftUIChartsPro', '~> 2.0'
```

## Quick Start

```swift
import SwiftUIChartsPro

struct DashboardView: View {
    let revenueData = [
        LineDataSeries(name: "2024", values: [120, 150, 180, 200, 220, 250], color: .blue),
        LineDataSeries(name: "2023", values: [100, 130, 150, 170, 190, 210], color: .gray)
    ]
    
    var body: some View {
        LineChart(
            data: revenueData,
            labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        )
        .showArea(true)
        .chartTheme(.midnight)
        .chartAnimation(.spring)
        .chartInteractive(maxZoom: 5.0)
        .chartAccessibility(label: "Revenue comparison chart")
        .frame(height: 300)
    }
}
```

## Features

### 📊 Real-Time Data Streaming

```swift
@StateObject var stream = RealTimeDataStream<Double>(
    windowSize: 100,
    updateFrequency: .fps60
)

var body: some View {
    RealTimeLineChart(stream: stream)
        .onAppear {
            stream.start()
            // Push data from sensors, WebSocket, etc.
        }
}
```

### 🚀 High-Performance Rendering (1M+ Points)

```swift
let renderer = HighPerformanceRenderer(
    data: massiveDataset,
    samplingStrategy: .largestTriangle(buckets: 1000)
)

// Automatic downsampling for smooth 60fps
let optimizedData = renderer.optimizedData(targetPoints: 1000)
```

### 🎨 Custom Themes

```swift
let customTheme = ChartTheme(
    name: "Brand",
    colorPalette: [.purple, .pink, .orange],
    backgroundColor: .black,
    foregroundColor: .white,
    gridColor: .gray.opacity(0.3),
    animationDuration: 0.5
)

LineChart(data: data)
    .chartTheme(customTheme)
```

### 📤 Export to PNG/PDF/SVG

```swift
let exporter = ChartExporter()

// Export to PNG
let pngData = try await exporter.exportToPNG(
    view: myChart,
    size: CGSize(width: 1200, height: 800),
    options: .init(scale: 2.0)
)

// Export to PDF
let pdfData = try await exporter.exportToPDF(view: myChart, size: size)

// Export to SVG
let svg = try exporter.exportToSVG(chartData: lineData, size: size)
```

### 🔍 Interactive Zoom & Pan

```swift
LineChart(data: largeDataset)
    .chartInteractive(
        minZoom: 1.0,
        maxZoom: 10.0,
        showZoomControls: true,
        onRangeChange: { range in
            print("Visible: \(range)")
        }
    )
```

### ♿ Full Accessibility Support

```swift
PieChart(data: marketShare)
    .chartAccessibility(
        label: "Market share distribution",
        summary: "Shows company market share across 5 segments"
    )
    .chartHighContrast()  // Auto high-contrast colors
    .chartReducedMotion() // Respects system preference
```

## Animation Presets

```swift
.chartAnimation(.quick)     // 0.2s snappy
.chartAnimation(.smooth)    // 0.5s ease-in-out
.chartAnimation(.spring)    // Bouncy spring
.chartAnimation(.elastic)   // Overshoot
.chartAnimation(.dramatic)  // Cinematic entrance
.chartAnimation(.staggered) // Sequential reveal
```

## Performance Benchmarks

| Data Points | Render Time | FPS |
|-------------|-------------|-----|
| 1,000 | 2ms | 60 |
| 10,000 | 5ms | 60 |
| 100,000 | 12ms | 60 |
| 1,000,000 | 25ms | 40 |

*Tested on iPhone 15 Pro, using LTTB downsampling*

## Platform Support

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 15.0 |
| macOS | 12.0 |
| watchOS | 8.0 |
| tvOS | 15.0 |
| visionOS | 1.0 |

## Documentation

Full documentation is available at our [Documentation Portal](https://muhittinc.github.io/SwiftUI-Charts-Pro/).

- [Getting Started Guide](https://muhittinc.github.io/SwiftUI-Charts-Pro/getting-started)
- [Chart Types Reference](https://muhittinc.github.io/SwiftUI-Charts-Pro/chart-types)
- [Theming Guide](https://muhittinc.github.io/SwiftUI-Charts-Pro/theming)
- [Performance Optimization](https://muhittinc.github.io/SwiftUI-Charts-Pro/performance)
- [Accessibility Guide](https://muhittinc.github.io/SwiftUI-Charts-Pro/accessibility)

## Examples

Check out our example app in the `/Examples` directory for comprehensive usage examples.

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

## License

SwiftUI Charts Pro is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

---

<p align="center">
  Made with ❤️ for the SwiftUI community
</p>
