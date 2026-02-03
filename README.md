# SwiftUI Charts Pro

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B%20%7C%20macOS%2013%2B-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)

**20+ Advanced Chart Types for SwiftUI** — Beyond what Apple Charts offers.

A comprehensive, production-ready charting library featuring Heatmaps, Treemaps, Sankey Diagrams, Gantt Charts, Financial Charts, and much more.

## ✨ Features

- 🎨 **20+ Chart Types** — Heatmap, Treemap, Radar, Sankey, Funnel, Gantt, Candlestick, Gauge, and more
- 🎯 **Pure SwiftUI** — Built entirely with SwiftUI for optimal performance
- 📱 **iOS 16+ & macOS 13+** — Leverages modern SwiftUI APIs
- 🎭 **8 Built-in Themes** — Dark, Light, Pastel, Vibrant, Ocean, Sunset, Forest, Monochrome
- ⚡ **Smooth Animations** — Staggered, wave, shimmer, and custom animations
- 🔍 **Interactive** — Zoom, pan, selection, tooltips, and brushing
- ♿ **Accessible** — VoiceOver support with meaningful labels
- 📤 **Export** — PNG, JPEG, and PDF export capabilities
- 📊 **Statistical Functions** — Mean, median, correlation, regression, and more

## 📦 Installation

### Swift Package Manager

Add SwiftUI Charts Pro to your project via SPM:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftUI-Charts-Pro.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Packages → Enter the repository URL.

## 🚀 Quick Start

```swift
import SwiftUI
import SwiftUIChartsPro

struct ContentView: View {
    let data = [
        RadarDataSeries(name: "Product A", values: [80, 90, 70, 60, 85]),
        RadarDataSeries(name: "Product B", values: [70, 80, 90, 75, 65])
    ]
    
    var body: some View {
        RadarChart(
            data: data,
            labels: ["Speed", "Quality", "Price", "Support", "Features"]
        )
        .chartTheme(.dark)
        .frame(height: 350)
        .padding()
    }
}
```

## 📊 Available Charts

### Data Distribution

| Chart | Description | Use Case |
|-------|-------------|----------|
| **HeatmapChart** | Color-coded matrix | Correlation matrices, activity maps |
| **BoxPlotChart** | Statistical quartiles | Data distribution analysis |
| **ViolinChart** | Kernel density + box plot | Distribution shape visualization |

### Hierarchical

| Chart | Description | Use Case |
|-------|-------------|----------|
| **TreemapChart** | Nested rectangles | File sizes, budget breakdown |
| **SunburstChart** | Radial hierarchy | Organizational structure |

### Flow & Relationships

| Chart | Description | Use Case |
|-------|-------------|----------|
| **SankeyChart** | Flow diagram | User journeys, budget flows |
| **ChordDiagram** | Circular connections | Migration patterns, dependencies |
| **FunnelChart** | Sequential stages | Sales pipeline, conversion rates |

### Multi-dimensional

| Chart | Description | Use Case |
|-------|-------------|----------|
| **RadarChart** | Spider/polar chart | Performance comparison |
| **ParallelCoordinatesChart** | Multiple axes | High-dimensional data |
| **BubbleChart** | XY + size dimension | Three-variable comparison |

### Time-based

| Chart | Description | Use Case |
|-------|-------------|----------|
| **GanttChart** | Timeline scheduling | Project management |
| **CandlestickChart** | OHLC financial | Stock analysis |
| **WaterfallChart** | Cumulative changes | Financial statements |

### Single Value

| Chart | Description | Use Case |
|-------|-------------|----------|
| **GaugeChart** | Meter/speedometer | KPIs, dashboards |
| **WordCloudChart** | Text frequency | Tag clouds, keyword analysis |

## 🎨 Theming

Apply consistent styling across your charts:

```swift
// Built-in themes
myChart.chartTheme(.dark)
myChart.chartTheme(.pastel)
myChart.chartTheme(.vibrant)
myChart.chartTheme(.ocean)

// Custom theme
let customTheme = ChartThemeBuilder()
    .backgroundColor(.black)
    .accentColor(.cyan)
    .palette([.cyan, .mint, .teal, .green])
    .animationDuration(0.8)
    .build()

myChart.chartTheme(customTheme)
```

## 🔧 Configuration

Fine-tune chart behavior:

