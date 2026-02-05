import SwiftUI

// MARK: - Line Chart

/// A high-performance animated line chart with support for multiple series,
/// gradients, markers, and real-time data streaming.
///
/// Line charts are ideal for showing trends over time or continuous data.
/// This implementation supports iOS 15+ while Apple Charts requires iOS 16+.
///
/// ```swift
/// let data = [
///     LineDataSeries(name: "Revenue", values: [100, 150, 200, 180, 220]),
///     LineDataSeries(name: "Costs", values: [80, 90, 100, 95, 110])
/// ]
///
/// LineChart(data: data, labels: ["Jan", "Feb", "Mar", "Apr", "May"])
///     .chartTheme(.dark)
///     .lineStyle(.curved)
/// ```
public struct LineChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data series to display
    public let data: [LineDataSeries]
    
    /// X-axis labels
    public let labels: [String]
    
    /// The line style (straight, curved, stepped)
    public var lineStyle: LineStyle
    
    /// Whether to show the area fill under lines
    public var showArea: Bool
    
    /// Area fill opacity
    public var areaOpacity: Double
    
    /// Whether to show data point markers
    public var showMarkers: Bool
    
    /// Marker radius
    public var markerRadius: CGFloat
    
    /// Line width
    public var lineWidth: CGFloat
    
    /// Whether to show grid lines
    public var showGrid: Bool
    
    /// Number of Y-axis grid lines
    public var yAxisGridCount: Int
    
    /// Whether to show X-axis labels
    public var showXAxisLabels: Bool
    
    /// Whether to show Y-axis labels
    public var showYAxisLabels: Bool
    
    /// Y-axis minimum value (auto if nil)
    public var yAxisMin: Double?
    
    /// Y-axis maximum value (auto if nil)
    public var yAxisMax: Double?
    
    /// Whether to enable touch interaction
    public var enableInteraction: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var selectedSeries: String?
    @State private var touchLocation: CGPoint?
    @State private var showTooltip: Bool = false
    
    /// Creates a line chart.
    public init(
        data: [LineDataSeries],
        labels: [String] = [],
        lineStyle: LineStyle = .curved,
        showArea: Bool = false,
        areaOpacity: Double = 0.2,
        showMarkers: Bool = true,
        markerRadius: CGFloat = 4,
        lineWidth: CGFloat = 2,
        showGrid: Bool = true,
        yAxisGridCount: Int = 5,
        showXAxisLabels: Bool = true,
        showYAxisLabels: Bool = true,
        yAxisMin: Double? = nil,
        yAxisMax: Double? = nil,
        enableInteraction: Bool = true
    ) {
        self.data = data
        self.labels = labels
        self.lineStyle = lineStyle
        self.showArea = showArea
        self.areaOpacity = areaOpacity
        self.showMarkers = showMarkers
        self.markerRadius = markerRadius
        self.lineWidth = lineWidth
        self.showGrid = showGrid
        self.yAxisGridCount = yAxisGridCount
        self.showXAxisLabels = showXAxisLabels
        self.showYAxisLabels = showYAxisLabels
        self.yAxisMin = yAxisMin
        self.yAxisMax = yAxisMax
        self.enableInteraction = enableInteraction
    }
    
    private var minValue: Double {
        yAxisMin ?? (data.flatMap { $0.values }.min() ?? 0)
    }
    
    private var maxValue: Double {
        yAxisMax ?? (data.flatMap { $0.values }.max() ?? 100)
    }
    
    private var valueRange: Double {
        max(maxValue - minValue, 0.001)
    }
    
    private var maxDataPoints: Int {
        data.map { $0.values.count }.max() ?? 0
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let chartArea = calculateChartArea(size: geometry.size)
                
                ZStack(alignment: .topLeading) {
                    // Grid and axes
                    if showGrid {
                        gridView(chartArea: chartArea)
                    }
                    
                    // Y-axis labels
                    if showYAxisLabels {
                        yAxisLabelsView(chartArea: chartArea)
                    }
                    
                    // X-axis labels
                    if showXAxisLabels {
                        xAxisLabelsView(chartArea: chartArea, size: geometry.size)
                    }
                    
                    // Chart content
                    ZStack {
                        // Area fills
                        if showArea {
                            ForEach(data) { series in
                                areaPath(series: series, chartArea: chartArea)
                            }
                        }
                        
                        // Lines
                        ForEach(data) { series in
                            linePath(series: series, chartArea: chartArea)
                        }
                        
                        // Markers
                        if showMarkers {
                            ForEach(data) { series in
                                markersView(series: series, chartArea: chartArea)
                            }
                        }
                        
                        // Selection indicator
                        if let index = selectedIndex, enableInteraction {
                            selectionIndicator(index: index, chartArea: chartArea)
                        }
                    }
                    .offset(x: chartArea.minX, y: chartArea.minY)
                    
                    // Tooltip
                    if showTooltip, let index = selectedIndex, let location = touchLocation {
                        tooltipView(index: index)
                            .position(x: min(max(location.x, 60), geometry.size.width - 60), y: max(location.y - 50, 30))
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
                                selectedIndex = nil
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
        .accessibilityLabel("Line chart with \(data.count) series and \(maxDataPoints) data points")
    }
    
    // MARK: - Chart Area Calculation
    
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
            ForEach(0...yAxisGridCount, id: \.self) { index in
                let y = chartArea.minY + chartArea.height * CGFloat(index) / CGFloat(yAxisGridCount)
                
                Path { path in
                    path.move(to: CGPoint(x: chartArea.minX, y: y))
                    path.addLine(to: CGPoint(x: chartArea.maxX, y: y))
                }
                .stroke(theme.gridColor, lineWidth: 0.5)
            }
            
            // Vertical grid lines
            if maxDataPoints > 1 {
                ForEach(0..<maxDataPoints, id: \.self) { index in
                    let x = chartArea.minX + chartArea.width * CGFloat(index) / CGFloat(maxDataPoints - 1)
                    
                    Path { path in
                        path.move(to: CGPoint(x: x, y: chartArea.minY))
                        path.addLine(to: CGPoint(x: x, y: chartArea.maxY))
                    }
                    .stroke(theme.gridColor.opacity(0.3), lineWidth: 0.5)
                }
            }
        }
    }
    
    // MARK: - Y-Axis Labels
    
    private func yAxisLabelsView(chartArea: CGRect) -> some View {
        ForEach(0...yAxisGridCount, id: \.self) { index in
            let value = maxValue - (valueRange * Double(index) / Double(yAxisGridCount))
            let y = chartArea.minY + chartArea.height * CGFloat(index) / CGFloat(yAxisGridCount)
            
            Text(formatValue(value))
                .font(theme.font)
                .foregroundColor(theme.foregroundColor.opacity(0.7))
                .position(x: chartArea.minX - 30, y: y)
        }
    }
    
    // MARK: - X-Axis Labels
    
    private func xAxisLabelsView(chartArea: CGRect, size: CGSize) -> some View {
        let labelCount = min(labels.count, maxDataPoints)
        let step = labelCount > 6 ? max(1, labelCount / 6) : 1
        
        return ForEach(Array(stride(from: 0, to: labelCount, by: step)), id: \.self) { index in
            if index < labels.count {
                let x = chartArea.minX + chartArea.width * CGFloat(index) / CGFloat(max(maxDataPoints - 1, 1))
                
                Text(labels[index])
                    .font(theme.font)
                    .foregroundColor(theme.foregroundColor.opacity(0.7))
                    .position(x: x, y: size.height - 10)
            }
        }
    }
    
    // MARK: - Line Path
    
    private func linePath(series: LineDataSeries, chartArea: CGRect) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        let isSelected = selectedSeries == nil || selectedSeries == series.name
        let points = calculatePoints(series: series, chartArea: chartArea)
        
        return Path { path in
            guard points.count >= 2 else { return }
            
            switch lineStyle {
            case .straight:
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                
            case .curved:
                path.move(to: points[0])
                for i in 1..<points.count {
                    let current = points[i]
                    let previous = points[i - 1]
                    let midX = (previous.x + current.x) / 2
                    
                    path.addCurve(
                        to: current,
                        control1: CGPoint(x: midX, y: previous.y),
                        control2: CGPoint(x: midX, y: current.y)
                    )
                }
                
            case .stepped:
                path.move(to: points[0])
                for i in 1..<points.count {
                    let current = points[i]
                    let previous = points[i - 1]
                    path.addLine(to: CGPoint(x: current.x, y: previous.y))
                    path.addLine(to: current)
                }
            }
        }
        .trim(from: 0, to: animationProgress)
        .stroke(
            series.gradient ?? LinearGradient(colors: [color], startPoint: .leading, endPoint: .trailing),
            style: StrokeStyle(lineWidth: series.lineWidth ?? lineWidth, lineCap: .round, lineJoin: .round, dash: series.dashPattern ?? [])
        )
        .opacity(isSelected ? 1.0 : 0.3)
    }
    
    // MARK: - Area Path
    
    private func areaPath(series: LineDataSeries, chartArea: CGRect) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        let isSelected = selectedSeries == nil || selectedSeries == series.name
        let points = calculatePoints(series: series, chartArea: chartArea)
        
        return Path { path in
            guard points.count >= 2 else { return }
            
            path.move(to: CGPoint(x: points[0].x, y: chartArea.height))
            path.addLine(to: points[0])
            
            switch lineStyle {
            case .straight:
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                
            case .curved:
                for i in 1..<points.count {
                    let current = points[i]
                    let previous = points[i - 1]
                    let midX = (previous.x + current.x) / 2
                    
                    path.addCurve(
                        to: current,
                        control1: CGPoint(x: midX, y: previous.y),
                        control2: CGPoint(x: midX, y: current.y)
                    )
                }
                
            case .stepped:
                for i in 1..<points.count {
                    let current = points[i]
                    let previous = points[i - 1]
                    path.addLine(to: CGPoint(x: current.x, y: previous.y))
                    path.addLine(to: current)
                }
            }
            
            path.addLine(to: CGPoint(x: points.last!.x, y: chartArea.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [color.opacity(areaOpacity * animationProgress), color.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .opacity(isSelected ? 1.0 : 0.3)
    }
    
    // MARK: - Markers
    
    private func markersView(series: LineDataSeries, chartArea: CGRect) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        let isSelected = selectedSeries == nil || selectedSeries == series.name
        let points = calculatePoints(series: series, chartArea: chartArea)
        
        return ForEach(Array(points.enumerated()), id: \.offset) { index, point in
            let isHighlighted = selectedIndex == index
            let radius = isHighlighted ? markerRadius * 1.5 : markerRadius
            
            Circle()
                .fill(color)
                .frame(width: radius * 2, height: radius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isHighlighted ? 2 : 1)
                )
                .position(point)
                .opacity(animationProgress * (isSelected ? 1.0 : 0.3))
                .scaleEffect(isHighlighted ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        }
    }
    
    // MARK: - Selection Indicator
    
    private func selectionIndicator(index: Int, chartArea: CGRect) -> some View {
        let x = chartArea.width * CGFloat(index) / CGFloat(max(maxDataPoints - 1, 1))
        
        return Path { path in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: chartArea.height))
        }
        .stroke(theme.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }
    
    // MARK: - Tooltip
    
    private func tooltipView(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if index < labels.count {
                Text(labels[index])
                    .font(.caption.bold())
                    .foregroundColor(theme.foregroundColor)
            }
            
            ForEach(data) { series in
                if index < series.values.count {
                    let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        
                        Text("\(series.name): \(formatValue(series.values[index]))")
                            .font(.caption)
                            .foregroundColor(theme.foregroundColor.opacity(0.8))
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(data) { series in
                let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
                let isSelected = selectedSeries == nil || selectedSeries == series.name
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 16, height: 3)
                    
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
    
    private func calculatePoints(series: LineDataSeries, chartArea: CGRect) -> [CGPoint] {
        series.values.enumerated().map { index, value in
            let x = chartArea.width * CGFloat(index) / CGFloat(max(maxDataPoints - 1, 1))
            let normalizedValue = (value - minValue) / valueRange
            let y = chartArea.height * (1 - CGFloat(normalizedValue) * animationProgress)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func handleTouch(at location: CGPoint, chartArea: CGRect) {
        let adjustedX = location.x - chartArea.minX
        let index = Int(round(adjustedX / chartArea.width * CGFloat(maxDataPoints - 1)))
        let clampedIndex = max(0, min(index, maxDataPoints - 1))
        
        if clampedIndex != selectedIndex {
            selectedIndex = clampedIndex
            touchLocation = location
            
            withAnimation(.easeInOut(duration: 0.15)) {
                showTooltip = true
            }
            
            // Haptic feedback
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        }
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

// MARK: - Line Style

/// The style of line interpolation.
public enum LineStyle: String, CaseIterable {
    /// Straight line segments between points
    case straight
    /// Smooth curved lines using bezier curves
    case curved
    /// Stepped lines (horizontal then vertical)
    case stepped
}

// MARK: - Line Data Series

/// A data series for line charts.
public struct LineDataSeries: Identifiable {
    public let id: UUID
    
    /// The name of the series
    public let name: String
    
    /// The Y values
    public let values: [Double]
    
    /// Optional custom color
    public var color: Color?
    
    /// Optional gradient for the line
    public var gradient: LinearGradient?
    
    /// Optional custom line width
    public var lineWidth: CGFloat?
    
    /// Optional dash pattern
    public var dashPattern: [CGFloat]?
    
    /// Creates a line data series.
    public init(
        id: UUID = UUID(),
        name: String,
        values: [Double],
        color: Color? = nil,
        gradient: LinearGradient? = nil,
        lineWidth: CGFloat? = nil,
        dashPattern: [CGFloat]? = nil
    ) {
        self.id = id
        self.name = name
        self.values = values
        self.color = color
        self.gradient = gradient
        self.lineWidth = lineWidth
        self.dashPattern = dashPattern
    }
}

// MARK: - View Extension

public extension LineChart {
    /// Sets the line interpolation style.
    func lineStyle(_ style: LineStyle) -> LineChart {
        var copy = self
        copy.lineStyle = style
        return copy
    }
    
    /// Shows or hides area fill under lines.
    func showArea(_ show: Bool, opacity: Double = 0.2) -> LineChart {
        var copy = self
        copy.showArea = show
        copy.areaOpacity = opacity
        return copy
    }
    
    /// Shows or hides data point markers.
    func showMarkers(_ show: Bool, radius: CGFloat = 4) -> LineChart {
        var copy = self
        copy.showMarkers = show
        copy.markerRadius = radius
        return copy
    }
    
    /// Sets the Y-axis range.
    func yAxisRange(min: Double?, max: Double?) -> LineChart {
        var copy = self
        copy.yAxisMin = min
        copy.yAxisMax = max
        return copy
    }
}

// MARK: - Preview Provider

#if DEBUG
struct LineChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            LineDataSeries(
                name: "Revenue",
                values: [100, 150, 130, 200, 180, 220, 250, 230, 280, 320, 290, 350],
                color: .blue
            ),
            LineDataSeries(
                name: "Costs",
                values: [80, 90, 85, 100, 95, 110, 120, 115, 130, 140, 135, 150],
                color: .red,
                dashPattern: [5, 3]
            )
        ]
        
        LineChart(
            data: data,
            labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        )
        .showArea(true)
        .frame(height: 300)
        .padding()
    }
}
#endif
