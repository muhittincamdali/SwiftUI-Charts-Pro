import SwiftUI

// MARK: - Box Plot Chart

/// A statistical chart showing data distribution through quartiles.
///
/// Box plots (box-and-whisker plots) display the five-number summary:
/// minimum, first quartile (Q1), median, third quartile (Q3), and maximum.
///
/// ```swift
/// let data = [
///     BoxPlotData(label: "Group A", values: [10, 20, 30, 40, 50, 60, 70]),
///     BoxPlotData(label: "Group B", values: [15, 25, 35, 45, 55, 65, 75])
/// ]
///
/// BoxPlotChart(data: data)
/// ```
public struct BoxPlotChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The box plot data sets
    public let data: [BoxPlotData]
    
    /// Whether to show outliers
    public let showOutliers: Bool
    
    /// Whether to show mean marker
    public let showMean: Bool
    
    /// Whether to show notches (confidence interval)
    public let showNotches: Bool
    
    /// Whether to show values on hover
    public let showValues: Bool
    
    /// Width of each box
    public let boxWidth: CGFloat
    
    /// Width of whisker caps
    public let whiskerWidth: CGFloat
    
    /// Whether to fill the box
    public let fillBox: Bool
    
    /// Box fill opacity
    public let fillOpacity: Double
    
    /// Orientation
    public let isHorizontal: Bool
    
    /// Value format string
    public let valueFormat: String
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var hoveredIndex: Int?
    
    /// Creates a box plot chart.
    public init(
        data: [BoxPlotData],
        showOutliers: Bool = true,
        showMean: Bool = true,
        showNotches: Bool = false,
        showValues: Bool = true,
        boxWidth: CGFloat = 40,
        whiskerWidth: CGFloat = 20,
        fillBox: Bool = true,
        fillOpacity: Double = 0.3,
        isHorizontal: Bool = false,
        valueFormat: String = "%.1f"
    ) {
        self.data = data
        self.showOutliers = showOutliers
        self.showMean = showMean
        self.showNotches = showNotches
        self.showValues = showValues
        self.boxWidth = boxWidth
        self.whiskerWidth = whiskerWidth
        self.fillBox = fillBox
        self.fillOpacity = fillOpacity
        self.isHorizontal = isHorizontal
        self.valueFormat = valueFormat
    }
    
    private var valueRange: (min: Double, max: Double) {
        var allValues: [Double] = []
        
        for item in data {
            allValues.append(item.stats.min)
            allValues.append(item.stats.max)
            allValues.append(contentsOf: item.stats.outliers)
        }
        
        let min = allValues.min() ?? 0
        let max = allValues.max() ?? 100
        let padding = (max - min) * 0.1
        
        return (min - padding, max + padding)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if isHorizontal {
                horizontalBoxPlot(size: geometry.size)
            } else {
                verticalBoxPlot(size: geometry.size)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Box plot chart with \(data.count) groups")
    }
    
    // MARK: - Vertical Box Plot
    
    private func verticalBoxPlot(size: CGSize) -> some View {
        let labelHeight: CGFloat = 30
        let axisWidth: CGFloat = 50
        let chartHeight = size.height - labelHeight
        let chartWidth = size.width - axisWidth
        let spacing = (chartWidth - CGFloat(data.count) * boxWidth) / CGFloat(data.count + 1)
        
        return ZStack(alignment: .topLeading) {
            // Grid
            gridLines(width: chartWidth, height: chartHeight)
                .offset(x: axisWidth)
            
            // Y axis labels
            yAxisLabels(height: chartHeight)
            
            // Box plots
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 4) {
                        verticalBox(item: item, index: index, chartHeight: chartHeight)
                            .frame(width: boxWidth, height: chartHeight)
                        
                        // Label
                        Text(item.label)
                            .font(.caption)
                            .foregroundColor(theme.foregroundColor)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, axisWidth + spacing)
            
            // Tooltip
            if let index = selectedIndex, index < data.count {
                tooltipView(for: data[index], index: index)
            }
        }
    }
    
    @ViewBuilder
    private func verticalBox(item: BoxPlotData, index: Int, chartHeight: CGFloat) -> some View {
        let stats = item.stats
        let color = item.color ?? theme.color(at: index)
        let isSelected = selectedIndex == index
        let isHovered = hoveredIndex == index
        
        let range = valueRange.max - valueRange.min
        guard range > 0 else { return EmptyView().eraseToAnyView() }
        
        let scale: (Double) -> CGFloat = { value in
            chartHeight - CGFloat((value - valueRange.min) / range) * chartHeight
        }
        
        let minY = scale(stats.min)
        let q1Y = scale(stats.q1)
        let medianY = scale(stats.median)
        let q3Y = scale(stats.q3)
        let maxY = scale(stats.max)
        let meanY = scale(stats.mean)
        
        ZStack {
            // Lower whisker
            Path { path in
                path.move(to: CGPoint(x: boxWidth / 2, y: minY))
                path.addLine(to: CGPoint(x: boxWidth / 2, y: q1Y))
            }
            .stroke(color, lineWidth: 1)
            .opacity(animationProgress)
            
            // Lower whisker cap
            Path { path in
                path.move(to: CGPoint(x: (boxWidth - whiskerWidth) / 2, y: minY))
                path.addLine(to: CGPoint(x: (boxWidth + whiskerWidth) / 2, y: minY))
            }
            .stroke(color, lineWidth: 2)
            .opacity(animationProgress)
            
            // Upper whisker
            Path { path in
                path.move(to: CGPoint(x: boxWidth / 2, y: q3Y))
                path.addLine(to: CGPoint(x: boxWidth / 2, y: maxY))
            }
            .stroke(color, lineWidth: 1)
            .opacity(animationProgress)
            
            // Upper whisker cap
            Path { path in
                path.move(to: CGPoint(x: (boxWidth - whiskerWidth) / 2, y: maxY))
                path.addLine(to: CGPoint(x: (boxWidth + whiskerWidth) / 2, y: maxY))
            }
            .stroke(color, lineWidth: 2)
            .opacity(animationProgress)
            
            // Box
            if showNotches {
                notchedBoxPath(q1Y: q1Y, medianY: medianY, q3Y: q3Y, stats: stats, chartHeight: chartHeight)
                    .fill(fillBox ? color.opacity(fillOpacity) : .clear)
                    .overlay(
                        notchedBoxPath(q1Y: q1Y, medianY: medianY, q3Y: q3Y, stats: stats, chartHeight: chartHeight)
                            .stroke(color, lineWidth: isSelected ? 3 : 2)
                    )
                    .opacity(animationProgress)
            } else {
                Rectangle()
                    .fill(fillBox ? color.opacity(fillOpacity) : .clear)
                    .frame(width: boxWidth, height: abs(q1Y - q3Y) * animationProgress)
                    .overlay(
                        Rectangle()
                            .stroke(color, lineWidth: isSelected ? 3 : 2)
                    )
                    .position(x: boxWidth / 2, y: (q1Y + q3Y) / 2)
            }
            
            // Median line
            Path { path in
                path.move(to: CGPoint(x: 0, y: medianY))
                path.addLine(to: CGPoint(x: boxWidth, y: medianY))
            }
            .stroke(color, lineWidth: 3)
            .opacity(animationProgress)
            
            // Mean marker
            if showMean {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .position(x: boxWidth / 2, y: meanY)
                    .opacity(animationProgress)
            }
            
            // Outliers
            if showOutliers {
                ForEach(Array(stats.outliers.enumerated()), id: \.offset) { _, outlier in
                    let y = scale(outlier)
                    Circle()
                        .stroke(color, lineWidth: 1)
                        .frame(width: 6, height: 6)
                        .position(x: boxWidth / 2, y: y)
                        .opacity(animationProgress)
                }
            }
            
            // Hover highlight
            if isHovered {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: boxWidth + 10, height: chartHeight)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = selectedIndex == index ? nil : index
            }
        }
        .onHover { hovering in
            hoveredIndex = hovering ? index : nil
        }
        .eraseToAnyView()
    }
    
    private func notchedBoxPath(q1Y: CGFloat, medianY: CGFloat, q3Y: CGFloat, stats: BoxPlotStatistics, chartHeight: CGFloat) -> Path {
        let notchWidth = boxWidth * 0.3
        let notchExtent = stats.notchExtent * chartHeight / CGFloat(valueRange.max - valueRange.min)
        
        return Path { path in
            path.move(to: CGPoint(x: 0, y: q1Y))
            path.addLine(to: CGPoint(x: 0, y: medianY + notchExtent))
            path.addLine(to: CGPoint(x: notchWidth, y: medianY))
            path.addLine(to: CGPoint(x: 0, y: medianY - notchExtent))
            path.addLine(to: CGPoint(x: 0, y: q3Y))
            path.addLine(to: CGPoint(x: boxWidth, y: q3Y))
            path.addLine(to: CGPoint(x: boxWidth, y: medianY - notchExtent))
            path.addLine(to: CGPoint(x: boxWidth - notchWidth, y: medianY))
            path.addLine(to: CGPoint(x: boxWidth, y: medianY + notchExtent))
            path.addLine(to: CGPoint(x: boxWidth, y: q1Y))
            path.closeSubpath()
        }
    }
    
    // MARK: - Horizontal Box Plot
    
    private func horizontalBoxPlot(size: CGSize) -> some View {
        let labelWidth: CGFloat = 80
        let axisHeight: CGFloat = 30
        let chartWidth = size.width - labelWidth
        let chartHeight = size.height - axisHeight
        let spacing = (chartHeight - CGFloat(data.count) * boxWidth) / CGFloat(data.count + 1)
        
        return ZStack(alignment: .topLeading) {
            // Grid
            horizontalGridLines(width: chartWidth, height: chartHeight)
                .offset(x: labelWidth)
            
            // X axis labels
            xAxisLabels(width: chartWidth)
                .offset(x: labelWidth, y: chartHeight)
            
            // Box plots
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Text(item.label)
                            .font(.caption)
                            .foregroundColor(theme.foregroundColor)
                            .frame(width: labelWidth, alignment: .trailing)
                        
                        horizontalBox(item: item, index: index, chartWidth: chartWidth)
                            .frame(width: chartWidth, height: boxWidth)
                    }
                }
            }
            .padding(.top, spacing)
        }
    }
    
    @ViewBuilder
    private func horizontalBox(item: BoxPlotData, index: Int, chartWidth: CGFloat) -> some View {
        let stats = item.stats
        let color = item.color ?? theme.color(at: index)
        
        let range = valueRange.max - valueRange.min
        guard range > 0 else { return EmptyView().eraseToAnyView() }
        
        let scale: (Double) -> CGFloat = { value in
            CGFloat((value - valueRange.min) / range) * chartWidth
        }
        
        let minX = scale(stats.min)
        let q1X = scale(stats.q1)
        let medianX = scale(stats.median)
        let q3X = scale(stats.q3)
        let maxX = scale(stats.max)
        
        ZStack {
            // Whiskers and box (similar logic, rotated)
            Path { path in
                path.move(to: CGPoint(x: minX, y: boxWidth / 2))
                path.addLine(to: CGPoint(x: q1X, y: boxWidth / 2))
            }
            .stroke(color, lineWidth: 1)
            
            Path { path in
                path.move(to: CGPoint(x: q3X, y: boxWidth / 2))
                path.addLine(to: CGPoint(x: maxX, y: boxWidth / 2))
            }
            .stroke(color, lineWidth: 1)
            
            Rectangle()
                .fill(fillBox ? color.opacity(fillOpacity) : .clear)
                .frame(width: (q3X - q1X) * animationProgress, height: boxWidth)
                .overlay(Rectangle().stroke(color, lineWidth: 2))
                .position(x: (q1X + q3X) / 2, y: boxWidth / 2)
            
            Path { path in
                path.move(to: CGPoint(x: medianX, y: 0))
                path.addLine(to: CGPoint(x: medianX, y: boxWidth))
            }
            .stroke(color, lineWidth: 3)
        }
        .opacity(animationProgress)
        .eraseToAnyView()
    }
    
    // MARK: - Helper Views
    
    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        let lineCount = 5
        
        return ZStack {
            ForEach(0..<lineCount, id: \.self) { i in
                let y = height * CGFloat(i) / CGFloat(lineCount - 1)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(theme.gridColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))
            }
        }
    }
    
    private func horizontalGridLines(width: CGFloat, height: CGFloat) -> some View {
        let lineCount = 5
        
        return ZStack {
            ForEach(0..<lineCount, id: \.self) { i in
                let x = width * CGFloat(i) / CGFloat(lineCount - 1)
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                .stroke(theme.gridColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))
            }
        }
    }
    
    private func yAxisLabels(height: CGFloat) -> some View {
        let labelCount = 5
        
        return VStack {
            ForEach(0..<labelCount, id: \.self) { i in
                let value = valueRange.max - (valueRange.max - valueRange.min) * Double(i) / Double(labelCount - 1)
                Text(String(format: valueFormat, value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: height / CGFloat(labelCount - 1), alignment: i == 0 ? .top : (i == labelCount - 1 ? .bottom : .center))
            }
        }
        .frame(width: 50)
    }
    
    private func xAxisLabels(width: CGFloat) -> some View {
        let labelCount = 5
        
        return HStack {
            ForEach(0..<labelCount, id: \.self) { i in
                let value = valueRange.min + (valueRange.max - valueRange.min) * Double(i) / Double(labelCount - 1)
                Text(String(format: valueFormat, value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func tooltipView(for item: BoxPlotData, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.label)
                .font(.caption.bold())
            
            Group {
                Text("Min: \(String(format: valueFormat, item.stats.min))")
                Text("Q1: \(String(format: valueFormat, item.stats.q1))")
                Text("Median: \(String(format: valueFormat, item.stats.median))")
                Text("Q3: \(String(format: valueFormat, item.stats.q3))")
                Text("Max: \(String(format: valueFormat, item.stats.max))")
                Text("Mean: \(String(format: valueFormat, item.stats.mean))")
            }
            .font(.caption2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
        )
        .foregroundColor(theme.foregroundColor)
        .position(x: 100, y: 80)
    }
}

// MARK: - Supporting Types

/// Data for a single box plot
public struct BoxPlotData: Identifiable {
    public let id: UUID
    public let label: String
    public let values: [Double]
    public var color: Color?
    
    public init(id: UUID = UUID(), label: String, values: [Double], color: Color? = nil) {
        self.id = id
        self.label = label
        self.values = values
        self.color = color
    }
    
    /// Computed statistics
    public var stats: BoxPlotStatistics {
        BoxPlotStatistics(values: values)
    }
}

/// Computed statistics for box plots
public struct BoxPlotStatistics {
    public let min: Double
    public let q1: Double
    public let median: Double
    public let q3: Double
    public let max: Double
    public let mean: Double
    public let outliers: [Double]
    public let notchExtent: Double
    
    init(values: [Double]) {
        let sorted = values.sorted()
        let n = sorted.count
        
        guard n > 0 else {
            self.min = 0
            self.q1 = 0
            self.median = 0
            self.q3 = 0
            self.max = 0
            self.mean = 0
            self.outliers = []
            self.notchExtent = 0
            return
        }
        
        self.mean = sorted.reduce(0, +) / Double(n)
        self.median = n % 2 == 0 ? (sorted[n/2 - 1] + sorted[n/2]) / 2 : sorted[n/2]
        self.q1 = sorted[n / 4]
        self.q3 = sorted[(3 * n) / 4]
        
        let iqr = q3 - q1
        let lowerFence = q1 - 1.5 * iqr
        let upperFence = q3 + 1.5 * iqr
        
        self.min = sorted.first { $0 >= lowerFence } ?? sorted[0]
        self.max = sorted.last { $0 <= upperFence } ?? sorted[n - 1]
        
        self.outliers = sorted.filter { $0 < lowerFence || $0 > upperFence }
        
        // Notch extent for 95% CI
        self.notchExtent = 1.57 * iqr / sqrt(Double(n))
    }
}

// MARK: - View Extension

private extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct BoxPlotChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            BoxPlotData(label: "Group A", values: Array(stride(from: 10.0, through: 90.0, by: 5.0)) + [5, 95, 100], color: .blue),
            BoxPlotData(label: "Group B", values: Array(stride(from: 20.0, through: 80.0, by: 5.0)) + [10, 85], color: .green),
            BoxPlotData(label: "Group C", values: Array(stride(from: 30.0, through: 100.0, by: 5.0)) + [15, 110], color: .orange)
        ]
        
        BoxPlotChart(data: data)
            .frame(height: 350)
            .padding()
    }
}
#endif
