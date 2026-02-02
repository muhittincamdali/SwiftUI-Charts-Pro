# SwiftUI-Charts-Pro

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Advanced chart types for SwiftUI that go beyond the built-in Charts framework. Heatmaps, treemaps, radar charts, Sankey diagrams, Gantt charts, candlestick charts, and more.

---

## ✨ Features

- **10+ Chart Types** — Specialized charts not available in Apple's Charts framework
- **Interactive** — Tooltips, selection, zoom, and pan gestures
- **Themeable** — Consistent styling with customizable color palettes
- **Export** — Save charts as PNG, PDF, or SVG
- **Accessible** — Full VoiceOver support with data descriptions
- **Lightweight** — Pure SwiftUI, zero dependencies
- **Animated** — Smooth enter/update/exit transitions

---

## 📦 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftUI-Charts-Pro.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and paste:
```
https://github.com/muhittincamdali/SwiftUI-Charts-Pro.git
```

---

## 🚀 Quick Start

### Heatmap Chart

```swift
import SwiftUIChartsPro

struct HeatmapExample: View {
    let data: [[Double]] = [
        [0.1, 0.5, 0.9, 0.3],
        [0.8, 0.2, 0.6, 0.7],
        [0.4, 0.9, 0.1, 0.5],
    ]

    var body: some View {
        HeatmapChart(
            data: data,
            rowLabels: ["Mon", "Tue", "Wed"],
            columnLabels: ["Q1", "Q2", "Q3", "Q4"],
            colorRange: (.blue, .red)
        )
        .frame(height: 300)
    }
}
```

### Radar Chart

```swift
struct RadarExample: View {
    let dataset = ChartDataSet(
        label: "Player Stats",
        values: [85, 92, 78, 65, 88, 70],
        color: .blue
    )

    var body: some View {
        RadarChart(
            dataSets: [dataset],
            categories: ["Speed", "Power", "Accuracy", "Defense", "Stamina", "Agility"]
        )
        .frame(height: 300)
    }
}
```

### Candlestick Chart

```swift
struct CandlestickExample: View {
    var body: some View {
        CandlestickChart(
            candles: sampleCandles,
            bullColor: .green,
            bearColor: .red
        )
        .frame(height: 400)
    }
}
```

---

## 📊 Available Charts

| Chart | Description | Use Case |
|-------|-------------|----------|
| `HeatmapChart` | Color-coded matrix grid | Correlation data, activity calendars |
| `TreemapChart` | Nested rectangles by proportion | Disk usage, portfolio allocation |
| `RadarChart` | Spider/radar polygon chart | Multi-variable comparison |
| `SankeyChart` | Flow diagram with weighted links | Budget flows, user journeys |
| `FunnelChart` | Funnel-shaped stages | Conversion funnels, pipelines |
| `GanttChart` | Horizontal bar timeline | Project schedules, timelines |
| `CandlestickChart` | OHLC financial chart | Stock/crypto price data |
| `GaugeChart` | Circular gauge/meter | KPIs, progress meters |
| `BubbleChart` | Scatter with variable size | 3-dimensional data comparison |
| `WordCloudChart` | Weighted word visualization | Text analysis, tag clouds |

---

## 🎨 Theming

```swift
let theme = ChartTheme(
    backgroundColor: .white,
    foregroundColor: .primary,
    accentColor: .blue,
    gridColor: .gray.opacity(0.2),
    palette: [.blue, .green, .orange, .purple, .red],
    font: .system(size: 12),
    titleFont: .headline,
    animationDuration: 0.5
)

HeatmapChart(data: data)
    .chartTheme(theme)
```

---

## 💡 Tooltips & Interaction

```swift
RadarChart(dataSets: datasets, categories: categories)
    .chartTooltip { value, label in
        VStack {
            Text(label).font(.caption.bold())
            Text(String(format: "%.1f", value))
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    .onChartSelection { index, value in
        print("Selected: \(index) = \(value)")
    }
```

