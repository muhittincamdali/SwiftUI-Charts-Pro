// SwiftUIChartsPro
// Advanced chart components for SwiftUI beyond Apple Charts
//
// Created by Muhittin Camdali
// Copyright © 2024 All rights reserved.

import SwiftUI

/// SwiftUI Charts Pro - A comprehensive charting library for SwiftUI.
///
/// This library provides 20+ advanced chart types beyond what Apple Charts offers,
/// including Heatmaps, Treemaps, Sankey Diagrams, Gantt Charts, and more.
///
/// ## Quick Start
///
/// ```swift
/// import SwiftUIChartsPro
///
/// struct ContentView: View {
///     var body: some View {
///         RadarChart(
///             data: [
///                 RadarDataSeries(name: "Sales", values: [80, 90, 70, 60, 85])
///             ],
///             labels: ["Q1", "Q2", "Q3", "Q4", "Q5"]
///         )
///         .chartTheme(.dark)
///     }
/// }
/// ```
///
/// ## Available Chart Types
///
/// - ``HeatmapChart``: Color-coded matrix visualization
/// - ``TreemapChart``: Hierarchical data as nested rectangles
/// - ``RadarChart``: Spider/radar charts for multivariate data
/// - ``SankeyChart``: Flow diagrams showing quantities between nodes
/// - ``FunnelChart``: Sequential stage conversion visualization
/// - ``GanttChart``: Project timeline and scheduling
/// - ``CandlestickChart``: Financial OHLC charts
/// - ``GaugeChart``: Meter/gauge for single values
/// - ``BubbleChart``: Scatter plots with size dimension
/// - ``WordCloudChart``: Text frequency visualization
/// - ``WaterfallChart``: Cumulative effect visualization
/// - ``BoxPlotChart``: Statistical distribution via quartiles
/// - ``ViolinChart``: Distribution shape with kernel density
/// - ``ParallelCoordinatesChart``: High-dimensional data
/// - ``ChordDiagram``: Circular relationship visualization
/// - ``SunburstChart``: Radial hierarchical chart
///
/// ## Theming
///
/// Apply consistent styling with built-in themes:
///
/// ```swift
/// MyChart(data: data)
///     .chartTheme(.dark)      // Dark theme
///     .chartTheme(.pastel)    // Pastel colors
///     .chartTheme(.vibrant)   // Saturated colors
/// ```
///
/// ## Interactions
///
/// Enable interactive features:
///
/// ```swift
/// MyChart(data: data)
///     .chartZoom(manager: zoomManager)
///     .onChartSelection { point in
///         print("Selected: \(point)")
///     }
/// ```
///
/// ## Export
///
/// Export charts as images:
///
/// ```swift
/// let exporter = ChartExporter()
/// if let result = exporter.exportToData(view: myChart, size: CGSize(width: 800, height: 600)) {
///     // Use result.data
/// }
/// ```

// MARK: - Library Version

/// The current version of SwiftUIChartsPro.
public let swiftUIChartsProVersion = "1.0.0"

/// Minimum iOS version supported.
public let minimumIOSVersion = "16.0"

// MARK: - Type Aliases

/// Convenience type alias for labeled data points.
public typealias ChartPoint = LabeledDataPoint

/// Convenience type alias for time series data.
public typealias TimePoint = TimeSeriesDataPoint

/// Convenience type alias for hierarchical data.
public typealias TreeNode = HierarchyNode

/// Convenience type alias for flow connections.
public typealias FlowLink = FlowConnection

// MARK: - Library Entry Point

/// Entry point for SwiftUIChartsPro configuration.
public enum SwiftUIChartsPro {
    
    /// Configures default settings for all charts.
    public static func configure(
        defaultTheme: ChartTheme = .default,
        defaultAnimation: ChartAnimation = .smooth,
        defaultConfiguration: ChartConfiguration = ChartConfiguration()
    ) {
        // Store defaults in UserDefaults or static properties
        _defaultTheme = defaultTheme
        _defaultAnimation = defaultAnimation
        _defaultConfiguration = defaultConfiguration
    }
    
