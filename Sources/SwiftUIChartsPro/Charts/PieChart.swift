import SwiftUI

// MARK: - Pie Chart

/// A high-performance pie and donut chart with smooth animations and interactive selection.
///
/// Pie charts are ideal for showing proportional data. This implementation supports
/// both solid pie and donut styles with customizable hole radius.
///
/// ```swift
/// let data = [
///     PieSlice(label: "iOS", value: 60, color: .blue),
///     PieSlice(label: "Android", value: 30, color: .green),
///     PieSlice(label: "Other", value: 10, color: .gray)
/// ]
///
/// PieChart(data: data)
///     .pieStyle(.donut(holeRadius: 0.5))
///     .showLabels(true)
/// ```
public struct PieChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data slices to display
    public let data: [PieSlice]
    
    /// The pie style (solid or donut)
    public var pieStyle: PieStyle
    
    /// Whether to show labels
    public var showLabels: Bool
    
    /// Label style
    public var labelStyle: PieLabelStyle
    
    /// Whether to show percentage values
    public var showPercentages: Bool
    
    /// Minimum slice angle to display label (in degrees)
    public var minLabelAngle: Double
    
    /// Explode offset for selected slice
    public var explodeOffset: CGFloat
    
    /// Start angle in degrees (0 = 3 o'clock, 90 = 6 o'clock)
    public var startAngle: Double
    
    /// Whether slices go clockwise
    public var clockwise: Bool
    
    /// Shadow radius for 3D effect
    public var shadowRadius: CGFloat
    
    /// Whether to enable interaction
    public var enableInteraction: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var showTooltip: Bool = false
    @State private var tooltipPosition: CGPoint = .zero
    
    /// Creates a pie chart.
    public init(
        data: [PieSlice],
        pieStyle: PieStyle = .pie,
        showLabels: Bool = true,
        labelStyle: PieLabelStyle = .outside,
        showPercentages: Bool = true,
        minLabelAngle: Double = 15,
        explodeOffset: CGFloat = 12,
        startAngle: Double = -90,
        clockwise: Bool = true,
        shadowRadius: CGFloat = 4,
        enableInteraction: Bool = true
    ) {
        self.data = data
        self.pieStyle = pieStyle
        self.showLabels = showLabels
        self.labelStyle = labelStyle
        self.showPercentages = showPercentages
        self.minLabelAngle = minLabelAngle
        self.explodeOffset = explodeOffset
        self.startAngle = startAngle
        self.clockwise = clockwise
        self.shadowRadius = shadowRadius
        self.enableInteraction = enableInteraction
    }
    
    private var total: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private var sliceAngles: [(start: Double, end: Double)] {
        var angles: [(start: Double, end: Double)] = []
        var currentAngle = startAngle
        
        for slice in data {
            let sliceAngle = (slice.value / total) * 360 * (clockwise ? 1 : -1)
            let endAngle = currentAngle + sliceAngle * Double(animationProgress)
            angles.append((start: currentAngle, end: endAngle))
            currentAngle = currentAngle + sliceAngle
        }
        
        return angles
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - (showLabels && labelStyle == .outside ? 50 : 20)
                
                ZStack {
                    // Pie slices
                    ForEach(Array(data.enumerated()), id: \.offset) { index, slice in
                        sliceView(
                            slice: slice,
                            index: index,
                            center: center,
                            radius: radius
                        )
                    }
                    
                    // Donut hole
                    if case .donut(let holeRadius) = pieStyle {
                        Circle()
                            .fill(theme.backgroundColor)
                            .frame(
                                width: radius * 2 * holeRadius,
                                height: radius * 2 * holeRadius
                            )
                            .position(center)
                        
                        // Center label for donut
                        if let selected = selectedIndex, selected < data.count {
                            centerLabel(slice: data[selected], center: center)
                        } else {
                            totalLabel(center: center)
                        }
                    }
                    
                    // Labels
                    if showLabels {
                        labelsView(center: center, radius: radius)
                    }
                    
                    // Tooltip
                    if showTooltip, let index = selectedIndex, index < data.count {
                        tooltipView(slice: data[index])
                            .position(tooltipPosition)
                    }
                }
            }
            
            // Legend
            if configuration.showLegend {
                legendView
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pie chart with \(data.count) slices")
    }
    
    // MARK: - Slice View
    
    private func sliceView(slice: PieSlice, index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let angles = sliceAngles[index]
        let isSelected = selectedIndex == index
        let color = slice.color ?? theme.color(at: index)
        
        // Calculate explode offset
        let midAngle = (angles.start + angles.end) / 2
        let explodeX = isSelected ? cos(midAngle * .pi / 180) * explodeOffset : 0
        let explodeY = isSelected ? sin(midAngle * .pi / 180) * explodeOffset : 0
        
        let holeRadius: CGFloat = {
            if case .donut(let r) = pieStyle {
                return radius * r
            }
            return 0
        }()
        
        return PieSliceShape(
            startAngle: Angle(degrees: angles.start),
            endAngle: Angle(degrees: angles.end),
            innerRadius: holeRadius
        )
        .fill(
            LinearGradient(
                colors: [color, color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            PieSliceShape(
                startAngle: Angle(degrees: angles.start),
                endAngle: Angle(degrees: angles.end),
                innerRadius: holeRadius
            )
            .stroke(theme.backgroundColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: isSelected ? shadowRadius * 2 : shadowRadius, x: 0, y: 2)
        .frame(width: radius * 2, height: radius * 2)
        .position(CGPoint(x: center.x + explodeX, y: center.y + explodeY))
        .opacity(selectedIndex == nil ? 1.0 : (isSelected ? 1.0 : 0.6))
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            handleSliceTap(index: index, center: center, radius: radius)
        }
    }
    
    // MARK: - Labels View
    
    private func labelsView(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(Array(data.enumerated()), id: \.offset) { index, slice in
            let angles = sliceAngles[index]
            let midAngle = (angles.start + angles.end) / 2
            let sliceAngle = abs(angles.end - angles.start)
            
            if sliceAngle >= minLabelAngle {
                let labelRadius: CGFloat = {
                    switch labelStyle {
                    case .inside:
                        if case .donut(let holeRadius) = pieStyle {
                            return radius * (1 + holeRadius) / 2
                        }
                        return radius * 0.65
                    case .outside:
                        return radius + 25
                    }
                }()
                
                let labelX = center.x + cos(midAngle * .pi / 180) * labelRadius
                let labelY = center.y + sin(midAngle * .pi / 180) * labelRadius
                
                VStack(spacing: 1) {
                    Text(slice.label)
                        .font(.system(size: labelStyle == .inside ? 10 : 11, weight: .medium))
                        .foregroundColor(labelStyle == .inside ? .white : theme.foregroundColor)
                    
                    if showPercentages {
                        let percentage = (slice.value / total) * 100
                        Text(String(format: "%.1f%%", percentage))
                            .font(.system(size: labelStyle == .inside ? 9 : 10))
                            .foregroundColor(labelStyle == .inside ? .white.opacity(0.8) : theme.foregroundColor.opacity(0.7))
                    }
                }
                .position(x: labelX, y: labelY)
                .opacity(animationProgress)
            }
        }
    }
    
    // MARK: - Center Label (Donut)
    
    private func centerLabel(slice: PieSlice, center: CGPoint) -> some View {
        VStack(spacing: 2) {
            Text(slice.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.foregroundColor)
            
            Text(formatValue(slice.value))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(slice.color ?? theme.accentColor)
            
            let percentage = (slice.value / total) * 100
            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 12))
                .foregroundColor(theme.foregroundColor.opacity(0.7))
        }
        .position(center)
    }
    
    private func totalLabel(center: CGPoint) -> some View {
        VStack(spacing: 2) {
            Text("Total")
                .font(.system(size: 12))
                .foregroundColor(theme.foregroundColor.opacity(0.7))
            
            Text(formatValue(total))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.foregroundColor)
        }
        .position(center)
    }
    
    // MARK: - Tooltip
    
    private func tooltipView(slice: PieSlice) -> some View {
        let percentage = (slice.value / total) * 100
        let color = slice.color ?? theme.color(at: data.firstIndex(where: { $0.id == slice.id }) ?? 0)
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                
                Text(slice.label)
                    .font(.caption.bold())
                    .foregroundColor(theme.foregroundColor)
            }
            
            Text("\(formatValue(slice.value)) (\(String(format: "%.1f%%", percentage)))")
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
    
    // MARK: - Legend
    
    private var legendView: some View {
        let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, slice in
                let color = slice.color ?? theme.color(at: index)
                let isSelected = selectedIndex == index
                let percentage = (slice.value / total) * 100
                
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(slice.label)
                            .font(.caption)
                            .foregroundColor(theme.foregroundColor)
                            .lineLimit(1)
                        
                        Text(String(format: "%.1f%%", percentage))
                            .font(.system(size: 9))
                            .foregroundColor(theme.foregroundColor.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? color.opacity(0.15) : Color.clear)
                )
                .opacity(selectedIndex == nil ? 1.0 : (isSelected ? 1.0 : 0.5))
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = selectedIndex == index ? nil : index
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleSliceTap(index: Int, center: CGPoint, radius: CGFloat) {
        guard enableInteraction else { return }
        
        let angles = sliceAngles[index]
        let midAngle = (angles.start + angles.end) / 2
        let tooltipRadius = radius + 50
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedIndex == index {
                selectedIndex = nil
                showTooltip = false
            } else {
                selectedIndex = index
                tooltipPosition = CGPoint(
                    x: center.x + cos(midAngle * .pi / 180) * tooltipRadius,
                    y: center.y + sin(midAngle * .pi / 180) * tooltipRadius
                )
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

// MARK: - Pie Style

/// The style of pie chart.
public enum PieStyle: Equatable {
    /// Solid pie chart
    case pie
    /// Donut chart with specified hole radius (0-1)
    case donut(holeRadius: CGFloat)
    
    public static func == (lhs: PieStyle, rhs: PieStyle) -> Bool {
        switch (lhs, rhs) {
        case (.pie, .pie):
            return true
        case (.donut(let l), .donut(let r)):
            return l == r
        default:
            return false
        }
    }
}

/// Label position style for pie charts.
public enum PieLabelStyle {
    /// Labels inside the slices
    case inside
    /// Labels outside the slices
    case outside
}

// MARK: - Pie Slice

/// A slice of pie chart data.
public struct PieSlice: Identifiable {
    public let id: UUID
    
    /// The label for this slice
    public let label: String
    
    /// The value
    public let value: Double
    
    /// Optional custom color
    public var color: Color?
    
    /// Creates a pie slice.
    public init(
        id: UUID = UUID(),
        label: String,
        value: Double,
        color: Color? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Pie Slice Shape

/// A shape representing a single pie slice.
struct PieSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = Angle(degrees: newValue.first)
            endAngle = Angle(degrees: newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        
        if innerRadius > 0 {
            // Donut slice
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: endAngle,
                endAngle: startAngle,
                clockwise: true
            )
            path.closeSubpath()
        } else {
            // Pie slice
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - View Extension

public extension PieChart {
    /// Sets the pie chart style (pie or donut).
    func pieStyle(_ style: PieStyle) -> PieChart {
        var copy = self
        copy.pieStyle = style
        return copy
    }
    
    /// Shows or hides labels.
    func showLabels(_ show: Bool, style: PieLabelStyle = .outside) -> PieChart {
        var copy = self
        copy.showLabels = show
        copy.labelStyle = style
        return copy
    }
    
    /// Shows or hides percentage values.
    func showPercentages(_ show: Bool) -> PieChart {
        var copy = self
        copy.showPercentages = show
        return copy
    }
    
    /// Sets the start angle in degrees.
    func startAngle(_ degrees: Double) -> PieChart {
        var copy = self
        copy.startAngle = degrees
        return copy
    }
}

// MARK: - Preview Provider

#if DEBUG
struct PieChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            PieSlice(label: "iOS", value: 60, color: .blue),
            PieSlice(label: "Android", value: 30, color: .green),
            PieSlice(label: "Web", value: 15, color: .orange),
            PieSlice(label: "Desktop", value: 10, color: .purple),
            PieSlice(label: "Other", value: 5, color: .gray)
        ]
        
        VStack(spacing: 20) {
            PieChart(data: data)
                .pieStyle(.pie)
                .frame(height: 300)
            
            PieChart(data: data)
                .pieStyle(.donut(holeRadius: 0.5))
                .frame(height: 300)
        }
        .padding()
    }
}
#endif
