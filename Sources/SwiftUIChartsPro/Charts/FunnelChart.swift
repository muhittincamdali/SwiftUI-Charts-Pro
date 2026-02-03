import SwiftUI

// MARK: - Funnel Chart

/// A funnel chart for visualizing sequential stages with decreasing values.
///
/// Funnel charts are ideal for showing conversion rates, sales pipelines,
/// or any process where values decrease through stages.
///
/// ```swift
/// let data = [
///     LabeledDataPoint(label: "Visitors", value: 10000),
///     LabeledDataPoint(label: "Leads", value: 5000),
///     LabeledDataPoint(label: "Prospects", value: 2000),
///     LabeledDataPoint(label: "Customers", value: 500)
/// ]
///
/// FunnelChart(data: data)
/// ```
public struct FunnelChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The data points for each funnel stage
    public let data: [LabeledDataPoint]
    
    /// Whether to show labels
    public let showLabels: Bool
    
    /// Whether to show values
    public let showValues: Bool
    
    /// Whether to show percentage conversion rates
    public let showPercentage: Bool
    
    /// The funnel orientation
    public let orientation: FunnelOrientation
    
    /// The funnel style
    public let style: FunnelStyle
    
    /// Spacing between stages
    public let spacing: CGFloat
    
    /// Corner radius for stages
    public let cornerRadius: CGFloat
    
    /// Format string for values
    public let valueFormat: String
    
    /// Minimum width ratio for the smallest stage
    public let minWidthRatio: CGFloat
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var hoveredIndex: Int?
    
    /// Creates a funnel chart.
    public init(
        data: [LabeledDataPoint],
        showLabels: Bool = true,
        showValues: Bool = true,
        showPercentage: Bool = true,
        orientation: FunnelOrientation = .vertical,
        style: FunnelStyle = .curved,
        spacing: CGFloat = 4,
        cornerRadius: CGFloat = 8,
        valueFormat: String = "%.0f",
        minWidthRatio: CGFloat = 0.2
    ) {
        self.data = data
        self.showLabels = showLabels
        self.showValues = showValues
        self.showPercentage = showPercentage
        self.orientation = orientation
        self.style = style
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.valueFormat = valueFormat
        self.minWidthRatio = minWidthRatio
    }
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
    
    public var body: some View {
        GeometryReader { geometry in
            switch orientation {
            case .vertical:
                verticalFunnel(size: geometry.size)
            case .horizontal:
                horizontalFunnel(size: geometry.size)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Funnel chart with \(data.count) stages")
    }
    
    // MARK: - Vertical Funnel
    
    private func verticalFunnel(size: CGSize) -> some View {
        let stageHeight = (size.height - CGFloat(data.count - 1) * spacing) / CGFloat(data.count)
        let labelWidth: CGFloat = showLabels ? 100 : 0
        let chartWidth = size.width - labelWidth * 2
        
        return ZStack(alignment: .top) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                let widthRatio = calculateWidthRatio(at: index)
                let nextWidthRatio = index < data.count - 1 ? calculateWidthRatio(at: index + 1) : widthRatio * 0.8
                let topWidth = chartWidth * CGFloat(widthRatio) * animationProgress
                let bottomWidth = chartWidth * CGFloat(nextWidthRatio) * animationProgress
                let yOffset = CGFloat(index) * (stageHeight + spacing)
                let isSelected = selectedIndex == index
                let isHovered = hoveredIndex == index
                
                funnelStage(
                    item: item,
                    index: index,
                    topWidth: topWidth,
                    bottomWidth: bottomWidth,
                    height: stageHeight,
                    centerX: size.width / 2,
                    yOffset: yOffset,
                    labelWidth: labelWidth,
                    isSelected: isSelected,
                    isHovered: isHovered
                )
            }
        }
    }
    
    @ViewBuilder
    private func funnelStage(
        item: LabeledDataPoint,
        index: Int,
        topWidth: CGFloat,
        bottomWidth: CGFloat,
        height: CGFloat,
        centerX: CGFloat,
        yOffset: CGFloat,
        labelWidth: CGFloat,
        isSelected: Bool,
        isHovered: Bool
    ) -> some View {
        let color = item.color ?? theme.color(at: index)
        let scale = isSelected ? 1.02 : (isHovered ? 1.01 : 1.0)
        
        ZStack {
            // Stage shape
            funnelStagePath(
                topWidth: topWidth,
                bottomWidth: bottomWidth,
                height: height,
                centerX: centerX
            )
            .fill(color)
            .opacity(animationProgress)
            
            // Border
            funnelStagePath(
                topWidth: topWidth,
                bottomWidth: bottomWidth,
                height: height,
                centerX: centerX
            )
            .stroke(isSelected ? theme.accentColor : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 0.5)
            
            // Labels and values
            HStack {
                // Left label
                if showLabels {
                    Text(item.label)
                        .font(theme.font)
                        .foregroundColor(theme.foregroundColor)
                        .frame(width: labelWidth, alignment: .trailing)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Center value
                VStack(spacing: 2) {
                    if showValues {
                        Text(formatValue(item.value))
                            .font(.system(.caption, design: .monospaced).weight(.medium))
                            .foregroundColor(.white)
                    }
                    
                    if showPercentage && index > 0 {
                        Text(conversionRate(from: 0, to: index))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Right percentage
                if showPercentage && index > 0 {
                    Text(conversionRate(from: index - 1, to: index))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: labelWidth, alignment: .leading)
                }
            }
            .frame(height: height)
        }
        .offset(y: yOffset)
        .scaleEffect(scale)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = selectedIndex == index ? nil : index
            }
        }
        .onHover { hovering in
            hoveredIndex = hovering ? index : nil
        }
        .accessibilityElement()
        .accessibilityLabel("\(item.label): \(formatValue(item.value))")
    }
    
    private func funnelStagePath(topWidth: CGFloat, bottomWidth: CGFloat, height: CGFloat, centerX: CGFloat) -> Path {
        Path { path in
            let topLeft = CGPoint(x: centerX - topWidth / 2, y: 0)
            let topRight = CGPoint(x: centerX + topWidth / 2, y: 0)
            let bottomRight = CGPoint(x: centerX + bottomWidth / 2, y: height)
            let bottomLeft = CGPoint(x: centerX - bottomWidth / 2, y: height)
            
            switch style {
            case .straight:
                path.move(to: topLeft)
                path.addLine(to: topRight)
                path.addLine(to: bottomRight)
                path.addLine(to: bottomLeft)
                path.closeSubpath()
                
            case .curved:
                let curveOffset = height * 0.2
                path.move(to: topLeft)
                path.addLine(to: topRight)
                path.addQuadCurve(to: bottomRight, control: CGPoint(x: centerX + (topWidth + bottomWidth) / 4, y: height / 2))
                path.addLine(to: bottomLeft)
                path.addQuadCurve(to: topLeft, control: CGPoint(x: centerX - (topWidth + bottomWidth) / 4, y: height / 2))
                
            case .stepped:
                let midHeight = height / 2
                path.move(to: topLeft)
                path.addLine(to: topRight)
                path.addLine(to: CGPoint(x: centerX + topWidth / 2, y: midHeight))
                path.addLine(to: CGPoint(x: centerX + bottomWidth / 2, y: midHeight))
                path.addLine(to: bottomRight)
                path.addLine(to: bottomLeft)
                path.addLine(to: CGPoint(x: centerX - bottomWidth / 2, y: midHeight))
                path.addLine(to: CGPoint(x: centerX - topWidth / 2, y: midHeight))
                path.closeSubpath()
            }
        }
    }
    
    // MARK: - Horizontal Funnel
    
    private func horizontalFunnel(size: CGSize) -> some View {
        let stageWidth = (size.width - CGFloat(data.count - 1) * spacing) / CGFloat(data.count)
        let labelHeight: CGFloat = showLabels ? 30 : 0
        let chartHeight = size.height - labelHeight * 2
        
        return ZStack(alignment: .leading) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                let heightRatio = calculateWidthRatio(at: index)
                let nextHeightRatio = index < data.count - 1 ? calculateWidthRatio(at: index + 1) : heightRatio * 0.8
                let leftHeight = chartHeight * CGFloat(heightRatio) * animationProgress
                let rightHeight = chartHeight * CGFloat(nextHeightRatio) * animationProgress
                let xOffset = CGFloat(index) * (stageWidth + spacing)
                let isSelected = selectedIndex == index
                let color = item.color ?? theme.color(at: index)
                
                horizontalStage(
                    item: item,
                    index: index,
                    leftHeight: leftHeight,
                    rightHeight: rightHeight,
                    width: stageWidth,
                    centerY: size.height / 2,
                    xOffset: xOffset,
                    isSelected: isSelected,
                    color: color
                )
            }
        }
    }
    
    @ViewBuilder
    private func horizontalStage(
        item: LabeledDataPoint,
        index: Int,
        leftHeight: CGFloat,
        rightHeight: CGFloat,
        width: CGFloat,
        centerY: CGFloat,
        xOffset: CGFloat,
        isSelected: Bool,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            if showLabels {
                Text(item.label)
                    .font(.caption)
                    .foregroundColor(theme.foregroundColor)
                    .lineLimit(1)
            }
            
            Path { path in
                let topLeft = CGPoint(x: 0, y: centerY - leftHeight / 2)
                let topRight = CGPoint(x: width, y: centerY - rightHeight / 2)
                let bottomRight = CGPoint(x: width, y: centerY + rightHeight / 2)
                let bottomLeft = CGPoint(x: 0, y: centerY + leftHeight / 2)
                
                path.move(to: topLeft)
                path.addLine(to: topRight)
                path.addLine(to: bottomRight)
                path.addLine(to: bottomLeft)
                path.closeSubpath()
            }
            .fill(color)
            .opacity(animationProgress)
            .overlay(
                VStack(spacing: 2) {
                    if showValues {
                        Text(formatValue(item.value))
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white)
                    }
                }
            )
            
            if showPercentage && index > 0 {
                Text(conversionRate(from: index - 1, to: index))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .offset(x: xOffset)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = selectedIndex == index ? nil : index
            }
        }
    }
    
    // MARK: - Helpers
    
    private func calculateWidthRatio(at index: Int) -> Double {
        guard maxValue > 0 else { return minWidthRatio }
        let ratio = data[index].value / maxValue
        return max(minWidthRatio, ratio)
    }
    
    private func conversionRate(from fromIndex: Int, to toIndex: Int) -> String {
        guard fromIndex >= 0, fromIndex < data.count,
              toIndex >= 0, toIndex < data.count,
              data[fromIndex].value > 0 else { return "0%" }
        
        let rate = (data[toIndex].value / data[fromIndex].value) * 100
        return String(format: "%.1f%%", rate)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: valueFormat, value)
        }
    }
}

// MARK: - Supporting Types

/// Funnel chart orientation
public enum FunnelOrientation {
    /// Vertical funnel (top to bottom)
    case vertical
    
    /// Horizontal funnel (left to right)
    case horizontal
}

/// Funnel stage style
public enum FunnelStyle {
    /// Straight edges
    case straight
    
    /// Curved edges
    case curved
    
    /// Stepped edges
    case stepped
}

// MARK: - Preview Provider

#if DEBUG
struct FunnelChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            LabeledDataPoint(label: "Visitors", value: 10000, color: .blue),
            LabeledDataPoint(label: "Leads", value: 5000, color: .cyan),
            LabeledDataPoint(label: "Prospects", value: 2000, color: .green),
            LabeledDataPoint(label: "Opportunities", value: 800, color: .yellow),
            LabeledDataPoint(label: "Customers", value: 500, color: .orange)
        ]
        
        VStack(spacing: 20) {
            FunnelChart(data: data, style: .curved)
                .frame(height: 300)
            
            FunnelChart(data: data, orientation: .horizontal, style: .straight)
                .frame(height: 200)
        }
        .padding()
    }
}
#endif
