<p align="center">
  <img src="Assets/logo.png" alt="SwiftUI Charts Pro" width="200"/>
</p>

<h1 align="center">SwiftUI Charts Pro</h1>

<p align="center">
  <strong>📊 20+ advanced chart types for SwiftUI beyond Apple Charts</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift"/>
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS"/>
</p>

---

## Chart Types

| Category | Charts |
|----------|--------|
| **Basic** | Line, Bar, Pie, Donut |
| **Advanced** | Radar, Sankey, Treemap, Sunburst |
| **Financial** | Candlestick, OHLC, Waterfall |
| **Statistical** | Box Plot, Violin, Histogram |
| **Geographic** | Choropleth, Bubble Map |

## Quick Start

```swift
import SwiftUIChartsPro

// Radar Chart
RadarChart(data: skills) { item in
    RadarMark(
        axis: item.name,
        value: item.level
    )
}

// Treemap
TreemapChart(data: categories) { item in
    TreemapMark(value: item.size)
        .foregroundStyle(by: .value("Category", item.name))
}

// Candlestick
CandlestickChart(data: stocks) { item in
    CandlestickMark(
        date: item.date,
        open: item.open,
        high: item.high,
        low: item.low,
        close: item.close
    )
}
```

## Animations

```swift
RadarChart(data: data)
    .animation(.spring(), value: data)
    .chartAnimation(.interpolate)
```

## Interactivity

```swift
LineChart(data: values)
    .chartOverlay { proxy in
        // Tooltip on hover
    }
    .chartSelection($selection)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License

---

## 📈 Star History

<a href="https://star-history.com/#muhittincamdali/SwiftUI-Charts-Pro&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/SwiftUI-Charts-Pro&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/SwiftUI-Charts-Pro&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=muhittincamdali/SwiftUI-Charts-Pro&type=Date" />
 </picture>
</a>
