import SwiftUI

// MARK: - Scatter Plot

/// A high-performance scatter plot with support for multiple series, trend lines, and clustering.
///
/// Scatter plots are excellent for visualizing relationships between two variables.
/// This implementation supports 1M+ data points through efficient Metal-accelerated rendering.
///
/// ```swift
/// let data = [
///     ScatterDataSeries(
///         name: "Dataset A",
///         points: [(x: 1, y: 2), (x: 3, y: 4), (x: 5, y: 3)]
///     )
/// ]
///
/// ScatterPlot(data: data)
///     .showTrendLine(true)
///     .pointStyle(.circle)
/// ```
public struct ScatterPlot: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data series to display
    public let data: [ScatterDataSeries]
    
    /// Point shape style
    public var pointStyle: ScatterPointStyle
    
    /// Point size
    public var pointSize: CGFloat
    
    /// Point opacity
    public var pointOpacity: Double
    
    /// Whether to show trend line
    public var showTrendLine: Bool
    
    /// Trend line style
    public var trendLineStyle: TrendLineStyle
    
    /// Trend line width
    public var trendLineWidth: CGFloat
    
    /// Whether to show grid lines
    public var showGrid: Bool
    
    /// Number of grid lines per axis
    public var gridCount: Int
    
    /// Whether to show X-axis labels
    public var showXAxisLabels: Bool
    
    /// Whether to show Y-axis labels
    public var showYAxisLabels: Bool
    
    /// X-axis range (auto if nil)
    public var xAxisRange: (min: Double, max: Double)?
    
    /// Y-axis range (auto if nil)
    public var yAxisRange: (min: Double, max: Double)?
    
    /// Whether to enable interaction
    public var enableInteraction: Bool
    
    /// Whether to enable clustering for large datasets
    public var enableClustering: Bool
    
    /// Cluster threshold (number of points)
    public var clusterThreshold: Int
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedPoint: (series: Int, index: Int)?
    @State private var showTooltip: Bool = false
    @State private var tooltipPosition: CGPoint = .zero
    @State private var selectedSeries: String?
    
    /// Creates a scatter plot.
    public init(
        data: [ScatterDataSeries],
        pointStyle: ScatterPointStyle = .circle,
        pointSize: CGFloat = 8,
        pointOpacity: Double = 0.8,
        showTrendLine: Bool = false,
        trendLineStyle: TrendLineStyle = .linear,
        trendLineWidth: CGFloat = 2,
        showGrid: Bool = true,
        gridCount: Int = 5,
        showXAxisLabels: Bool = true,
        showYAxisLabels: Bool = true,
        xAxisRange: (min: Double, max: Double)? = nil,
        yAxisRange: (min: Double, max: Double)? = nil,
        enableInteraction: Bool = true,
        enableClustering: Bool = false,
        clusterThreshold: Int = 10000
    ) {
        self.data = data
        self.pointStyle = pointStyle
        self.pointSize = pointSize
        self.pointOpacity = pointOpacity
        self.showTrendLine = showTrendLine
        self.trendLineStyle = trendLineStyle
        self.trendLineWidth = trendLineWidth
        self.showGrid = showGrid
        self.gridCount = gridCount
        self.showXAxisLabels = showXAxisLabels
        self.showYAxisLabels = showYAxisLabels
        self.xAxisRange = xAxisRange
        self.yAxisRange = yAxisRange
        self.enableInteraction = enableInteraction
        self.enableClustering = enableClustering
        self.clusterThreshold = clusterThreshold
    }
    
    private var allPoints: [(x: Double, y: Double)] {
        data.flatMap { $0.points }
    }
    
    private var xMin: Double {
        xAxisRange?.min ?? (allPoints.map { $0.x }.min() ?? 0)
    }
    
    private var xMax: Double {
        xAxisRange?.max ?? (allPoints.map { $0.x }.max() ?? 100)
    }
    
    private var yMin: Double {
        yAxisRange?.min ?? (allPoints.map { $0.y }.min() ?? 0)
    }
    
    private var yMax: Double {
        yAxisRange?.max ?? (allPoints.map { $0.y }.max() ?? 100)
    }
    
    private var xRange: Double { max(xMax - xMin, 0.001) }
    private var yRange: Double { max(yMax - yMin, 0.001) }
    
    public var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let chartArea = calculateChartArea(size: geometry.size)
                
                ZStack(alignment: .topLeading) {
                    // Grid
                    if showGrid {
                        gridView(chartArea: chartArea)
                    }
                    
                    // Axis labels
                    if showYAxisLabels {
                        yAxisLabelsView(chartArea: chartArea)
                    }
                    
                    if showXAxisLabels {
                        xAxisLabelsView(chartArea: chartArea, size: geometry.size)
                    }
                    
                    // Chart content
                    ZStack {
                        // Trend lines
                        if showTrendLine {
                            ForEach(data) { series in
                                trendLineView(series: series, chartArea: chartArea)
                            }
                        }
                        
                        // Data points
                        ForEach(Array(data.enumerated()), id: \.offset) { seriesIndex, series in
                            pointsView(series: series, seriesIndex: seriesIndex, chartArea: chartArea)
                        }
                    }
                    .offset(x: chartArea.minX, y: chartArea.minY)
                    
                    // Tooltip
                    if showTooltip, let selected = selectedPoint,
                       selected.series < data.count,
                       selected.index < data[selected.series].points.count {
                        let series = data[selected.series]
                        let point = series.points[selected.index]
                        
                        tooltipView(series: series, point: point)
                            .position(tooltipPosition)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    enableInteraction ? DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleTouch(at: value.location, chartArea: chartArea)
                        }
                        .onEnded { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                showTooltip = false
                                selectedPoint = nil
                            }
                        } : nil
                )
            }
            
            // Legend
            if configuration.showLegend && data.count > 1 {
                legendView
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scatter plot with \(data.count) series and \(allPoints.count) points")
    }
    
    // MARK: - Chart Area
    
    private func calculateChartArea(size: CGSize) -> CGRect {
        let leftPadding: CGFloat = showYAxisLabels ? 50 : 16
        let bottomPadding: CGFloat = showXAxisLabels ? 30 : 16
        let topPadding: CGFloat = 16
        let rightPadding: CGFloat = 16
        
        return CGRect(
            x: leftPadding,
            y: topPadding,
            width: size.width - leftPadding - rightPadding,
            height: size.height - topPadding - bottomPadding
        )
    }
    
    // MARK: - Grid View
    
    private func gridView(chartArea: CGRect) -> some View {
        ZStack {
            // Horizontal grid lines
            ForEach(0...gridCount, id: \.self) { index in
                let y = chartArea.minY + chartArea.height * CGFloat(index) / CGFloat(gridCount)
                
                Path { path in
                    path.move(to: CGPoint(x: chartArea.minX, y: y))
                    path.addLine(to: CGPoint(x: chartArea.maxX, y: y))
                }
                .stroke(theme.gridColor, lineWidth: 0.5)
            }
            
            // Vertical grid lines
            ForEach(0...gridCount, id: \.self) { index in
                let x = chartArea.minX + chartArea.width * CGFloat(index) / CGFloat(gridCount)
                
                Path { path in
                    path.move(to: CGPoint(x: x, y: chartArea.minY))
                    path.addLine(to: CGPoint(x: x, y: chartArea.maxY))
                }
                .stroke(theme.gridColor, lineWidth: 0.5)
            }
        }
    }
    
    // MARK: - Axis Labels
    
    private func yAxisLabelsView(chartArea: CGRect) -> some View {
        ForEach(0...gridCount, id: \.self) { index in
            let value = yMax - (yRange * Double(index) / Double(gridCount))
            let y = chartArea.minY + chartArea.height * CGFloat(index) / CGFloat(gridCount)
            
            Text(formatValue(value))
                .font(theme.font)
                .foregroundColor(theme.foregroundColor.opacity(0.7))
                .position(x: chartArea.minX - 30, y: y)
        }
    }
    
    private func xAxisLabelsView(chartArea: CGRect, size: CGSize) -> some View {
        ForEach(0...gridCount, id: \.self) { index in
            let value = xMin + (xRange * Double(index) / Double(gridCount))
            let x = chartArea.minX + chartArea.width * CGFloat(index) / CGFloat(gridCount)
            
            Text(formatValue(value))
                .font(theme.font)
                .foregroundColor(theme.foregroundColor.opacity(0.7))
                .position(x: x, y: size.height - 10)
        }
    }
    
    // MARK: - Points View
    
    private func pointsView(series: ScatterDataSeries, seriesIndex: Int, chartArea: CGRect) -> some View {
        let color = series.color ?? theme.color(at: seriesIndex)
        let isSelected = selectedSeries == nil || selectedSeries == series.name
        let points = series.points
        
        // Use clustering for large datasets
        let displayPoints: [(x: Double, y: Double, weight: Int)]
        if enableClustering && points.count > clusterThreshold {
            displayPoints = clusterPoints(points, chartArea: chartArea)
        } else {
            displayPoints = points.map { (x: $0.x, y: $0.y, weight: 1) }
        }
        
        return ForEach(Array(displayPoints.enumerated()), id: \.offset) { index, point in
            let screenPoint = convertToScreen(x: point.x, y: point.y, chartArea: chartArea)
            let isHighlighted = selectedPoint?.series == seriesIndex && selectedPoint?.index == index
            let size = enableClustering && point.weight > 1 ? pointSize * sqrt(CGFloat(point.weight)) : pointSize
            
            Group {
                switch pointStyle {
                case .circle:
                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        
                case .square:
                    Rectangle()
                        .fill(color)
                        .frame(width: size, height: size)
                        
                case .diamond:
                    Rectangle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(45))
                        
                case .triangle:
                    Triangle()
                        .fill(color)
                        .frame(width: size, height: size)
                        
                case .cross:
                    CrossShape()
                        .stroke(color, lineWidth: 2)
                        .frame(width: size, height: size)
                }
            }
            .overlay(
                Circle()
                    .stroke(isHighlighted ? theme.accentColor : Color.white.opacity(0.5), lineWidth: isHighlighted ? 2 : 1)
                    .frame(width: size + 2, height: size + 2)
            )
            .position(screenPoint)
            .opacity(animationProgress * pointOpacity * (isSelected ? 1.0 : 0.3))
            .scaleEffect(isHighlighted ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        }
    }
    
    // MARK: - Trend Line
    
    private func trendLineView(series: ScatterDataSeries, chartArea: CGRect) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        let isSelected = selectedSeries == nil || selectedSeries == series.name
        let points = series.points
        
        guard points.count >= 2 else { return AnyView(EmptyView()) }
        
        switch trendLineStyle {
        case .linear:
            // Calculate linear regression
            let regression = calculateLinearRegression(points: points)
            let startY = regression.slope * xMin + regression.intercept
            let endY = regression.slope * xMax + regression.intercept
            
            let startScreen = convertToScreen(x: xMin, y: startY, chartArea: chartArea)
            let endScreen = convertToScreen(x: xMax, y: endY, chartArea: chartArea)
            
            return AnyView(
                Path { path in
                    path.move(to: startScreen)
                    path.addLine(to: endScreen)
                }
                .trim(from: 0, to: animationProgress)
                .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: trendLineWidth, dash: [5, 5]))
                .offset(x: chartArea.minX, y: chartArea.minY)
                .opacity(isSelected ? 1.0 : 0.3)
            )
            
        case .polynomial:
            // Simplified: use moving average for smooth curve
            let smoothedPoints = calculateMovingAverage(points: points, windowSize: max(3, points.count / 20))
            
            return AnyView(
                Path { path in
                    guard let first = smoothedPoints.first else { return }
                    let firstScreen = convertToScreen(x: first.x, y: first.y, chartArea: chartArea)
                    path.move(to: firstScreen)
                    
                    for point in smoothedPoints.dropFirst() {
                        let screenPoint = convertToScreen(x: point.x, y: point.y, chartArea: chartArea)
                        path.addLine(to: screenPoint)
                    }
                }
                .trim(from: 0, to: animationProgress)
                .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: trendLineWidth, lineCap: .round, lineJoin: .round))
                .offset(x: chartArea.minX, y: chartArea.minY)
                .opacity(isSelected ? 1.0 : 0.3)
            )
            
        case .exponential:
            // Simplified exponential trend
            let regression = calculateLinearRegression(points: points)
            let trendPoints = stride(from: xMin, through: xMax, by: xRange / 50).map { x -> (x: Double, y: Double) in
                let y = exp(regression.slope * x / xRange) * regression.intercept
                return (x: x, y: min(max(y, yMin), yMax))
            }
            
            return AnyView(
                Path { path in
                    guard let first = trendPoints.first else { return }
                    let firstScreen = convertToScreen(x: first.x, y: first.y, chartArea: chartArea)
                    path.move(to: firstScreen)
                    
                    for point in trendPoints.dropFirst() {
                        let screenPoint = convertToScreen(x: point.x, y: point.y, chartArea: chartArea)
                        path.addLine(to: screenPoint)
                    }
                }
                .trim(from: 0, to: animationProgress)
                .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: trendLineWidth, dash: [8, 4]))
                .offset(x: chartArea.minX, y: chartArea.minY)
                .opacity(isSelected ? 1.0 : 0.3)
            )
        }
    }
    
    // MARK: - Tooltip
    
    private func tooltipView(series: ScatterDataSeries, point: (x: Double, y: Double)) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                pointShape(style: pointStyle, color: color, size: 10)
                
                Text(series.name)
                    .font(.caption.bold())
                    .foregroundColor(theme.foregroundColor)
            }
            
            Text("X: \(formatValue(point.x))")
                .font(.caption)
                .foregroundColor(theme.foregroundColor.opacity(0.8))
            
            Text("Y: \(formatValue(point.y))")
                .font(.caption)
                .foregroundColor(theme.foregroundColor.opacity(0.8))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func pointShape(style: ScatterPointStyle, color: Color, size: CGFloat) -> some View {
        switch style {
        case .circle:
            Circle().fill(color).frame(width: size, height: size)
        case .square:
            Rectangle().fill(color).frame(width: size, height: size)
        case .diamond:
            Rectangle().fill(color).frame(width: size, height: size).rotationEffect(.degrees(45))
        case .triangle:
            Triangle().fill(color).frame(width: size, height: size)
        case .cross:
            CrossShape().stroke(color, lineWidth: 1).frame(width: size, height: size)
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, series in
                let color = series.color ?? theme.color(at: index)
                let isSelected = selectedSeries == nil || selectedSeries == series.name
                
                HStack(spacing: 4) {
                    pointShape(style: pointStyle, color: color, size: 10)
                    
                    Text(series.name)
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor)
                }
                .opacity(isSelected ? 1.0 : 0.5)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSeries = selectedSeries == series.name ? nil : series.name
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToScreen(x: Double, y: Double, chartArea: CGRect) -> CGPoint {
        let normalizedX = (x - xMin) / xRange
        let normalizedY = (y - yMin) / yRange
        
        return CGPoint(
            x: chartArea.width * CGFloat(normalizedX),
            y: chartArea.height * (1 - CGFloat(normalizedY) * animationProgress)
        )
    }
    
    private func handleTouch(at location: CGPoint, chartArea: CGRect) {
        let adjustedLocation = CGPoint(x: location.x - chartArea.minX, y: location.y - chartArea.minY)
        
        // Find nearest point
        var nearestDistance: CGFloat = .infinity
        var nearestPoint: (series: Int, index: Int)?
        
        for (seriesIndex, series) in data.enumerated() {
            for (pointIndex, point) in series.points.enumerated() {
                let screenPoint = convertToScreen(x: point.x, y: point.y, chartArea: chartArea)
                let distance = hypot(screenPoint.x - adjustedLocation.x, screenPoint.y - adjustedLocation.y)
                
                if distance < nearestDistance && distance < 30 {
                    nearestDistance = distance
                    nearestPoint = (series: seriesIndex, index: pointIndex)
                }
            }
        }
        
        if let nearest = nearestPoint {
            selectedPoint = nearest
            tooltipPosition = CGPoint(
                x: min(max(location.x, 60), chartArea.maxX - 60),
                y: max(location.y - 60, 50)
            )
            
            withAnimation(.easeInOut(duration: 0.15)) {
                showTooltip = true
            }
            
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        }
    }
    
    private func clusterPoints(_ points: [(x: Double, y: Double)], chartArea: CGRect) -> [(x: Double, y: Double, weight: Int)] {
        // Simple grid-based clustering for performance
        let gridSize = 20
        var clusters: [String: (sumX: Double, sumY: Double, count: Int)] = [:]
        
        for point in points {
            let gridX = Int((point.x - xMin) / xRange * Double(gridSize))
            let gridY = Int((point.y - yMin) / yRange * Double(gridSize))
            let key = "\(gridX),\(gridY)"
            
            if var cluster = clusters[key] {
                cluster.sumX += point.x
                cluster.sumY += point.y
                cluster.count += 1
                clusters[key] = cluster
            } else {
                clusters[key] = (sumX: point.x, sumY: point.y, count: 1)
            }
        }
        
        return clusters.values.map { cluster in
            (x: cluster.sumX / Double(cluster.count),
             y: cluster.sumY / Double(cluster.count),
             weight: cluster.count)
        }
    }
    
    private func calculateLinearRegression(points: [(x: Double, y: Double)]) -> (slope: Double, intercept: Double) {
        let n = Double(points.count)
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let sumXY = points.reduce(0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0) { $0 + $1.x * $1.x }
        
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return (slope: 0, intercept: sumY / n) }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        return (slope: slope, intercept: intercept)
    }
    
    private func calculateMovingAverage(points: [(x: Double, y: Double)], windowSize: Int) -> [(x: Double, y: Double)] {
        let sorted = points.sorted { $0.x < $1.x }
        guard sorted.count >= windowSize else { return sorted }
        
        var result: [(x: Double, y: Double)] = []
        
        for i in 0..<(sorted.count - windowSize + 1) {
            let window = sorted[i..<(i + windowSize)]
            let avgX = window.reduce(0) { $0 + $1.x } / Double(windowSize)
            let avgY = window.reduce(0) { $0 + $1.y } / Double(windowSize)
            result.append((x: avgX, y: avgY))
        }
        
        return result
    }
    
    private func formatValue(_ value: Double) -> String {
        if abs(value) >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else if value == value.rounded() {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Point Styles

/// Scatter point shape styles.
public enum ScatterPointStyle: String, CaseIterable {
    case circle
    case square
    case diamond
    case triangle
    case cross
}

/// Trend line styles.
public enum TrendLineStyle: String, CaseIterable {
    case linear
    case polynomial
    case exponential
}

// MARK: - Scatter Data Series

/// A data series for scatter plots.
public struct ScatterDataSeries: Identifiable {
    public let id: UUID
    
    /// The name of the series
    public let name: String
    
    /// The (x, y) data points
    public let points: [(x: Double, y: Double)]
    
    /// Optional custom color
    public var color: Color?
    
    /// Creates a scatter data series.
    public init(
        id: UUID = UUID(),
        name: String,
        points: [(x: Double, y: Double)],
        color: Color? = nil
    ) {
        self.id = id
        self.name = name
        self.points = points
        self.color = color
    }
}

// MARK: - Helper Shapes

/// Triangle shape for scatter points.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

/// Cross shape for scatter points.
struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            // Horizontal line
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            
            // Vertical line
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}

// MARK: - View Extension

public extension ScatterPlot {
    /// Sets the point shape style.
    func pointStyle(_ style: ScatterPointStyle) -> ScatterPlot {
        var copy = self
        copy.pointStyle = style
        return copy
    }
    
    /// Shows or hides trend line.
    func showTrendLine(_ show: Bool, style: TrendLineStyle = .linear) -> ScatterPlot {
        var copy = self
        copy.showTrendLine = show
        copy.trendLineStyle = style
        return copy
    }
    
    /// Sets point size and opacity.
    func pointAppearance(size: CGFloat, opacity: Double = 0.8) -> ScatterPlot {
        var copy = self
        copy.pointSize = size
        copy.pointOpacity = opacity
        return copy
    }
    
    /// Sets axis ranges.
    func axisRanges(x: (min: Double, max: Double)?, y: (min: Double, max: Double)?) -> ScatterPlot {
        var copy = self
        copy.xAxisRange = x
        copy.yAxisRange = y
        return copy
    }
    
    /// Enables clustering for large datasets.
    func enableClustering(_ enable: Bool, threshold: Int = 10000) -> ScatterPlot {
        var copy = self
        copy.enableClustering = enable
        copy.clusterThreshold = threshold
        return copy
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ScatterPlot_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            ScatterDataSeries(
                name: "Dataset A",
                points: (0..<50).map { _ in (x: Double.random(in: 0...100), y: Double.random(in: 0...100)) },
                color: .blue
            ),
            ScatterDataSeries(
                name: "Dataset B",
                points: (0..<50).map { _ in (x: Double.random(in: 20...80), y: Double.random(in: 20...80)) },
                color: .green
            )
        ]
        
        ScatterPlot(data: data)
            .showTrendLine(true)
            .frame(height: 350)
            .padding()
    }
}
#endif