    /// The default theme for new charts.
    public static var defaultTheme: ChartTheme {
        _defaultTheme ?? .default
    }
    
    /// The default animation for chart transitions.
    public static var defaultAnimation: ChartAnimation {
        _defaultAnimation ?? .smooth
    }
    
    /// The default configuration for new charts.
    public static var defaultConfiguration: ChartConfiguration {
        _defaultConfiguration ?? ChartConfiguration()
    }
    
    // Private storage
    private static var _defaultTheme: ChartTheme?
    private static var _defaultAnimation: ChartAnimation?
    private static var _defaultConfiguration: ChartConfiguration?
}

// MARK: - Sample Data Generators

/// Generates sample data for testing and previews.
public enum SampleData {
    
    /// Generates random labeled data points.
    public static func labeledPoints(count: Int, range: ClosedRange<Double> = 0...100) -> [LabeledDataPoint] {
        (0..<count).map { i in
            LabeledDataPoint(
                label: "Item \(i + 1)",
                value: Double.random(in: range)
            )
        }
    }
    
    /// Generates random XY data points.
    public static func xyPoints(count: Int, xRange: ClosedRange<Double> = 0...100, yRange: ClosedRange<Double> = 0...100) -> [XYDataPoint] {
        (0..<count).map { _ in
            XYDataPoint(
                x: Double.random(in: xRange),
                y: Double.random(in: yRange),
                size: Double.random(in: 10...50)
            )
        }
    }
    
    /// Generates a sample hierarchy.
    public static func hierarchy(depth: Int = 3, breadth: Int = 4) -> HierarchyNode {
        func generateChildren(currentDepth: Int) -> [HierarchyNode] {
            guard currentDepth < depth else {
                return (0..<breadth).map { i in
                    HierarchyNode(name: "Leaf \(i + 1)", value: Double.random(in: 10...100))
                }
            }
            
            return (0..<breadth).map { i in
                HierarchyNode(
                    name: "Node \(currentDepth)-\(i + 1)",
                    children: generateChildren(currentDepth: currentDepth + 1)
                )
            }
        }
        
        return HierarchyNode(
            name: "Root",
            children: generateChildren(currentDepth: 0)
        )
    }
    
    /// Generates sample flow connections.
    public static func flowConnections() -> [FlowConnection] {
        [
            FlowConnection(source: "A", target: "B", value: 100),
            FlowConnection(source: "A", target: "C", value: 80),
            FlowConnection(source: "B", target: "D", value: 60),
            FlowConnection(source: "B", target: "E", value: 40),
            FlowConnection(source: "C", target: "D", value: 50),
            FlowConnection(source: "C", target: "F", value: 30)
        ]
    }
    
    /// Generates sample heatmap data.
    public static func heatmapMatrix(rows: Int, cols: Int, range: ClosedRange<Double> = 0...100) -> [[Double]] {
        (0..<rows).map { _ in
            (0..<cols).map { _ in Double.random(in: range) }
        }
    }
    
    /// Generates sample time series data.
    public static func timeSeries(days: Int, baseValue: Double = 100) -> [TimeSeriesDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var value = baseValue
        
        return (0..<days).map { i in
            value += Double.random(in: -10...10)
            let date = calendar.date(byAdding: .day, value: -days + i, to: today) ?? today
            return TimeSeriesDataPoint(date: date, value: value)
        }
    }
    
    /// Generates sample candlestick data.
    public static func candlesticks(count: Int, startPrice: Double = 100) -> [CandlestickData] {
        let calendar = Calendar.current
        let today = Date()
        var price = startPrice
        
        return (0..<count).map { i in
            let date = calendar.date(byAdding: .day, value: -count + i, to: today) ?? today
            let open = price + Double.random(in: -5...5)
            let close = open + Double.random(in: -10...10)
            let high = max(open, close) + Double.random(in: 0...5)
            let low = min(open, close) - Double.random(in: 0...5)
            let volume = Double.random(in: 100_000...500_000)
            
            price = close
            
            return CandlestickData(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }
    }
}
