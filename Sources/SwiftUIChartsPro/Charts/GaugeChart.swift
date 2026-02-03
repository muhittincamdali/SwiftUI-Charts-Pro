import SwiftUI

// MARK: - Gauge Chart

/// A meter/gauge chart for displaying a single value within a range.
///
/// Gauge charts are ideal for dashboards and KPIs, showing progress
/// or status within defined thresholds.
///
/// ```swift
/// GaugeChart(
///     value: 75,
///     maxValue: 100,
///     label: "Performance"
/// )
/// ```
public struct GaugeChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The current value
    public let value: Double
    
    /// Minimum value (default 0)
    public let minValue: Double
    
    /// Maximum value
    public let maxValue: Double
    
    /// Label displayed below the gauge
    public let label: String?
    
    /// The gauge style
    public let style: GaugeStyle
    
    /// Segments with colors for different ranges
    public let segments: [GaugeSegment]
    
    /// Whether to show the current value
    public let showValue: Bool
    
    /// Whether to show min/max labels
    public let showMinMax: Bool
    
    /// Whether to show segment labels
    public let showSegmentLabels: Bool
    
    /// Line width for the gauge arc
    public let lineWidth: CGFloat
    
    /// Start angle in degrees (0 = right, 90 = bottom)
    public let startAngle: Double
    
    /// End angle in degrees
    public let endAngle: Double
    
    /// Value format string
    public let valueFormat: String
    
    /// Unit suffix (e.g., "%", "°C")
    public let unit: String
    
    @State private var animationProgress: CGFloat = 0
    @State private var displayValue: Double = 0
    
    /// Creates a gauge chart.
    public init(
        value: Double,
        minValue: Double = 0,
        maxValue: Double = 100,
        label: String? = nil,
        style: GaugeStyle = .arc,
        segments: [GaugeSegment] = [],
        showValue: Bool = true,
        showMinMax: Bool = true,
        showSegmentLabels: Bool = false,
        lineWidth: CGFloat = 20,
        startAngle: Double = 135,
        endAngle: Double = 405,
        valueFormat: String = "%.0f",
        unit: String = ""
    ) {
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.label = label
        self.style = style
        self.segments = segments.isEmpty ? GaugeSegment.defaultSegments : segments
        self.showValue = showValue
        self.showMinMax = showMinMax
        self.showSegmentLabels = showSegmentLabels
        self.lineWidth = lineWidth
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.valueFormat = valueFormat
        self.unit = unit
    }
    
    private var normalizedValue: Double {
        let range = maxValue - minValue
        guard range > 0 else { return 0 }
        return (value - minValue) / range
    }
    
    private var currentSegmentColor: Color {
        let normalized = normalizedValue
        for segment in segments {
            if normalized >= segment.range.lowerBound && normalized <= segment.range.upperBound {
                return segment.color
            }
        }
        return theme.accentColor
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                switch style {
                case .arc:
                    arcGauge(size: size, center: center)
                case .speedometer:
                    speedometerGauge(size: size, center: center)
                case .linear:
                    linearGauge(width: geometry.size.width)
                case .circular:
                    circularGauge(size: size, center: center)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration * 1.5)) {
                animationProgress = 1
                displayValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                displayValue = newValue
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(label ?? "Gauge"): \(String(format: valueFormat, value))\(unit)")
        .accessibilityValue("\(Int(normalizedValue * 100))%")
    }
    
    // MARK: - Arc Gauge
    
    private func arcGauge(size: CGFloat, center: CGPoint) -> some View {
        let radius = (size - lineWidth) / 2
        
        return ZStack {
            // Background track
            arcPath(radius: radius)
                .stroke(theme.gridColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            
            // Segment colors
            ForEach(segments) { segment in
                arcPath(radius: radius)
                    .trim(from: segment.range.lowerBound, to: segment.range.upperBound)
                    .stroke(segment.color.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            
            // Value arc
            arcPath(radius: radius)
                .trim(from: 0, to: CGFloat(normalizedValue) * animationProgress)
                .stroke(currentSegmentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            
            // Center content
            VStack(spacing: 4) {
                if showValue {
                    Text("\(String(format: valueFormat, displayValue))\(unit)")
                        .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                        .foregroundColor(currentSegmentColor)
                }
                
                if let label = label {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .position(center)
            
            // Min/Max labels
            if showMinMax {
                minMaxLabels(radius: radius, center: center)
            }
        }
    }
    
    private func arcPath(radius: CGFloat) -> Path {
        Path { path in
            path.addArc(
                center: .zero,
                radius: radius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
        }
        .offsetBy(dx: radius + lineWidth / 2, dy: radius + lineWidth / 2)
    }
    
    // MARK: - Speedometer Gauge
    
    private func speedometerGauge(size: CGFloat, center: CGPoint) -> some View {
        let radius = (size - lineWidth * 2) / 2
        let needleLength = radius * 0.7
        let angleRange = endAngle - startAngle
        let currentAngle = startAngle + angleRange * normalizedValue * Double(animationProgress)
        
        return ZStack {
            // Background with segments
            ForEach(segments) { segment in
                arcPath(radius: radius)
                    .trim(from: segment.range.lowerBound, to: segment.range.upperBound)
                    .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            }
            
            // Tick marks
            ForEach(0...10, id: \.self) { i in
                let tickAngle = startAngle + angleRange * Double(i) / 10.0
                let tickRadians = tickAngle * .pi / 180
                let innerRadius = radius - lineWidth / 2 - 10
                let outerRadius = radius - lineWidth / 2
                
                Path { path in
                    let inner = CGPoint(
                        x: center.x + cos(tickRadians) * innerRadius,
                        y: center.y + sin(tickRadians) * innerRadius
                    )
                    let outer = CGPoint(
                        x: center.x + cos(tickRadians) * outerRadius,
                        y: center.y + sin(tickRadians) * outerRadius
                    )
                    path.move(to: inner)
                    path.addLine(to: outer)
                }
                .stroke(theme.foregroundColor, lineWidth: i % 5 == 0 ? 2 : 1)
            }
            
            // Needle
            Path { path in
                let radians = currentAngle * .pi / 180
                let tip = CGPoint(
                    x: center.x + cos(radians) * needleLength,
                    y: center.y + sin(radians) * needleLength
                )
                let baseOffset: CGFloat = 8
                let perpRadians = radians + .pi / 2
                let base1 = CGPoint(
                    x: center.x + cos(perpRadians) * baseOffset,
                    y: center.y + sin(perpRadians) * baseOffset
                )
                let base2 = CGPoint(
                    x: center.x - cos(perpRadians) * baseOffset,
                    y: center.y - sin(perpRadians) * baseOffset
                )
                
                path.move(to: tip)
                path.addLine(to: base1)
                path.addLine(to: base2)
                path.closeSubpath()
            }
            .fill(currentSegmentColor)
            
            // Center cap
            Circle()
                .fill(theme.foregroundColor)
                .frame(width: 16, height: 16)
                .position(center)
            
            // Value display
            VStack(spacing: 2) {
                Text("\(String(format: valueFormat, displayValue))\(unit)")
                    .font(.system(size: size * 0.1, weight: .bold, design: .rounded))
                    .foregroundColor(theme.foregroundColor)
                
                if let label = label {
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .position(x: center.x, y: center.y + radius * 0.4)
        }
    }
    
    // MARK: - Linear Gauge
    
    private func linearGauge(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Value
            if showValue {
                HStack {
                    if let label = label {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(String(format: valueFormat, displayValue))\(unit)")
                        .font(.system(.caption, design: .monospaced).weight(.medium))
                        .foregroundColor(currentSegmentColor)
                }
            }
            
            // Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: lineWidth / 2)
                        .fill(theme.gridColor)
                    
                    // Segments
                    HStack(spacing: 0) {
                        ForEach(segments) { segment in
                            let segmentWidth = geo.size.width * CGFloat(segment.range.upperBound - segment.range.lowerBound)
                            Rectangle()
                                .fill(segment.color.opacity(0.3))
                                .frame(width: segmentWidth)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: lineWidth / 2))
                    
                    // Value bar
                    RoundedRectangle(cornerRadius: lineWidth / 2)
                        .fill(currentSegmentColor)
                        .frame(width: geo.size.width * CGFloat(normalizedValue) * animationProgress)
                }
            }
            .frame(height: lineWidth)
            
            // Min/Max labels
            if showMinMax {
                HStack {
                    Text(String(format: valueFormat, minValue))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: valueFormat, maxValue))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Circular Gauge
    
    private func circularGauge(size: CGFloat, center: CGPoint) -> some View {
        let radius = (size - lineWidth) / 2
        
        return ZStack {
            // Background
            Circle()
                .stroke(theme.gridColor, lineWidth: lineWidth)
            
            // Segments
            ForEach(segments) { segment in
                Circle()
                    .trim(from: segment.range.lowerBound, to: segment.range.upperBound)
                    .stroke(segment.color.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            
            // Value
            Circle()
                .trim(from: 0, to: CGFloat(normalizedValue) * animationProgress)
                .stroke(currentSegmentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Center content
            VStack(spacing: 4) {
                if showValue {
                    Text("\(String(format: valueFormat, displayValue))\(unit)")
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(currentSegmentColor)
                }
                
                if let label = label {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Min/Max Labels
    
    private func minMaxLabels(radius: CGFloat, center: CGPoint) -> some View {
        let startRadians = startAngle * .pi / 180
        let endRadians = endAngle * .pi / 180
        let labelRadius = radius + lineWidth / 2 + 15
        
        let minPos = CGPoint(
            x: center.x + cos(startRadians) * labelRadius,
            y: center.y + sin(startRadians) * labelRadius
        )
        
        let maxPos = CGPoint(
            x: center.x + cos(endRadians) * labelRadius,
            y: center.y + sin(endRadians) * labelRadius
        )
        
        return ZStack {
            Text(String(format: valueFormat, minValue))
                .font(.caption2)
                .foregroundColor(.secondary)
                .position(minPos)
            
            Text(String(format: valueFormat, maxValue))
                .font(.caption2)
                .foregroundColor(.secondary)
                .position(maxPos)
        }
    }
}

// MARK: - Supporting Types

/// Gauge visual style
public enum GaugeStyle {
    /// Arc/semi-circle gauge
    case arc
    
    /// Speedometer with needle
    case speedometer
    
    /// Linear horizontal bar
    case linear
    
    /// Full circle gauge
    case circular
}

/// A segment in a gauge with a color and range
public struct GaugeSegment: Identifiable {
    public let id: UUID
    
    /// The range this segment covers (0-1)
    public let range: ClosedRange<Double>
    
    /// The color for this segment
    public let color: Color
    
    /// Optional label for the segment
    public var label: String?
    
    public init(
        id: UUID = UUID(),
        range: ClosedRange<Double>,
        color: Color,
        label: String? = nil
    ) {
        self.id = id
        self.range = range
        self.color = color
        self.label = label
    }
    
    /// Default traffic light segments
    public static let defaultSegments: [GaugeSegment] = [
        GaugeSegment(range: 0...0.33, color: .red, label: "Low"),
        GaugeSegment(range: 0.33...0.66, color: .yellow, label: "Medium"),
        GaugeSegment(range: 0.66...1.0, color: .green, label: "High")
    ]
    
    /// Performance segments
    public static let performanceSegments: [GaugeSegment] = [
        GaugeSegment(range: 0...0.25, color: .red, label: "Poor"),
        GaugeSegment(range: 0.25...0.5, color: .orange, label: "Fair"),
        GaugeSegment(range: 0.5...0.75, color: .yellow, label: "Good"),
        GaugeSegment(range: 0.75...1.0, color: .green, label: "Excellent")
    ]
}

// MARK: - Preview Provider

#if DEBUG
struct GaugeChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                GaugeChart(value: 72, label: "CPU", unit: "%")
                    .frame(width: 150, height: 150)
                
                GaugeChart(value: 45, label: "Memory", style: .circular, unit: "%")
                    .frame(width: 120, height: 120)
            }
            
            GaugeChart(value: 85, label: "Speed", style: .speedometer, unit: " km/h")
                .frame(width: 200, height: 150)
            
            GaugeChart(value: 65, maxValue: 100, label: "Progress", style: .linear, unit: "%")
                .frame(height: 60)
                .padding(.horizontal)
        }
        .padding()
    }
}
#endif