```swift
// Axis configuration
.chartXAxis(AxisConfiguration(
    showAxisLine: true,
    tickCount: 10,
    title: "Revenue ($)"
))

// Grid configuration
.chartGrid(GridConfiguration.dashed)

// Legend configuration
.chartLegend(LegendConfiguration(
    position: .bottom,
    isInteractive: true
))
```

## 🖱️ Interactions

Enable rich interactivity:

```swift
// Zoom and pan
@StateObject var zoomManager = ChartZoomManager()

myChart
    .chartZoom(manager: zoomManager)

// Selection
@StateObject var selection = ChartSelectionManager<String>()

myChart
    .onChartSelection { point in
        selection.select(point.id)
    }
```

## 📤 Export

Export charts as images:

```swift
let exporter = ChartExporter()

// Export to UIImage
if let image = await exporter.exportToImage(
    view: myChart,
    size: CGSize(width: 800, height: 600),
    quality: .high
) {
    // Use image
}

// Export to data (PNG, JPEG, or PDF)
if let result = await exporter.exportToData(
    view: myChart,
    size: CGSize(width: 800, height: 600),
    format: .png
) {
    // Save result.data
}
```

## 📐 Chart Examples

### Heatmap Chart

```swift
let data = [
    [1.0, 2.0, 3.0, 4.0],
    [2.0, 4.0, 6.0, 8.0],
    [3.0, 6.0, 9.0, 12.0]
]

HeatmapChart(
    data: data,
    rowLabels: ["A", "B", "C"],
    columnLabels: ["Q1", "Q2", "Q3", "Q4"],
    colorRange: (.blue.opacity(0.1), .blue)
)
```

### Sankey Chart

```swift
let connections = [
    FlowConnection(source: "Budget", target: "Marketing", value: 300),
    FlowConnection(source: "Budget", target: "Development", value: 500),
    FlowConnection(source: "Marketing", target: "Online", value: 200)
]

SankeyChart(connections: connections)
```

### Gantt Chart

```swift
let tasks = [
    GanttTask.from(name: "Design", daysFromNow: 0, duration: 5, progress: 0.8),
    GanttTask.from(name: "Development", daysFromNow: 3, duration: 10, progress: 0.4),
    GanttTask.from(name: "Testing", daysFromNow: 10, duration: 5, progress: 0)
]

GanttChart(tasks: tasks)
```

### Gauge Chart

```swift
GaugeChart(
    value: 72,
    maxValue: 100,
    label: "CPU Usage",
    style: .speedometer,
    unit: "%"
)
```

## 📊 Statistical Utilities

Built-in math functions for data analysis:

```swift
import SwiftUIChartsPro

let values = [10.0, 20.0, 30.0, 40.0, 50.0]

// Basic statistics
let mean = ChartMath.mean(values)           // 30.0
let median = ChartMath.median(values)       // 30.0
let std = ChartMath.standardDeviation(values)

// Correlation & regression
let r = ChartMath.correlation(x, y)
let regression = ChartMath.linearRegression(x, y)

// Quartiles
let quartiles = ChartMath.quartiles(values) // (q1, q2, q3)

// Normalization
let normalized = ChartMath.normalize(values) // [0, 0.25, 0.5, 0.75, 1.0]
```

## ♿ Accessibility

All charts support VoiceOver:

```swift
myChart
    .chartAccessibility(
        label: "Sales Chart",
        hint: "Double tap to select data points",
        value: "Showing Q1 through Q4 2024"
    )
```

## 🏗️ Architecture

```
SwiftUIChartsPro/
├── Core/
│   ├── ChartView.swift         # Base chart view & protocols
│   ├── ChartDataSet.swift      # Data models
│   ├── ChartTheme.swift        # Theming system
│   └── ChartConfiguration.swift # Configuration options
├── Charts/
│   ├── HeatmapChart.swift
│   ├── TreemapChart.swift
│   ├── RadarChart.swift
│   └── ... (16 more chart types)
├── Interaction/
│   ├── ChartTooltip.swift
│   ├── ChartSelection.swift
│   └── ChartZoom.swift
├── Animation/
│   └── ChartAnimation.swift
├── Export/
│   └── ChartExporter.swift
├── Accessibility/
│   └── ChartAccessibility.swift
├── Utilities/
│   └── ChartMath.swift
└── Extensions/
    └── Color+Charts.swift
```

## 📋 Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## 📄 License

SwiftUI Charts Pro is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📬 Contact

- GitHub: [@muhittincamdali](https://github.com/muhittincamdali)

---

Made with ❤️ for the SwiftUI community