---

## 📤 Export

```swift
let exporter = ChartExporter()

// Export as PNG
if let image = exporter.renderToImage(chart: myChart, size: CGSize(width: 800, height: 600)) {
    // Save or share
}

// Export as PDF
if let pdfData = exporter.renderToPDF(chart: myChart, size: CGSize(width: 800, height: 600)) {
    // Save or share
}
```

---

## 🔧 Advanced Examples

### Sankey Diagram

```swift
let nodes: [SankeyNode] = [
    SankeyNode(id: "budget", label: "Budget", color: .blue),
    SankeyNode(id: "marketing", label: "Marketing", color: .green),
    SankeyNode(id: "engineering", label: "Engineering", color: .orange),
    SankeyNode(id: "sales", label: "Sales", color: .purple),
]

let links: [SankeyLink] = [
    SankeyLink(source: "budget", target: "marketing", value: 30),
    SankeyLink(source: "budget", target: "engineering", value: 50),
    SankeyLink(source: "budget", target: "sales", value: 20),
]

SankeyChart(nodes: nodes, links: links)
    .frame(height: 400)
```

### Gantt Chart

```swift
let tasks: [GanttTask] = [
    GanttTask(id: "design", label: "Design", start: startDate, end: designEnd, color: .blue),
    GanttTask(id: "develop", label: "Development", start: designEnd, end: devEnd, color: .green),
    GanttTask(id: "test", label: "Testing", start: devEnd, end: testEnd, color: .orange),
    GanttTask(id: "launch", label: "Launch", start: testEnd, end: launchEnd, color: .red),
]

GanttChart(tasks: tasks, showToday: true)
    .frame(height: 300)
```

### Treemap

```swift
let items: [TreemapItem] = [
    TreemapItem(label: "Photos", value: 45, color: .blue),
    TreemapItem(label: "Videos", value: 30, color: .green),
    TreemapItem(label: "Apps", value: 15, color: .orange),
    TreemapItem(label: "Documents", value: 10, color: .purple),
]

TreemapChart(items: items)
    .frame(height: 300)
```

---

## 📐 Architecture

```
SwiftUIChartsPro/
├── Core/
│   ├── ChartView.swift          # Base chart view protocol
│   ├── ChartDataSet.swift       # Data models
│   └── ChartTheme.swift         # Theming system
├── Charts/
│   ├── HeatmapChart.swift       # Color-coded matrix
│   ├── TreemapChart.swift       # Proportional rectangles
│   ├── RadarChart.swift         # Spider/radar chart
│   ├── SankeyChart.swift        # Flow diagram
│   ├── FunnelChart.swift        # Funnel stages
│   ├── GanttChart.swift         # Timeline bars
│   ├── CandlestickChart.swift   # OHLC financial
│   ├── GaugeChart.swift         # Circular meter
│   ├── BubbleChart.swift        # Sized scatter
│   └── WordCloudChart.swift     # Text cloud
├── Interaction/
│   └── ChartTooltip.swift       # Tooltip overlays
└── Export/
    └── ChartExporter.swift      # PNG/PDF export
```

---

## 📋 Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 16.0           |
| macOS    | 13.0           |
| tvOS     | 16.0           |
| watchOS  | 9.0            |
| Swift    | 5.9            |

---

## 🗺️ Roadmap

- [ ] Sunburst chart
- [ ] Network/graph chart
- [ ] Waterfall chart
- [ ] Box plot chart
- [ ] Real-time streaming data support
- [ ] Chart composition/layering
- [ ] Accessibility improvements
- [ ] More export formats (SVG)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-chart`)
3. Commit your changes (`git commit -m 'feat: add waterfall chart'`)
4. Push to the branch (`git push origin feature/new-chart`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by D3.js, Chart.js, and Recharts
- Built for the SwiftUI community
