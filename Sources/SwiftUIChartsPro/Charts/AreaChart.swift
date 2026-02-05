import SwiftUI

// MARK: - Area Chart

/// A high-performance area chart with support for stacked, normalized, and stream layouts.
///
/// Area charts are excellent for showing cumulative values over time. This implementation
/// supports smooth animations, gradient fills, and multiple stacking modes.
///
/// ```swift
/// let data = [
///     AreaDataSeries(name: "Revenue", values: [100, 150, 200, 180, 220]),
///     AreaDataSeries(name: "Costs", values: [80, 90, 100, 95, 110])
/// ]
///
/// AreaChart(data: data, labels: ["Jan", "Feb", "Mar", "Apr", "May"])
///     .areaStyle(.stacked)
///     .showGradient(true)
/// ```
public struct AreaChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data series to display
    public let data: [AreaDataSeries]
    
    /// X-axis labels
    public let labels: [String]
    
    /// Area stacking style
    public var areaStyle: AreaStyle
    
    /// Curve type for area edges
    public var curveType: AreaCurveType
    
    /// Whether to show gradient fills
    public var showGradient: Bool
    
    /// Gradient opacity
    public var gradientOpacity: Double
    
    /// Whether to show line strokes
    public var showStrokes: Bool
    
    /// Stroke line width
    public var strokeWidth: CGFloat
    
    /// Whether to show data points
    public var showPoints: Bool
    
    /// Point radius
    public var pointRadius: CGFloat
    
    /// Whether to show grid lines
    public var showGrid: Bool
    
    /// Number of Y-axis grid lines
    public var yAxisGridCount: Int
    
    /// Whether to show X-axis labels
    public var showXAxisLabels: Bool
    
    /// Whether to show Y-axis labels
    public var showYAxisLabels: Bool
    
    /// Whether to enable interaction
    public var enableInteraction: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var selectedSeries: String?
    @State private var showTooltip: Bool = false
    @State private var touchLocation: CGPoint = .zero
    
    /// Creates an area chart.
    public init(
        data: [AreaDataSeries],
        labels: [String] = [],
        areaStyle: AreaStyle = .stacked,
        curveType: AreaCurveType = .curved,
        showGradient: Bool = true,
        gradientOpacity: Double = 0.6,
        showStrokes: Bool = true,
        strokeWidth: CGFloat = 2,
        showPoints: Bool = false,
        pointRadius: CGFloat = 4,
        showGrid: Bool = true,
        yAxisGridCount: Int = 5,
        showXAxisLabels: Bool = true,
        showYAxisLabels: Bool = true,
        enableInteraction: Bool = true
    ) {
        self.data = data
        self.labels = labels
        self.areaStyle = areaStyle
        self.curveType = curveType
        self.showGradient = showGradient
        self.gradientOpacity = gradientOpacity
        self.showStrokes = showStrokes
        self.strokeWidth = strokeWidth
        self.showPoints = showPoints
        self.pointRadius = pointRadius
        self.showGrid = showGrid
        self.yAxisGridCount = yAxisGridCount
        self.showXAxisLabels = showXAxisLabels
        self.showYAxisLabels = showYAxisLabels
        self.enableInteraction = enableInteraction
    }
    
    private var maxDataPoints: Int {
        data.map { $0.values.count }.max() ?? 0
    }
    
    private var maxValue: Double {
        switch areaStyle {
        case .overlapped:
            return data.flatMap { $0.values }.max() ?? 100
        case .stacked, .stream:
            // Calculate max stack height
            var maxSum: Double = 0
            for i in 0..<maxDataPoints {
                let sum = data.reduce(0.0) { result, series in
                    result + (i < series.values.count ? max(0, series.values[i]) : 0)
                }
                maxSum = max(maxSum, sum)
            }
            return maxSum
        case .normalized:
            return 100
        }
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let chartArea = calculateChartArea(size: geometry.size)
                
                ZStack(alignment: .topLeading) {
                    // Grid
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
                    
                    // Areas (draw in reverse order for proper layering in overlapped mode)
                    ZStack {
                        switch areaStyle {
                        case .overlapped:
                            ForEach(data.reversed()) { series in
                                overlappedArea(series: series, chartArea: chartArea)
                            }
                            
                        case .stacked, .normalized:
                            stackedAreas(chartArea: chartArea)
                            
                        case .stream:
                            streamAreas(chartArea: chartArea)
                        }
                        
                        // Points
                        if showPoints {
                            pointsView(chartArea: chartArea)
                        }
                        
                        // Selection indicator
                        if let index = selectedIndex, enableInteraction {
                            selectionIndicator(index: index, chartArea: chartArea)
                        }
                    }
                    .offset(x: chartArea.minX, y: chartArea.minY)
                    
                    // Tooltip
                    if showTooltip, let index = selectedIndex {
                        tooltipView(index: index)
                            .position(x: min(max(touchLocation.x, 80), geometry.size.width - 80), y: max(touchLocation.y - 60, 40))
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
        .accessibilityLabel("Area chart with \(data.count) series")
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
            ForEach(0...yAxisGridCount, id: \.self) { index in
                let y = chartArea.minY + chartArea.height * CGFloat(index) / CGFloat(yAxisGridCount)
                
                Path { path in
                    path.move(to: CGPoint(x: chartArea.minX, y: y))
                    path.addLine(to: CGPoint(x: chartArea.maxX, y: y))
                }
                .stroke(theme.gridColor, lineWidth: 0.5)
            }
        }
    }
    
    // MARK: - Y-Axis Labels
    
    private func yAxisLabelsView(chartArea: CGRect) -> some View {
        ForEach(0...yAxisGridCount, id: \.self) { index in
            let value = maxValue * Double(yAxisGridCount - index) / Double(yAxisGridCount)
            let y = chartArea.minY + chartArea.height * CGFloat(index) / CGFloat(yAxisGridCount)
            let label = areaStyle == .normalized ? String(format: "%.0f%%", value) : formatValue(value)
            
            Text(label)
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
    
    // MARK: - Overlapped Area
    
    private func overlappedArea(series: AreaDataSeries, chartArea: CGRect) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        let isSelected = selectedSeries == nil || selectedSeries == series.name
        let points = calculatePoints(values: series.values, chartArea: chartArea, maxVal: maxValue)
        
        return ZStack {
            // Fill
            Path { path in
                guard points.count >= 2 else { return }
                
                path.move(to: CGPoint(x: points[0].x, y: chartArea.height))
                addCurvedPath(to: &path, points: points)
                path.addLine(to: CGPoint(x: points.last!.x, y: chartArea.height))
                path.closeSubpath()
            }
            .fill(
                showGradient ?
                LinearGradient(
                    colors: [color.opacity(gradientOpacity * animationProgress), color.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(colors: [color.opacity(0.5 * animationProgress)], startPoint: .top, endPoint: .bottom)
            )
            .opacity(isSelected ? 1.0 : 0.3)
            
            // Stroke
            if showStrokes {
                Path { path in
                    guard points.count >= 2 else { return }
                    path.move(to: points[0])
                    addCurvedPath(to: &path, points: points)
                }
                .trim(from: 0, to: animationProgress)
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                .opacity(isSelected ? 1.0 : 0.3)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSeries = selectedSeries == series.name ? nil : series.name
            }
        }
    }
    
    // MARK: - Stacked Areas
    
    private func stackedAreas(chartArea: CGRect) -> some View {
        let stackedData = calculateStackedData()
        
        return ZStack {
            ForEach(Array(data.enumerated().reversed()), id: \.offset) { index, series in
                let color = series.color ?? theme.color(at: index)
                let isSelected = selectedSeries == nil || selectedSeries == series.name
                
                let topPoints = stackedData[index].map { CGPoint(x: $0.x * chartArea.width, y: (1 - $0.topY) * chartArea.height * animationProgress) }
                let bottomPoints = stackedData[index].map { CGPoint(x: $0.x * chartArea.width, y: (1 - $0.bottomY) * chartArea.height * animationProgress) }
                
                ZStack {
                    // Fill
                    Path { path in
                        guard topPoints.count >= 2 else { return }
                        
                        // Start from bottom-left
                        path.move(to: CGPoint(x: bottomPoints[0].x, y: chartArea.height - bottomPoints[0].y + chartArea.height * (1 - animationProgress)))
                        
                        // Draw bottom edge (left to right)
                        for point in bottomPoints {
                            let adjustedY = chartArea.height - point.y + chartArea.height * (1 - animationProgress)
                            addCurvedLine(to: &path, endPoint: CGPoint(x: point.x, y: adjustedY))
                        }
                        
                        // Draw right edge (bottom to top)
                        let lastTopY = chartArea.height - topPoints.last!.y + chartArea.height * (1 - animationProgress)
                        path.addLine(to: CGPoint(x: topPoints.last!.x, y: lastTopY))
                        
                        // Draw top edge (right to left)
                        for point in topPoints.reversed() {
                            let adjustedY = chartArea.height - point.y + chartArea.height * (1 - animationProgress)
                            addCurvedLine(to: &path, endPoint: CGPoint(x: point.x, y: adjustedY))
                        }
                        
                        path.closeSubpath()
                    }
                    .fill(
                        showGradient ?
                        LinearGradient(
                            colors: [color.opacity(gradientOpacity), color.opacity(gradientOpacity * 0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(colors: [color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                    .opacity(isSelected ? 1.0 : 0.3)
                    
                    // Stroke on top
                    if showStrokes {
                        Path { path in
                            guard topPoints.count >= 2 else { return }
                            let firstY = chartArea.height - topPoints[0].y + chartArea.height * (1 - animationProgress)
                            path.move(to: CGPoint(x: topPoints[0].x, y: firstY))
                            
                            for point in topPoints.dropFirst() {
                                let adjustedY = chartArea.height - point.y + chartArea.height * (1 - animationProgress)
                                addCurvedLine(to: &path, endPoint: CGPoint(x: point.x, y: adjustedY))
                            }
                        }
                        .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                        .opacity(isSelected ? 1.0 : 0.3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSeries = selectedSeries == series.name ? nil : series.name
                    }
                }
            }
        }
    }
    
    // MARK: - Stream Areas
    
    private func streamAreas(chartArea: CGRect) -> some View {
        // Stream graph centers the stack around the baseline
        let streamData = calculateStreamData()
        
        return ZStack {
            ForEach(Array(data.enumerated().reversed()), id: \.offset) { index, series in
                let color = series.color ?? theme.color(at: index)
                let isSelected = selectedSeries == nil || selectedSeries == series.name
                
                let topPoints = streamData[index].map { CGPoint(x: $0.x * chartArea.width, y: (0.5 - $0.topY / 2) * chartArea.height) }
                let bottomPoints = streamData[index].map { CGPoint(x: $0.x * chartArea.width, y: (0.5 + $0.bottomY / 2) * chartArea.height) }
                
                Path { path in
                    guard topPoints.count >= 2 else { return }
                    
                    path.move(to: CGPoint(x: bottomPoints[0].x, y: bottomPoints[0].y))
                    
                    for point in bottomPoints {
                        addCurvedLine(to: &path, endPoint: point)
                    }
                    
                    path.addLine(to: CGPoint(x: topPoints.last!.x, y: topPoints.last!.y))
                    
                    for point in topPoints.reversed() {
                        addCurvedLine(to: &path, endPoint: point)
                    }
                    
                    path.closeSubpath()
                }
                .fill(
                    showGradient ?
                    LinearGradient(
                        colors: [color.opacity(gradientOpacity * animationProgress), color.opacity(gradientOpacity * 0.5 * animationProgress)],
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(colors: [color.opacity(0.7 * animationProgress)], startPoint: .top, endPoint: .bottom)
                )
                .opacity(isSelected ? 1.0 : 0.3)
            }
        }
    }
    
    // MARK: - Points View
    
    private func pointsView(chartArea: CGRect) -> some View {
        ForEach(data) { series in
            let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
            let isSelected = selectedSeries == nil || selectedSeries == series.name
            let points = calculatePoints(values: series.values, chartArea: chartArea, maxVal: maxValue)
            
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                let isHighlighted = selectedIndex == index
                
                Circle()
                    .fill(color)
                    .frame(width: (isHighlighted ? pointRadius * 1.5 : pointRadius) * 2, height: (isHighlighted ? pointRadius * 1.5 : pointRadius) * 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isHighlighted ? 2 : 1)
                    )
                    .position(point)
                    .opacity(animationProgress * (isSelected ? 1.0 : 0.3))
            }
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
            ForEach(Array(data.enumerated()), id: \.offset) { index, series in
                let color = series.color ?? theme.color(at: index)
                let isSelected = selectedSeries == nil || selectedSeries == series.name
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
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
    
    private func calculatePoints(values: [Double], chartArea: CGRect, maxVal: Double) -> [CGPoint] {
        values.enumerated().map { index, value in
            let x = chartArea.width * CGFloat(index) / CGFloat(max(maxDataPoints - 1, 1))
            let normalizedValue = value / maxVal
            let y = chartArea.height * (1 - CGFloat(normalizedValue) * animationProgress)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func calculateStackedData() -> [[(x: CGFloat, topY: CGFloat, bottomY: CGFloat)]] {
        var result: [[(x: CGFloat, topY: CGFloat, bottomY: CGFloat)]] = []
        
        for seriesIndex in 0..<data.count {
            var seriesData: [(x: CGFloat, topY: CGFloat, bottomY: CGFloat)] = []
            
            for pointIndex in 0..<maxDataPoints {
                let x = CGFloat(pointIndex) / CGFloat(max(maxDataPoints - 1, 1))
                
                // Calculate total for normalized style
                let total: Double
                if areaStyle == .normalized {
                    total = data.reduce(0.0) { result, series in
                        result + (pointIndex < series.values.count ? max(0, series.values[pointIndex]) : 0)
                    }
                } else {
                    total = maxValue
                }
                
                // Calculate bottom (sum of all series below)
                var bottomSum: Double = 0
                for i in 0..<seriesIndex {
                    if pointIndex < data[i].values.count {
                        bottomSum += max(0, data[i].values[pointIndex])
                    }
                }
                
                // Calculate top
                let value = pointIndex < data[seriesIndex].values.count ? max(0, data[seriesIndex].values[pointIndex]) : 0
                let topSum = bottomSum + value
                
                let bottomY = total > 0 ? CGFloat(bottomSum / total) : 0
                let topY = total > 0 ? CGFloat(topSum / total) : 0
                
                seriesData.append((x: x, topY: topY, bottomY: bottomY))
            }
            
            result.append(seriesData)
        }
        
        return result
    }
    
    private func calculateStreamData() -> [[(x: CGFloat, topY: CGFloat, bottomY: CGFloat)]] {
        // Simplified stream layout
        var result: [[(x: CGFloat, topY: CGFloat, bottomY: CGFloat)]] = []
        
        for seriesIndex in 0..<data.count {
            var seriesData: [(x: CGFloat, topY: CGFloat, bottomY: CGFloat)] = []
            
            for pointIndex in 0..<maxDataPoints {
                let x = CGFloat(pointIndex) / CGFloat(max(maxDataPoints - 1, 1))
                
                let total = data.reduce(0.0) { result, series in
                    result + (pointIndex < series.values.count ? max(0, series.values[pointIndex]) : 0)
                }
                
                var offsetBelow: Double = 0
                for i in 0..<seriesIndex {
                    if pointIndex < data[i].values.count {
                        offsetBelow += max(0, data[i].values[pointIndex])
                    }
                }
                
                let value = pointIndex < data[seriesIndex].values.count ? max(0, data[seriesIndex].values[pointIndex]) : 0
                let normalizedValue = total > 0 ? value / total : 0
                let normalizedOffset = total > 0 ? offsetBelow / total : 0
                
                let topY = CGFloat(normalizedOffset + normalizedValue) * animationProgress
                let bottomY = CGFloat(normalizedOffset) * animationProgress
                
                seriesData.append((x: x, topY: topY, bottomY: bottomY))
            }
            
            result.append(seriesData)
        }
        
        return result
    }
    
    private func addCurvedPath(to path: inout Path, points: [CGPoint]) {
        guard points.count >= 2 else { return }
        
        switch curveType {
        case .linear:
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
            
        case .step:
            for i in 1..<points.count {
                let current = points[i]
                let previous = points[i - 1]
                path.addLine(to: CGPoint(x: current.x, y: previous.y))
                path.addLine(to: current)
            }
        }
    }
    
    private func addCurvedLine(to path: inout Path, endPoint: CGPoint) {
        // Simple line for stacked areas
        path.addLine(to: endPoint)
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

// MARK: - Area Style

/// Area chart stacking styles.
public enum AreaStyle: String, CaseIterable {
    /// Areas overlap each other
    case overlapped
    /// Areas stacked on top of each other
    case stacked
    /// Areas stacked and normalized to 100%
    case normalized
    /// Stream graph layout (centered baseline)
    case stream
}

/// Area curve interpolation types.
public enum AreaCurveType: String, CaseIterable {
    /// Straight line segments
    case linear
    /// Smooth bezier curves
    case curved
    /// Step function
    case step
}

// MARK: - Area Data Series

/// A data series for area charts.
public struct AreaDataSeries: Identifiable {
    public let id: UUID
    
    /// The name of the series
    public let name: String
    
    /// The Y values
    public let values: [Double]
    
    /// Optional custom color
    public var color: Color?
    
    /// Creates an area data series.
    public init(
        id: UUID = UUID(),
        name: String,
        values: [Double],
        color: Color? = nil
    ) {
        self.id = id
        self.name = name
        self.values = values
        self.color = color
    }
}

// MARK: - View Extension

public extension AreaChart {
    /// Sets the area stacking style.
    func areaStyle(_ style: AreaStyle) -> AreaChart {
        var copy = self
        copy.areaStyle = style
        return copy
    }
    
    /// Sets the curve interpolation type.
    func curveType(_ type: AreaCurveType) -> AreaChart {
        var copy = self
        copy.curveType = type
        return copy
    }
    
    /// Shows or hides gradient fills.
    func showGradient(_ show: Bool, opacity: Double = 0.6) -> AreaChart {
        var copy = self
        copy.showGradient = show
        copy.gradientOpacity = opacity
        return copy
    }
}

// MARK: - Preview Provider

#if DEBUG
struct AreaChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            AreaDataSeries(name: "Desktop", values: [30, 35, 40, 38, 45, 50, 48], color: .blue),
            AreaDataSeries(name: "Mobile", values: [20, 25, 30, 35, 40, 45, 50], color: .green),
            AreaDataSeries(name: "Tablet", values: [10, 12, 15, 13, 18, 20, 22], color: .orange)
        ]
        
        VStack(spacing: 20) {
            AreaChart(data: data, labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
                .areaStyle(.stacked)
                .frame(height: 250)
            
            AreaChart(data: data, labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
                .areaStyle(.stream)
                .frame(height: 250)
        }
        .padding()
    }
}
#endif
