# SwiftUI Charts Pro

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)

Advanced chart types for SwiftUI that go beyond the built-in Charts framework. Heatmaps, radar charts, Sankey diagrams, Gantt charts, candlestick charts, and more — all built with pure SwiftUI and `Canvas`.

---

## Features

- **Heatmap Chart** — Grid-based data visualization with customizable color scales
- **Radar Chart** — Multi-axis comparison with filled or stroked polygons
- **Sankey Diagram** — Flow visualization between categories
- **Funnel Chart** — Conversion pipeline visualization
- **Gantt Chart** — Project timeline and task scheduling
- **Candlestick Chart** — Financial OHLC data rendering
- **Gauge Chart** — Circular and linear progress indicators
- **Bubble Chart** — Three-dimensional data on a 2D plane
- **Word Cloud** — Text frequency visualization with automatic layout
- **Interactive Tooltips** — Touch-driven data inspection
- **Export** — Render any chart to PNG or PDF

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 16.0+          |
| macOS    | 13.0+          |
| tvOS     | 16.0+          |
| watchOS  | 9.0+           |

## Installation

### Swift Package Manager

Add to your project through Xcode:

1. **File → Add Package Dependencies**
2. Enter:
   ```
   https://github.com/muhittincamdali/SwiftUI-Charts-Pro.git
   ```
3. Select **Up to Next Major Version** from `1.0.0`

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftUI-Charts-Pro.git", from: "1.0.0")
]
```

## Quick Start

### Heatmap

```swift
import SwiftUIChartsPro

let data = HeatmapData(
    rows: ["Mon", "Tue", "Wed", "Thu", "Fri"],
    columns: ["9AM", "12PM", "3PM", "6PM"],
    values: [
        [0.2, 0.8, 0.5, 0.3],
        [0.6, 0.9, 0.4, 0.1],
        [0.3, 0.7, 0.8, 0.5],
        [0.9, 0.4, 0.6, 0.2],
        [0.1, 0.3, 0.7, 0.9]
    ]
)

HeatmapChart(data: data)
    .heatmapColorScale(.blue, .red)
    .frame(height: 300)
```

### Radar Chart

```swift
let axes = ["Speed", "Power", "Defense", "Agility", "Stamina"]
let series = [
    RadarSeries(name: "Player A", values: [0.9, 0.7, 0.5, 0.8, 0.6], color: .blue),
    RadarSeries(name: "Player B", values: [0.5, 0.8, 0.9, 0.4, 0.7], color: .red)
]

RadarChart(axes: axes, series: series)
    .radarStyle(.filled(opacity: 0.3))
    .frame(width: 300, height: 300)
```

### Candlestick Chart

```swift
let candles = [
    CandlestickData(date: date1, open: 150, high: 155, low: 148, close: 153),
    CandlestickData(date: date2, open: 153, high: 158, low: 151, close: 156),
    // ...
]

CandlestickChart(data: candles)
    .candlestickColors(up: .green, down: .red)
    .frame(height: 400)
```

### Gantt Chart

```swift
let tasks = [
    GanttTask(name: "Design", start: day(1), end: day(5), color: .blue),
    GanttTask(name: "Development", start: day(3), end: day(12), color: .green),
    GanttTask(name: "Testing", start: day(10), end: day(15), color: .orange),
    GanttTask(name: "Launch", start: day(15), end: day(16), color: .red)
]

GanttChart(tasks: tasks)
    .ganttShowDependencies(true)
    .frame(height: 300)
```

### Bubble Chart

```swift
let bubbles = [
    BubbleData(x: 10, y: 20, size: 30, label: "A"),
    BubbleData(x: 40, y: 50, size: 15, label: "B"),
    BubbleData(x: 70, y: 30, size: 45, label: "C")
]

BubbleChart(data: bubbles)
    .bubbleColor(.blue.opacity(0.6))
    .frame(height: 300)
```

### Exporting

```swift
let exporter = ChartExporter()

// Export to PNG
if let image = exporter.renderToPNG(chart: myChart, size: CGSize(width: 800, height: 600)) {
    // Save or share
}

// Export to PDF
if let pdfData = exporter.renderToPDF(chart: myChart, size: CGSize(width: 800, height: 600)) {
    // Save or share
}
```

## Chart Types Reference

| Chart | Use Case | Data Dimensions |
|-------|----------|-----------------|
| `HeatmapChart` | Density, correlation | 2D grid + intensity |
| `RadarChart` | Multi-metric comparison | N axes + values |
| `SankeyChart` | Flow between categories | Source → Target + weight |
| `FunnelChart` | Conversion pipelines | Stages + values |
| `GanttChart` | Project timelines | Tasks + dates |
| `CandlestickChart` | Financial OHLC | Date + OHLC values |
| `GaugeChart` | Progress/KPIs | Value + range |
| `BubbleChart` | 3D data on 2D plane | X + Y + Size |
| `WordCloudChart` | Text frequency | Words + counts |

## Tooltips

All charts support interactive tooltips:

```swift
HeatmapChart(data: data)
    .chartTooltip { point in
        VStack {
            Text(point.label)
                .font(.headline)
            Text("Value: \(point.value, specifier: "%.1f")")
        }
    }
```

## Architecture

```
SwiftUIChartsPro/
├── Core/
│   ├── ChartView.swift           # Base chart view protocol
│   └── ChartDataSet.swift        # Data set abstraction
├── Charts/
│   ├── HeatmapChart.swift        # Grid-based heatmap
│   ├── RadarChart.swift          # Spider/radar chart
│   ├── SankeyChart.swift         # Flow diagram
│   ├── FunnelChart.swift         # Funnel visualization
│   ├── GanttChart.swift          # Timeline chart
│   ├── CandlestickChart.swift    # Financial chart
│   ├── GaugeChart.swift          # Gauge/dial chart
│   ├── BubbleChart.swift         # Bubble scatter chart
│   └── WordCloudChart.swift      # Word cloud
├── Interaction/
│   └── ChartTooltip.swift        # Tooltip system
└── Export/
    └── ChartExporter.swift       # PNG/PDF export
```

## Customization

Every chart exposes view modifiers for styling:

```swift
RadarChart(axes: axes, series: series)
    .radarGridColor(.gray.opacity(0.3))
    .radarAxisLabelFont(.caption)
    .radarStyle(.stroked(lineWidth: 2))
    .radarShowValues(true)
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-chart`)
3. Commit your changes (`git commit -m 'feat: add treemap chart'`)
4. Push to the branch (`git push origin feature/new-chart`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Author

**Muhittin Camdali** — [@muhittincamdali](https://github.com/muhittincamdali)
