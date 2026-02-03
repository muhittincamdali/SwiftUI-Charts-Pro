import SwiftUI

// MARK: - Radar Chart

/// A spider/radar chart for comparing multiple variables.
///
/// Radar charts are excellent for displaying multivariate data in a way
/// that makes it easy to see which variables have similar values.
///
/// ```swift
/// let data = [
///     RadarDataSeries(name: "Product A", values: [80, 90, 70, 60, 85]),
///     RadarDataSeries(name: "Product B", values: [70, 80, 90, 75, 65])
/// ]
///
/// RadarChart(
///     data: data,
///     labels: ["Speed", "Quality", "Price", "Support", "Features"]
/// )
/// ```
public struct RadarChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data series to display
    public let data: [RadarDataSeries]
    
    /// Labels for each axis
    public let labels: [String]
    
    /// Maximum value for scaling (auto-calculated if nil)
    public let maxValue: Double?
    
    /// Number of grid rings
    public let gridLevels: Int
    
    /// Whether to fill the radar area
    public let showFill: Bool
    
    /// Opacity of the fill
    public let fillOpacity: Double
    
    /// Whether to show data points
    public let showPoints: Bool
    
    /// Point radius
    public let pointRadius: CGFloat
    
    /// Line width for the radar
    public let lineWidth: CGFloat
    
    /// Whether to show grid lines
    public let showGrid: Bool
    
    /// Whether to show labels
    public let showLabels: Bool
    
    /// Whether to show values on hover
    public let showValues: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedSeries: String?
    @State private var selectedAxis: Int?
    
    /// Creates a radar chart.
    public init(
        data: [RadarDataSeries],
        labels: [String],
        maxValue: Double? = nil,
        gridLevels: Int = 5,
        showFill: Bool = true,
        fillOpacity: Double = 0.2,
        showPoints: Bool = true,
        pointRadius: CGFloat = 4,
        lineWidth: CGFloat = 2,
        showGrid: Bool = true,
        showLabels: Bool = true,
        showValues: Bool = true
    ) {
        self.data = data
        self.labels = labels
        self.maxValue = maxValue
        self.gridLevels = gridLevels
        self.showFill = showFill
        self.fillOpacity = fillOpacity
        self.showPoints = showPoints
        self.pointRadius = pointRadius
        self.lineWidth = lineWidth
        self.showGrid = showGrid
        self.showLabels = showLabels
        self.showValues = showValues
    }
    
    private var calculatedMaxValue: Double {
        if let max = maxValue { return max }
        return data.flatMap { $0.values }.max() ?? 100
    }
    
    private var axisCount: Int {
        labels.count
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
                
                ZStack {
                    // Grid
                    if showGrid {
                        radarGrid(center: center, radius: radius)
                    }
                    
                    // Axis lines and labels
                    ForEach(0..<axisCount, id: \.self) { index in
                        axisLine(index: index, center: center, radius: radius)
                    }
                    
                    // Data series
                    ForEach(data) { series in
                        radarPath(series: series, center: center, radius: radius)
                    }
                    
                    // Data points
                    if showPoints {
                        ForEach(data) { series in
                            dataPoints(series: series, center: center, radius: radius)
                        }
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
        .accessibilityLabel("Radar chart with \(data.count) series and \(axisCount) axes")
    }
    
    // MARK: - Grid
    
    private func radarGrid(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            // Concentric polygons
            ForEach(1...gridLevels, id: \.self) { level in
                let levelRadius = radius * CGFloat(level) / CGFloat(gridLevels)
                
                Path { path in
                    for i in 0..<axisCount {
                        let angle = angleForAxis(i) - .pi / 2
                        let point = CGPoint(
                            x: center.x + cos(angle) * levelRadius,
                            y: center.y + sin(angle) * levelRadius
                        )
                        
                        if i == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(theme.gridColor, lineWidth: 0.5)
            }
        }
    }
    
    // MARK: - Axis Lines
    
    private func axisLine(index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let angle = angleForAxis(index) - .pi / 2
        let endPoint = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        let labelPoint = CGPoint(
            x: center.x + cos(angle) * (radius + 20),
            y: center.y + sin(angle) * (radius + 20)
        )
        
        return ZStack {
            // Axis line
            Path { path in
                path.move(to: center)
                path.addLine(to: endPoint)
            }
            .stroke(theme.gridColor, lineWidth: 1)
            
            // Label
            if showLabels && index < labels.count {
                Text(labels[index])
                    .font(theme.font)
                    .foregroundColor(theme.foregroundColor)
                    .position(labelPoint)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Data Path
    
    private func radarPath(series: RadarDataSeries, center: CGPoint, radius: CGFloat) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        let isSelected = selectedSeries == series.name
        let opacity = selectedSeries == nil ? 1.0 : (isSelected ? 1.0 : 0.3)
        
        return ZStack {
            // Fill
            if showFill {
                Path { path in
                    let points = dataPointPositions(series: series, center: center, radius: radius)
                    guard let first = points.first else { return }
                    
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.closeSubpath()
                }
                .fill(color.opacity(fillOpacity * animationProgress * opacity))
            }
            
            // Stroke
            Path { path in
                let points = dataPointPositions(series: series, center: center, radius: radius)
                guard let first = points.first else { return }
                
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.closeSubpath()
            }
            .trim(from: 0, to: animationProgress)
            .stroke(color.opacity(opacity), lineWidth: isSelected ? lineWidth + 1 : lineWidth)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSeries = selectedSeries == series.name ? nil : series.name
            }
        }
    }
    
    // MARK: - Data Points
    
    private func dataPoints(series: RadarDataSeries, center: CGPoint, radius: CGFloat) -> some View {
        let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
        let points = dataPointPositions(series: series, center: center, radius: radius)
        let isSelected = selectedSeries == series.name
        let opacity = selectedSeries == nil ? 1.0 : (isSelected ? 1.0 : 0.3)
        
        return ForEach(Array(points.enumerated()), id: \.offset) { index, point in
            Circle()
                .fill(color)
                .frame(width: pointRadius * 2, height: pointRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
                .position(point)
                .opacity(animationProgress * opacity)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedAxis = selectedAxis == index ? nil : index
                    }
                }
        }
    }
    
    private func dataPointPositions(series: RadarDataSeries, center: CGPoint, radius: CGFloat) -> [CGPoint] {
        series.values.enumerated().map { index, value in
            let normalizedValue = value / calculatedMaxValue
            let angle = angleForAxis(index) - .pi / 2
            let distance = radius * CGFloat(normalizedValue) * animationProgress
            
            return CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
        }
    }
    
    private func angleForAxis(_ index: Int) -> CGFloat {
        CGFloat(index) * (2 * .pi) / CGFloat(axisCount)
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(data) { series in
                let color = series.color ?? theme.color(at: data.firstIndex(where: { $0.id == series.id }) ?? 0)
                let isSelected = selectedSeries == series.name
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                    
                    Text(series.name)
                        .font(.caption)
                        .foregroundColor(isSelected ? theme.accentColor : theme.foregroundColor)
                }
                .opacity(selectedSeries == nil ? 1.0 : (isSelected ? 1.0 : 0.5))
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSeries = selectedSeries == series.name ? nil : series.name
                    }
                }
            }
        }
    }
}

// MARK: - Radar Data Series

/// A data series for radar charts.
public struct RadarDataSeries: Identifiable {
    public let id: UUID
    
    /// The name of the series
    public let name: String
    
    /// The values for each axis
    public let values: [Double]
    
    /// Optional custom color
    public var color: Color?
    
    /// Creates a radar data series.
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

// MARK: - Preview Provider

#if DEBUG
struct RadarChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            RadarDataSeries(
                name: "Product A",
                values: [80, 90, 70, 60, 85, 75],
                color: .blue
            ),
            RadarDataSeries(
                name: "Product B",
                values: [70, 80, 90, 75, 65, 80],
                color: .green
            )
        ]
        
        RadarChart(
            data: data,
            labels: ["Speed", "Quality", "Price", "Support", "Features", "Design"]
        )
        .frame(height: 350)
        .padding()
    }
}
#endif
