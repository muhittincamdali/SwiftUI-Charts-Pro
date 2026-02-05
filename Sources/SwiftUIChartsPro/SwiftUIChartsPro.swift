// SwiftUI Charts Pro
// The most comprehensive charting library for SwiftUI
// iOS 15+ | macOS 12+ | watchOS 8+ | tvOS 15+ | visionOS 1+

/// SwiftUI Charts Pro - Production-Ready Charts Library
///
/// A comprehensive, high-performance charting library for SwiftUI that provides:
/// - 20+ chart types including Line, Bar, Pie, Area, Scatter, Radar, and more
/// - iOS 15+ backward compatibility (Apple Charts requires iOS 16+)
/// - Real-time data streaming support
/// - 1M+ data point rendering with intelligent downsampling
/// - Interactive zoom, pan, and selection gestures
/// - Export to PNG, JPEG, PDF, and SVG
/// - Full accessibility support with VoiceOver and audio graphs
/// - Custom themes and animation presets
///
/// ## Quick Start
///
/// ```swift
/// import SwiftUIChartsPro
///
/// struct ContentView: View {
///     let data = [
///         LineDataSeries(name: "Revenue", values: [100, 150, 200, 180, 220])
///     ]
///
///     var body: some View {
///         LineChart(data: data, labels: ["Jan", "Feb", "Mar", "Apr", "May"])
///             .chartTheme(.midnight)
///             .chartAnimation(.spring)
///             .chartAccessibility(label: "Monthly Revenue")
///     }
/// }
/// ```

// MARK: - Core Components

// Chart Base
@_exported import struct SwiftUI.Color
@_exported import struct SwiftUI.Animation

// Configuration
public typealias ChartConfig = ChartConfiguration

// MARK: - Chart Types

// Basic Charts
// - LineChart: Animated line charts with multiple series
// - BarChart: Grouped, stacked, and horizontal bar charts
// - PieChart: Pie and donut charts with labels
// - AreaChart: Stacked, overlapped, and stream area charts
// - ScatterPlot: Scatter plots with trend lines and clustering

// Advanced Charts
// - RadarChart: Spider/radar charts for multivariate data
// - CandlestickChart: Financial candlestick/OHLC charts
// - HeatmapChart: 2D heatmaps with color gradients
// - TreemapChart: Hierarchical treemap visualization
// - SankeyChart: Flow diagrams for value transfer
// - FunnelChart: Conversion funnel visualization
// - GaugeChart: Circular and linear gauges
// - BoxPlotChart: Statistical box plots
// - ViolinChart: Violin plots for distribution
// - BubbleChart: Bubble charts with size encoding
// - WaterfallChart: Cumulative effect waterfall charts
// - GanttChart: Project timeline visualization
// - SunburstChart: Hierarchical sunburst diagrams
// - ChordDiagram: Relationship chord diagrams
// - ParallelCoordinates: High-dimensional data visualization
// - WordCloudChart: Word frequency visualization

// MARK: - Version

/// The current version of SwiftUI Charts Pro
public let swiftUIChartsProVersion = "2.0.0"

/// Build information
public struct BuildInfo {
    public static let version = "2.0.0"
    public static let buildDate = "2025-02-05"
    public static let minimumSwiftVersion = "5.9"
    public static let platforms = ["iOS 15+", "macOS 12+", "watchOS 8+", "tvOS 15+", "visionOS 1+"]
}

// MARK: - Feature Flags

/// Feature availability flags
public struct ChartFeatures {
    /// Whether real-time streaming is available
    public static let realTimeStreaming = true
    
    /// Whether high-performance rendering is available
    public static let highPerformanceRendering = true
    
    /// Whether export functionality is available
    public static let exportSupport = true
    
    /// Whether accessibility features are available
    public static let accessibility = true
    
    /// Whether interactive gestures are available
    public static let interactiveGestures = true
    
    /// Maximum supported data points for optimal performance
    public static let maxOptimalDataPoints = 1_000_000
}

// MARK: - Convenience Initializers

public extension LineChart {
    /// Creates a simple line chart from values.
    init(values: [Double], labels: [String] = []) {
        self.init(
            data: [LineDataSeries(name: "Data", values: values)],
            labels: labels
        )
    }
}

public extension BarChart {
    /// Creates a simple bar chart from values.
    init(values: [Double], labels: [String] = []) {
        self.init(
            data: [BarDataSeries(name: "Data", values: values)],
            labels: labels
        )
    }
}

public extension PieChart {
    /// Creates a pie chart from label-value pairs.
    init(items: [(label: String, value: Double)]) {
        self.init(
            data: items.map { PieSlice(label: $0.label, value: $0.value) }
        )
    }
}

// MARK: - Debug Helpers

#if DEBUG
public extension View {
    /// Prints chart performance metrics.
    func chartDebug() -> some View {
        self.onAppear {
            print("📊 SwiftUI Charts Pro v\(swiftUIChartsProVersion)")
            print("   Platforms: \(BuildInfo.platforms.joined(separator: ", "))")
            print("   Features: Real-time ✓, High-perf ✓, Export ✓, A11y ✓")
        }
    }
}
#endif
