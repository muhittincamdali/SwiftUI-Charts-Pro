import SwiftUI

// MARK: - Parallel Coordinates Chart

/// A chart for visualizing high-dimensional data across multiple axes.
///
/// Parallel coordinates plots display each data point as a line connecting
/// values across multiple vertical axes, useful for spotting patterns in
/// multivariate data.
///
/// ```swift
/// let data = [
///     ParallelDataPoint(values: ["Speed": 80, "Power": 90, "Efficiency": 70]),
///     ParallelDataPoint(values: ["Speed": 60, "Power": 85, "Efficiency": 85])
/// ]
///
/// ParallelCoordinatesChart(data: data, axes: ["Speed", "Power", "Efficiency"])
/// ```
public struct ParallelCoordinatesChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data points to display
    public let data: [ParallelDataPoint]
    
    /// The axis names in order
    public let axes: [String]
    
    /// The value ranges for each axis (auto-calculated if nil)
    public let axisRanges: [String: ClosedRange<Double>]?
    
    /// Line width for data lines
    public let lineWidth: CGFloat
    
    /// Line opacity
    public let lineOpacity: Double
    
    /// Whether to show axis labels
    public let showAxisLabels: Bool
    
    /// Whether to show axis values
    public let showAxisValues: Bool
    
    /// Whether to show data points
    public let showPoints: Bool
    
    /// Point radius
    public let pointRadius: CGFloat
    
    /// Whether to enable brushing (selection)
    public let enableBrushing: Bool
    
    /// Value format string
    public let valueFormat: String
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedPoints: Set<UUID> = []
    @State private var hoveredPoint: UUID?
    @State private var brushRanges: [String: ClosedRange<CGFloat>] = [:]
    
    /// Creates a parallel coordinates chart.
    public init(
        data: [ParallelDataPoint],
        axes: [String],
        axisRanges: [String: ClosedRange<Double>]? = nil,
        lineWidth: CGFloat = 1.5,
        lineOpacity: Double = 0.6,
        showAxisLabels: Bool = true,
        showAxisValues: Bool = true,
        showPoints: Bool = true,
        pointRadius: CGFloat = 4,
        enableBrushing: Bool = true,
        valueFormat: String = "%.1f"
    ) {
        self.data = data
        self.axes = axes
        self.axisRanges = axisRanges
        self.lineWidth = lineWidth
        self.lineOpacity = lineOpacity
        self.showAxisLabels = showAxisLabels
        self.showAxisValues = showAxisValues
        self.showPoints = showPoints
        self.pointRadius = pointRadius
        self.enableBrushing = enableBrushing
        self.valueFormat = valueFormat
    }
    
    private func rangeFor(axis: String) -> ClosedRange<Double> {
        if let ranges = axisRanges, let range = ranges[axis] {
            return range
        }
        
        let values = data.compactMap { $0.values[axis] }
        let min = values.min() ?? 0
        let max = values.max() ?? 100
        let padding = (max - min) * 0.1
        
        return (min - padding)...(max + padding)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let labelHeight: CGFloat = showAxisLabels ? 30 : 0
            let valueHeight: CGFloat = showAxisValues ? 20 : 0
            let chartHeight = geometry.size.height - labelHeight - valueHeight * 2
            let axisSpacing = geometry.size.width / CGFloat(axes.count + 1)
            
            ZStack(alignment: .top) {
                // Axis lines
                ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                    let x = axisSpacing * CGFloat(index + 1)
                    
                    axisView(axis: axis, x: x, height: chartHeight, valueHeight: valueHeight)
                }
                
                // Data lines
                ForEach(data) { point in
                    dataLine(
                        point: point,
                        chartHeight: chartHeight,
                        axisSpacing: axisSpacing,
                        valueHeight: valueHeight
                    )
                }
                
                // Data points
                if showPoints {
                    ForEach(data) { point in
                        dataPoints(
                            point: point,
                            chartHeight: chartHeight,
                            axisSpacing: axisSpacing,
                            valueHeight: valueHeight
                        )
                    }
                }
                
                // Brush overlays
                if enableBrushing {
                    ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                        let x = axisSpacing * CGFloat(index + 1)
                        brushOverlay(axis: axis, x: x, height: chartHeight, offset: valueHeight)
                    }
                }
            }
            .offset(y: valueHeight)
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Parallel coordinates chart with \(data.count) data points and \(axes.count) axes")
    }
    
    // MARK: - Axis View
    
    @ViewBuilder
    private func axisView(axis: String, x: CGFloat, height: CGFloat, valueHeight: CGFloat) -> some View {
        let range = rangeFor(axis: axis)
        
        ZStack {
            // Axis line
            Path { path in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
            .stroke(theme.foregroundColor.opacity(0.5), lineWidth: 1)
            
            // Axis label
            if showAxisLabels {
                Text(axis)
                    .font(.caption)
                    .foregroundColor(theme.foregroundColor)
                    .position(x: x, y: height + 15)
            }
            
            // Value labels
            if showAxisValues {
                Text(String(format: valueFormat, range.upperBound))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(x: x, y: -10)
                
                Text(String(format: valueFormat, range.lowerBound))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(x: x, y: height + valueHeight + 25)
            }
        }
    }
    
    // MARK: - Data Line
    
    @ViewBuilder
    private func dataLine(point: ParallelDataPoint, chartHeight: CGFloat, axisSpacing: CGFloat, valueHeight: CGFloat) -> some View {
        let color = point.color ?? theme.color(at: data.firstIndex(where: { $0.id == point.id }) ?? 0)
        let isSelected = selectedPoints.isEmpty || selectedPoints.contains(point.id)
        let isHovered = hoveredPoint == point.id
        let isBrushed = isPointInBrush(point)
        
        let opacity = calculateLineOpacity(isSelected: isSelected, isHovered: isHovered, isBrushed: isBrushed)
        
        Path { path in
            var firstPoint = true
            
            for (index, axis) in axes.enumerated() {
                guard let value = point.values[axis] else { continue }
                
                let x = axisSpacing * CGFloat(index + 1)
                let range = rangeFor(axis: axis)
                let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                let y = chartHeight - CGFloat(normalized) * chartHeight
                
                if firstPoint {
                    path.move(to: CGPoint(x: x, y: y))
                    firstPoint = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .trim(from: 0, to: animationProgress)
        .stroke(
            color.opacity(opacity),
            style: StrokeStyle(lineWidth: isHovered ? lineWidth + 1 : lineWidth, lineCap: .round, lineJoin: .round)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedPoints.contains(point.id) {
                    selectedPoints.remove(point.id)
                } else {
                    selectedPoints.insert(point.id)
                }
            }
        }
        .onHover { hovering in
            hoveredPoint = hovering ? point.id : nil
        }
    }
    
    private func calculateLineOpacity(isSelected: Bool, isHovered: Bool, isBrushed: Bool) -> Double {
        if isHovered {
            return 1.0
        }
        
        if !brushRanges.isEmpty && !isBrushed {
            return 0.1
        }
        
        if !selectedPoints.isEmpty && !isSelected {
            return 0.1
        }
        
        return lineOpacity
    }
    
    private func isPointInBrush(_ point: ParallelDataPoint) -> Bool {
        guard !brushRanges.isEmpty else { return true }
        
        for (axis, range) in brushRanges {
            guard let value = point.values[axis] else { return false }
            
            let axisRange = rangeFor(axis: axis)
            let normalized = CGFloat((value - axisRange.lowerBound) / (axisRange.upperBound - axisRange.lowerBound))
            
            if normalized < range.lowerBound || normalized > range.upperBound {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Data Points
    
    @ViewBuilder
    private func dataPoints(point: ParallelDataPoint, chartHeight: CGFloat, axisSpacing: CGFloat, valueHeight: CGFloat) -> some View {
        let color = point.color ?? theme.color(at: data.firstIndex(where: { $0.id == point.id }) ?? 0)
        let isSelected = selectedPoints.isEmpty || selectedPoints.contains(point.id)
        let isHovered = hoveredPoint == point.id
        
        ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
            if let value = point.values[axis] {
                let x = axisSpacing * CGFloat(index + 1)
                let range = rangeFor(axis: axis)
                let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                let y = chartHeight - CGFloat(normalized) * chartHeight
                
                Circle()
                    .fill(color)
                    .frame(width: pointRadius * 2, height: pointRadius * 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .position(x: x, y: y)
                    .opacity((isSelected ? 1.0 : 0.3) * animationProgress)
                    .scaleEffect(isHovered ? 1.3 : 1.0)
            }
        }
    }
    
    // MARK: - Brush Overlay
    
    @ViewBuilder
    private func brushOverlay(axis: String, x: CGFloat, height: CGFloat, offset: CGFloat) -> some View {
        let brushWidth: CGFloat = 20
        
        ZStack {
            // Brush selection area
            if let range = brushRanges[axis] {
                Rectangle()
                    .fill(theme.accentColor.opacity(0.3))
                    .frame(width: brushWidth, height: (range.upperBound - range.lowerBound) * height)
                    .position(x: x, y: height - (range.lowerBound + range.upperBound) / 2 * height)
            }
            
            // Brush interaction area
            Rectangle()
                .fill(Color.clear)
                .frame(width: brushWidth, height: height)
                .position(x: x, y: height / 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let normalizedY = 1 - value.location.y / height
                            let clampedY = max(0, min(1, normalizedY))
                            
                            let startY = 1 - value.startLocation.y / height
                            let clampedStartY = max(0, min(1, startY))
                            
                            let lower = min(clampedY, clampedStartY)
                            let upper = max(clampedY, clampedStartY)
                            
                            brushRanges[axis] = lower...upper
                        }
                        .onEnded { _ in
                            // Keep brush or clear if too small
                            if let range = brushRanges[axis], range.upperBound - range.lowerBound < 0.05 {
                                brushRanges.removeValue(forKey: axis)
                            }
                        }
                )
        }
    }
}

// MARK: - Supporting Types

/// A data point for parallel coordinates
public struct ParallelDataPoint: Identifiable {
    public let id: UUID
    
    /// The label for this data point
    public var label: String?
    
    /// Values for each axis
    public let values: [String: Double]
    
    /// Optional custom color
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        label: String? = nil,
        values: [String: Double],
        color: Color? = nil
    ) {
        self.id = id
        self.label = label
        self.values = values
        self.color = color
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ParallelCoordinatesChart_Previews: PreviewProvider {
    static var previews: some View {
        let axes = ["Speed", "Power", "Efficiency", "Cost", "Quality"]
        
        let data = (0..<10).map { i -> ParallelDataPoint in
            ParallelDataPoint(
                label: "Item \(i + 1)",
                values: [
                    "Speed": Double.random(in: 40...100),
                    "Power": Double.random(in: 50...95),
                    "Efficiency": Double.random(in: 60...90),
                    "Cost": Double.random(in: 20...80),
                    "Quality": Double.random(in: 70...100)
                ]
            )
        }
        
        ParallelCoordinatesChart(data: data, axes: axes)
            .frame(height: 350)
            .padding()
    }
}
#endif
