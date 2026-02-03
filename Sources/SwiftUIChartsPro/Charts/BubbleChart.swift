import SwiftUI

// MARK: - Bubble Chart

/// A scatter plot with variable-sized bubbles representing a third dimension.
///
/// Bubble charts extend scatter plots by encoding an additional variable
/// through the size of each point, useful for showing relationships
/// between three variables.
///
/// ```swift
/// let data = [
///     XYDataPoint(x: 10, y: 20, size: 50),
///     XYDataPoint(x: 30, y: 40, size: 100),
///     XYDataPoint(x: 50, y: 30, size: 75)
/// ]
///
/// BubbleChart(data: data)
/// ```
public struct BubbleChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data points to display
    public let data: [XYDataPoint]
    
    /// Minimum bubble radius
    public let minRadius: CGFloat
    
    /// Maximum bubble radius
    public let maxRadius: CGFloat
    
    /// Bubble opacity
    public let bubbleOpacity: Double
    
    /// Whether to show grid lines
    public let showGrid: Bool
    
    /// Whether to show axis labels
    public let showAxisLabels: Bool
    
    /// Whether to show data labels
    public let showDataLabels: Bool
    
    /// X axis label
    public let xAxisLabel: String?
    
    /// Y axis label
    public let yAxisLabel: String?
    
    /// Number format for values
    public let valueFormat: String
    
    /// Whether to show connecting lines
    public let showConnectingLines: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedPoint: UUID?
    @State private var hoveredPoint: UUID?
    
    /// Creates a bubble chart.
    public init(
        data: [XYDataPoint],
        minRadius: CGFloat = 10,
        maxRadius: CGFloat = 50,
        bubbleOpacity: Double = 0.7,
        showGrid: Bool = true,
        showAxisLabels: Bool = true,
        showDataLabels: Bool = false,
        xAxisLabel: String? = nil,
        yAxisLabel: String? = nil,
        valueFormat: String = "%.1f",
        showConnectingLines: Bool = false
    ) {
        self.data = data
        self.minRadius = minRadius
        self.maxRadius = maxRadius
        self.bubbleOpacity = bubbleOpacity
        self.showGrid = showGrid
        self.showAxisLabels = showAxisLabels
        self.showDataLabels = showDataLabels
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
        self.valueFormat = valueFormat
        self.showConnectingLines = showConnectingLines
    }
    
    private var xRange: (min: Double, max: Double) {
        let values = data.map { $0.x }
        let min = values.min() ?? 0
        let max = values.max() ?? 100
        let padding = (max - min) * 0.1
        return (min - padding, max + padding)
    }
    
    private var yRange: (min: Double, max: Double) {
        let values = data.map { $0.y }
        let min = values.min() ?? 0
        let max = values.max() ?? 100
        let padding = (max - min) * 0.1
        return (min - padding, max + padding)
    }
    
    private var sizeRange: (min: Double, max: Double) {
        let sizes = data.map { $0.size }
        return (sizes.min() ?? 1, sizes.max() ?? 1)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let labelWidth: CGFloat = showAxisLabels ? 50 : 0
            let labelHeight: CGFloat = showAxisLabels ? 30 : 0
            let chartWidth = geometry.size.width - labelWidth
            let chartHeight = geometry.size.height - labelHeight
            
            ZStack(alignment: .topLeading) {
                // Grid
                if showGrid {
                    gridView(width: chartWidth, height: chartHeight)
                        .offset(x: labelWidth)
                }
                
                // Y axis labels
                if showAxisLabels {
                    yAxisLabels(height: chartHeight)
                }
                
                // X axis labels
                if showAxisLabels {
                    xAxisLabels(width: chartWidth)
                        .offset(x: labelWidth, y: chartHeight)
                }
                
                // Connecting lines
                if showConnectingLines {
                    connectingLines(width: chartWidth, height: chartHeight)
                        .offset(x: labelWidth)
                }
                
                // Bubbles
                ForEach(data) { point in
                    bubbleView(
                        point: point,
                        chartWidth: chartWidth,
                        chartHeight: chartHeight,
                        labelOffset: labelWidth
                    )
                }
                
                // Axis labels
                axisLabelsView(width: chartWidth, height: chartHeight, labelWidth: labelWidth)
                
                // Tooltip
                if let id = selectedPoint, let point = data.first(where: { $0.id == id }) {
                    tooltipView(for: point, chartWidth: chartWidth, chartHeight: chartHeight, labelOffset: labelWidth)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bubble chart with \(data.count) data points")
    }
    
    // MARK: - Grid
    
    private func gridView(width: CGFloat, height: CGFloat) -> some View {
        let xLines = 5
        let yLines = 5
        
        return ZStack {
            // Horizontal lines
            ForEach(0..<yLines, id: \.self) { i in
                let y = height * CGFloat(i) / CGFloat(yLines - 1)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(theme.gridColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))
            }
            
            // Vertical lines
            ForEach(0..<xLines, id: \.self) { i in
                let x = width * CGFloat(i) / CGFloat(xLines - 1)
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                .stroke(theme.gridColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))
            }
        }
    }
    
    // MARK: - Axis Labels
    
    private func xAxisLabels(width: CGFloat) -> some View {
        let labelCount = 5
        
        return HStack {
            ForEach(0..<labelCount, id: \.self) { i in
                let value = xRange.min + (xRange.max - xRange.min) * Double(i) / Double(labelCount - 1)
                Text(String(format: valueFormat, value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func yAxisLabels(height: CGFloat) -> some View {
        let labelCount = 5
        
        return VStack {
            ForEach(0..<labelCount, id: \.self) { i in
                let value = yRange.max - (yRange.max - yRange.min) * Double(i) / Double(labelCount - 1)
                Text(String(format: valueFormat, value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: height / CGFloat(labelCount - 1), alignment: i == 0 ? .top : (i == labelCount - 1 ? .bottom : .center))
            }
        }
        .frame(width: 50)
    }
    
    private func axisLabelsView(width: CGFloat, height: CGFloat, labelWidth: CGFloat) -> some View {
        ZStack {
            if let xLabel = xAxisLabel {
                Text(xLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .position(x: labelWidth + width / 2, y: height + 25)
            }
            
            if let yLabel = yAxisLabel {
                Text(yLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(-90))
                    .position(x: 10, y: height / 2)
            }
        }
    }
    
    // MARK: - Connecting Lines
    
    private func connectingLines(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let sortedData = data.sorted { $0.x < $1.x }
            
            for (index, point) in sortedData.enumerated() {
                let position = pointPosition(point, width: width, height: height)
                
                if index == 0 {
                    path.move(to: position)
                } else {
                    path.addLine(to: position)
                }
            }
        }
        .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
    }
    
    // MARK: - Bubble View
    
    @ViewBuilder
    private func bubbleView(point: XYDataPoint, chartWidth: CGFloat, chartHeight: CGFloat, labelOffset: CGFloat) -> some View {
        let position = pointPosition(point, width: chartWidth, height: chartHeight)
        let radius = bubbleRadius(for: point.size)
        let color = point.color ?? theme.color(at: data.firstIndex(where: { $0.id == point.id }) ?? 0)
        let isSelected = selectedPoint == point.id
        let isHovered = hoveredPoint == point.id
        
        ZStack {
            Circle()
                .fill(color.opacity(bubbleOpacity))
                .frame(width: radius * 2 * animationProgress, height: radius * 2 * animationProgress)
            
            Circle()
                .stroke(isSelected ? theme.accentColor : color, lineWidth: isSelected ? 3 : 1)
                .frame(width: radius * 2 * animationProgress, height: radius * 2 * animationProgress)
            
            if isHovered {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: radius * 2, height: radius * 2)
            }
            
            if showDataLabels, let label = point.label {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .position(x: position.x + labelOffset, y: position.y)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPoint = selectedPoint == point.id ? nil : point.id
            }
        }
        .onHover { hovering in
            hoveredPoint = hovering ? point.id : nil
        }
        .accessibilityElement()
        .accessibilityLabel("\(point.label ?? "Point"): X=\(String(format: valueFormat, point.x)), Y=\(String(format: valueFormat, point.y)), Size=\(String(format: valueFormat, point.size))")
    }
    
    private func pointPosition(_ point: XYDataPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        let xNormalized = (point.x - xRange.min) / (xRange.max - xRange.min)
        let yNormalized = (point.y - yRange.min) / (yRange.max - yRange.min)
        
        return CGPoint(
            x: xNormalized * width,
            y: (1 - yNormalized) * height
        )
    }
    
    private func bubbleRadius(for size: Double) -> CGFloat {
        let range = sizeRange.max - sizeRange.min
        guard range > 0 else { return (minRadius + maxRadius) / 2 }
        
        let normalized = (size - sizeRange.min) / range
        return minRadius + (maxRadius - minRadius) * CGFloat(normalized)
    }
    
    // MARK: - Tooltip
    
    @ViewBuilder
    private func tooltipView(for point: XYDataPoint, chartWidth: CGFloat, chartHeight: CGFloat, labelOffset: CGFloat) -> some View {
        let position = pointPosition(point, width: chartWidth, height: chartHeight)
        
        VStack(alignment: .leading, spacing: 4) {
            if let label = point.label {
                Text(label)
                    .font(.caption.bold())
            }
            
            Text("X: \(String(format: valueFormat, point.x))")
                .font(.caption2)
            Text("Y: \(String(format: valueFormat, point.y))")
                .font(.caption2)
            Text("Size: \(String(format: valueFormat, point.size))")
                .font(.caption2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
        )
        .foregroundColor(theme.foregroundColor)
        .position(x: position.x + labelOffset + 60, y: position.y - 40)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct BubbleChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            XYDataPoint(x: 10, y: 20, label: "A", size: 30, color: .blue),
            XYDataPoint(x: 25, y: 45, label: "B", size: 60, color: .green),
            XYDataPoint(x: 40, y: 30, label: "C", size: 45, color: .orange),
            XYDataPoint(x: 55, y: 60, label: "D", size: 80, color: .purple),
            XYDataPoint(x: 70, y: 40, label: "E", size: 50, color: .red),
            XYDataPoint(x: 85, y: 70, label: "F", size: 100, color: .cyan)
        ]
        
        BubbleChart(
            data: data,
            xAxisLabel: "Revenue ($K)",
            yAxisLabel: "Growth (%)"
        )
        .frame(height: 350)
        .padding()
    }
}
#endif
