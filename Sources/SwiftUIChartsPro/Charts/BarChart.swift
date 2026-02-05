import SwiftUI

// MARK: - Bar Chart

/// A high-performance bar chart with support for grouped, stacked, and horizontal layouts.
///
/// Bar charts are excellent for comparing discrete categories. This implementation
/// provides smooth animations, interactive selection, and multiple layout options.
///
/// ```swift
/// let data = [
///     BarDataSeries(name: "2023", values: [100, 150, 200]),
///     BarDataSeries(name: "2024", values: [120, 180, 220])
/// ]
///
/// BarChart(data: data, labels: ["Q1", "Q2", "Q3"])
///     .barStyle(.grouped)
///     .cornerRadius(4)
/// ```
public struct BarChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data series to display
    public let data: [BarDataSeries]
    
    /// X-axis labels for each category
    public let labels: [String]
    
    /// Bar layout style
    public var barStyle: BarStyle
    
    /// Bar corner radius
    public var cornerRadius: CGFloat
    
    /// Spacing between bar groups
    public var groupSpacing: CGFloat
    
    /// Spacing between bars within a group
    public var barSpacing: CGFloat
    
    /// Whether to show value labels on bars
    public var showValueLabels: Bool
    
    /// Whether to show grid lines
    public var showGrid: Bool
    
    /// Number of Y-axis grid lines
    public var yAxisGridCount: Int
    
    /// Whether to show X-axis labels
    public var showXAxisLabels: Bool
    
    /// Whether to show Y-axis labels
    public var showYAxisLabels: Bool
    
    /// Whether bars are horizontal
    public var isHorizontal: Bool
    
    /// Y-axis minimum value (auto if nil)
    public var yAxisMin: Double?
    
    /// Y-axis maximum value (auto if nil)
    public var yAxisMax: Double?
    
    /// Whether to enable touch interaction
    public var enableInteraction: Bool
    
    /// Whether to show gradient fills
    public var showGradient: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedBarIndex: (series: Int, bar: Int)?
    @State private var showTooltip: Bool = false
    @State private var tooltipPosition: CGPoint = .zero
    
    /// Creates a bar chart.
    public init(
        data: [BarDataSeries],
        labels: [String] = [],
        barStyle: BarStyle = .grouped,
        cornerRadius: CGFloat = 4,
        groupSpacing: CGFloat = 8,
        barSpacing: CGFloat = 2,
        showValueLabels: Bool = false,
        showGrid: Bool = true,
        yAxisGridCount: Int = 5,
        showXAxisLabels: Bool = true,
        showYAxisLabels: Bool = true,
        isHorizontal: Bool = false,
        yAxisMin: Double? = nil,
        yAxisMax: Double? = nil,
        enableInteraction: Bool = true,
        showGradient: Bool = true
    ) {
        self.data = data
        self.labels = labels
        self.barStyle = barStyle
        self.cornerRadius = cornerRadius
        self.groupSpacing = groupSpacing
        self.barSpacing = barSpacing
        self.showValueLabels = showValueLabels
        self.showGrid = showGrid
        self.yAxisGridCount = yAxisGridCount
        self.showXAxisLabels = showXAxisLabels
        self.showYAxisLabels = showYAxisLabels
        self.isHorizontal = isHorizontal
        self.yAxisMin = yAxisMin
        self.yAxisMax = yAxisMax
        self.enableInteraction = enableInteraction
        self.showGradient = showGradient
    }
    
    private var categoryCount: Int {
        data.map { $0.values.count }.max() ?? 0
    }
    
    private var minValue: Double {
        if barStyle == .stacked {
            return yAxisMin ?? 0
        }
        return yAxisMin ?? min(0, data.flatMap { $0.values }.min() ?? 0)
    }
    
    private var maxValue: Double {
        if barStyle == .stacked {
            // For stacked, calculate max sum per category
            var maxSum: Double = 0
            for i in 0..<categoryCount {
                let sum = data.reduce(0.0) { result, series in
                    result + (i < series.values.count ? max(0, series.values[i]) : 0)
                }
                maxSum = max(maxSum, sum)
            }
            return yAxisMax ?? maxSum
        }
        return yAxisMax ?? (data.flatMap { $0.values }.max() ?? 100)
    }
    
    private var valueRange: Double {
        max(maxValue - minValue, 0.001)
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
                    
                    // Bars
                    barsView(chartArea: chartArea)
                        .offset(x: chartArea.minX, y: chartArea.minY)
                    
                    // Tooltip
                    if showTooltip, let selected = selectedBarIndex {
                        tooltipView(seriesIndex: selected.series, barIndex: selected.bar)
                            .position(tooltipPosition)
                    }
                }
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
        .accessibilityLabel("Bar chart with \(data.count) series and \(categoryCount) categories")
    }
    
    // MARK: - Chart Area Calculation
    
    private func calculateChartArea(size: CGSize) -> CGRect {
        let leftPadding: CGFloat = showYAxisLabels ? 50 : 16
        let bottomPadding: CGFloat = showXAxisLabels ? 40 : 16
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
            
            // Zero line if applicable
            if minValue < 0 && maxValue > 0 {
                let zeroY = chartArea.minY + chartArea.height * CGFloat(maxValue / valueRange)
                
                Path { path in
                    path.move(to: CGPoint(x: chartArea.minX, y: zeroY))
                    path.addLine(to: CGPoint(x: chartArea.maxX, y: zeroY))
                }
                .stroke(theme.foregroundColor.opacity(0.5), lineWidth: 1)
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
        ForEach(0..<categoryCount, id: \.self) { index in
            if index < labels.count {
                let groupWidth = chartArea.width / CGFloat(categoryCount)
                let x = chartArea.minX + groupWidth * (CGFloat(index) + 0.5)
                
                Text(labels[index])
                    .font(theme.font)
                    .foregroundColor(theme.foregroundColor.opacity(0.7))
                    .lineLimit(1)
                    .frame(width: groupWidth - 4)
                    .position(x: x, y: size.height - 15)
            }
        }
    }
    
    // MARK: - Bars View
    
    private func barsView(chartArea: CGRect) -> some View {
        let groupWidth = chartArea.width / CGFloat(categoryCount)
        let availableWidth = groupWidth - groupSpacing
        
        return ZStack {
            ForEach(0..<categoryCount, id: \.self) { categoryIndex in
                let groupX = groupWidth * CGFloat(categoryIndex) + groupSpacing / 2
                
                switch barStyle {
                case .grouped:
                    groupedBars(categoryIndex: categoryIndex, groupX: groupX, availableWidth: availableWidth, chartArea: chartArea)
                    
                case .stacked:
                    stackedBars(categoryIndex: categoryIndex, groupX: groupX, availableWidth: availableWidth, chartArea: chartArea)
                    
                case .percentStacked:
                    percentStackedBars(categoryIndex: categoryIndex, groupX: groupX, availableWidth: availableWidth, chartArea: chartArea)
                }
            }
        }
    }
    
    // MARK: - Grouped Bars
    
    private func groupedBars(categoryIndex: Int, groupX: CGFloat, availableWidth: CGFloat, chartArea: CGRect) -> some View {
        let barWidth = (availableWidth - CGFloat(data.count - 1) * barSpacing) / CGFloat(data.count)
        
        return ForEach(Array(data.enumerated()), id: \.offset) { seriesIndex, series in
            if categoryIndex < series.values.count {
                let value = series.values[categoryIndex]
                let color = series.color ?? theme.color(at: seriesIndex)
                let barX = groupX + CGFloat(seriesIndex) * (barWidth + barSpacing)
                let isSelected = selectedBarIndex?.series == seriesIndex && selectedBarIndex?.bar == categoryIndex
                
                singleBar(
                    value: value,
                    color: color,
                    x: barX,
                    width: barWidth,
                    chartArea: chartArea,
                    isSelected: isSelected,
                    seriesIndex: seriesIndex,
                    barIndex: categoryIndex
                )
            }
        }
    }
    
    // MARK: - Stacked Bars
    
    private func stackedBars(categoryIndex: Int, groupX: CGFloat, availableWidth: CGFloat, chartArea: CGRect) -> some View {
        var runningHeight: CGFloat = 0
        
        return ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { seriesIndex, series in
                if categoryIndex < series.values.count {
                    let value = max(0, series.values[categoryIndex])
                    let color = series.color ?? theme.color(at: seriesIndex)
                    let normalizedValue = value / valueRange
                    let barHeight = chartArea.height * CGFloat(normalizedValue) * animationProgress
                    let isSelected = selectedBarIndex?.series == seriesIndex && selectedBarIndex?.bar == categoryIndex
                    
                    let yPos = chartArea.height - runningHeight - barHeight
                    
                    let _ = runningHeight += barHeight
                    
                    stackedBarSegment(
                        color: color,
                        x: groupX,
                        y: yPos,
                        width: availableWidth,
                        height: barHeight,
                        isSelected: isSelected,
                        isTop: seriesIndex == data.count - 1,
                        isBottom: seriesIndex == 0,
                        seriesIndex: seriesIndex,
                        barIndex: categoryIndex
                    )
                }
            }
        }
    }
    
    // MARK: - Percent Stacked Bars
    
    private func percentStackedBars(categoryIndex: Int, groupX: CGFloat, availableWidth: CGFloat, chartArea: CGRect) -> some View {
        let total = data.reduce(0.0) { result, series in
            result + (categoryIndex < series.values.count ? max(0, series.values[categoryIndex]) : 0)
        }
        var runningHeight: CGFloat = 0
        
        return ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { seriesIndex, series in
                if categoryIndex < series.values.count && total > 0 {
                    let value = max(0, series.values[categoryIndex])
                    let color = series.color ?? theme.color(at: seriesIndex)
                    let percentage = value / total
                    let barHeight = chartArea.height * CGFloat(percentage) * animationProgress
                    let isSelected = selectedBarIndex?.series == seriesIndex && selectedBarIndex?.bar == categoryIndex
                    
                    let yPos = chartArea.height - runningHeight - barHeight
                    
                    let _ = runningHeight += barHeight
                    
                    stackedBarSegment(
                        color: color,
                        x: groupX,
                        y: yPos,
                        width: availableWidth,
                        height: barHeight,
                        isSelected: isSelected,
                        isTop: seriesIndex == data.count - 1,
                        isBottom: seriesIndex == 0,
                        seriesIndex: seriesIndex,
                        barIndex: categoryIndex
                    )
                }
            }
        }
    }
    
    // MARK: - Single Bar
    
    private func singleBar(value: Double, color: Color, x: CGFloat, width: CGFloat, chartArea: CGRect, isSelected: Bool, seriesIndex: Int, barIndex: Int) -> some View {
        let normalizedValue = (value - minValue) / valueRange
        let barHeight = chartArea.height * CGFloat(normalizedValue) * animationProgress
        let yPos = value >= 0 ? chartArea.height - barHeight : chartArea.height * CGFloat((maxValue - minValue) / valueRange)
        
        return ZStack {
            if showGradient {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width, height: abs(barHeight))
                    .position(x: x + width / 2, y: yPos + abs(barHeight) / 2)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .frame(width: width, height: abs(barHeight))
                    .position(x: x + width / 2, y: yPos + abs(barHeight) / 2)
            }
            
            // Value label
            if showValueLabels && animationProgress > 0.9 {
                Text(formatValue(value))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(theme.foregroundColor)
                    .position(x: x + width / 2, y: yPos - 8)
            }
        }
        .opacity(isSelected ? 1.0 : (selectedBarIndex == nil ? 1.0 : 0.5))
        .scaleEffect(isSelected ? CGSize(width: 1.05, height: 1.0) : CGSize(width: 1.0, height: 1.0), anchor: .bottom)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture {
            handleBarTap(seriesIndex: seriesIndex, barIndex: barIndex, position: CGPoint(x: x + width / 2, y: yPos))
        }
    }
    
    // MARK: - Stacked Bar Segment
    
    private func stackedBarSegment(color: Color, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, isSelected: Bool, isTop: Bool, isBottom: Bool, seriesIndex: Int, barIndex: Int) -> some View {
        let corners: UIRectCorner = {
            if isTop && isBottom { return .allCorners }
            if isTop { return [.topLeft, .topRight] }
            if isBottom { return [.bottomLeft, .bottomRight] }
            return []
        }()
        
        return ZStack {
            if showGradient {
                RoundedCornerShape(radius: cornerRadius, corners: corners)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width, height: max(0, height))
                    .position(x: x + width / 2, y: y + height / 2)
            } else {
                RoundedCornerShape(radius: cornerRadius, corners: corners)
                    .fill(color)
                    .frame(width: width, height: max(0, height))
                    .position(x: x + width / 2, y: y + height / 2)
            }
        }
        .opacity(isSelected ? 1.0 : (selectedBarIndex == nil ? 1.0 : 0.5))
        .contentShape(Rectangle())
        .onTapGesture {
            handleBarTap(seriesIndex: seriesIndex, barIndex: barIndex, position: CGPoint(x: x + width / 2, y: y))
        }
    }
    
    // MARK: - Tooltip
    
    private func tooltipView(seriesIndex: Int, barIndex: Int) -> some View {
        let series = data[seriesIndex]
        let value = barIndex < series.values.count ? series.values[barIndex] : 0
        let color = series.color ?? theme.color(at: seriesIndex)
        
        return VStack(alignment: .leading, spacing: 4) {
            if barIndex < labels.count {
                Text(labels[barIndex])
                    .font(.caption.bold())
                    .foregroundColor(theme.foregroundColor)
            }
            
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text("\(series.name): \(formatValue(value))")
                    .font(.caption)
                    .foregroundColor(theme.foregroundColor.opacity(0.8))
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
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text(series.name)
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleBarTap(seriesIndex: Int, barIndex: Int, position: CGPoint) {
        guard enableInteraction else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedBarIndex?.series == seriesIndex && selectedBarIndex?.bar == barIndex {
                selectedBarIndex = nil
                showTooltip = false
            } else {
                selectedBarIndex = (series: seriesIndex, bar: barIndex)
                tooltipPosition = CGPoint(x: position.x + 50, y: max(position.y, 50))
                showTooltip = true
            }
        }
        
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
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

// MARK: - Bar Style

/// Bar chart layout styles.
public enum BarStyle: String, CaseIterable {
    /// Bars grouped side by side
    case grouped
    /// Bars stacked on top of each other
    case stacked
    /// Bars stacked and normalized to 100%
    case percentStacked
}

// MARK: - Bar Data Series

/// A data series for bar charts.
public struct BarDataSeries: Identifiable {
    public let id: UUID
    
    /// The name of the series
    public let name: String
    
    /// The values for each category
    public let values: [Double]
    
    /// Optional custom color
    public var color: Color?
    
    /// Creates a bar data series.
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

// MARK: - Rounded Corner Shape

/// A shape with individually rounded corners.
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Extension

public extension BarChart {
    /// Sets the bar layout style.
    func barStyle(_ style: BarStyle) -> BarChart {
        var copy = self
        copy.barStyle = style
        return copy
    }
    
    /// Sets the corner radius for bars.
    func cornerRadius(_ radius: CGFloat) -> BarChart {
        var copy = self
        copy.cornerRadius = radius
        return copy
    }
    
    /// Shows value labels on bars.
    func showValueLabels(_ show: Bool) -> BarChart {
        var copy = self
        copy.showValueLabels = show
        return copy
    }
    
    /// Sets the Y-axis range.
    func yAxisRange(min: Double?, max: Double?) -> BarChart {
        var copy = self
        copy.yAxisMin = min
        copy.yAxisMax = max
        return copy
    }
}

// MARK: - Preview Provider

#if DEBUG
struct BarChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            BarDataSeries(name: "2023", values: [100, 150, 200, 180], color: .blue),
            BarDataSeries(name: "2024", values: [120, 180, 220, 200], color: .green)
        ]
        
        VStack(spacing: 20) {
            BarChart(data: data, labels: ["Q1", "Q2", "Q3", "Q4"])
                .barStyle(.grouped)
                .frame(height: 250)
            
            BarChart(data: data, labels: ["Q1", "Q2", "Q3", "Q4"])
                .barStyle(.stacked)
                .frame(height: 250)
        }
        .padding()
    }
}
#endif
