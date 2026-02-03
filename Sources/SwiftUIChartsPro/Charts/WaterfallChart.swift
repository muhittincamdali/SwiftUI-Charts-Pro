import SwiftUI

// MARK: - Waterfall Chart

/// A chart showing cumulative effects of sequential positive/negative values.
///
/// Waterfall charts are ideal for financial analysis, showing how an initial
/// value is affected by a series of positive and negative changes.
///
/// ```swift
/// let data = [
///     WaterfallItem(label: "Start", value: 100, type: .total),
///     WaterfallItem(label: "Revenue", value: 50, type: .positive),
///     WaterfallItem(label: "Costs", value: -30, type: .negative),
///     WaterfallItem(label: "End", value: 0, type: .total)
/// ]
///
/// WaterfallChart(data: data)
/// ```
public struct WaterfallChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The waterfall data items
    public let data: [WaterfallItem]
    
    /// Color for positive values
    public let positiveColor: Color
    
    /// Color for negative values
    public let negativeColor: Color
    
    /// Color for total/subtotal values
    public let totalColor: Color
    
    /// Whether to show connector lines
    public let showConnectors: Bool
    
    /// Whether to show values on bars
    public let showValues: Bool
    
    /// Whether to show the value change (delta)
    public let showDelta: Bool
    
    /// Bar corner radius
    public let cornerRadius: CGFloat
    
    /// Spacing between bars
    public let barSpacing: CGFloat
    
    /// Value format string
    public let valueFormat: String
    
    /// Whether bars are horizontal
    public let isHorizontal: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var hoveredIndex: Int?
    
    /// Creates a waterfall chart.
    public init(
        data: [WaterfallItem],
        positiveColor: Color = .green,
        negativeColor: Color = .red,
        totalColor: Color = .blue,
        showConnectors: Bool = true,
        showValues: Bool = true,
        showDelta: Bool = true,
        cornerRadius: CGFloat = 4,
        barSpacing: CGFloat = 8,
        valueFormat: String = "%.0f",
        isHorizontal: Bool = false
    ) {
        self.data = data
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self.totalColor = totalColor
        self.showConnectors = showConnectors
        self.showValues = showValues
        self.showDelta = showDelta
        self.cornerRadius = cornerRadius
        self.barSpacing = barSpacing
        self.valueFormat = valueFormat
        self.isHorizontal = isHorizontal
    }
    
    private var runningTotals: [Double] {
        var totals: [Double] = []
        var running: Double = 0
        
        for item in data {
            switch item.type {
            case .total:
                totals.append(item.value != 0 ? item.value : running)
                running = item.value != 0 ? item.value : running
            case .positive, .negative:
                running += item.value
                totals.append(running)
            case .subtotal:
                totals.append(running)
            }
        }
        
        return totals
    }
    
    private var valueRange: (min: Double, max: Double) {
        var running: Double = 0
        var allValues: [Double] = [0]
        
        for item in data {
            let prev = running
            switch item.type {
            case .total:
                running = item.value != 0 ? item.value : running
            case .positive, .negative:
                running += item.value
            case .subtotal:
                break
            }
            allValues.append(running)
            allValues.append(prev)
        }
        
        let min = allValues.min() ?? 0
        let max = allValues.max() ?? 100
        let padding = (max - min) * 0.1
        
        return (min - padding, max + padding)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if isHorizontal {
                horizontalWaterfall(size: geometry.size)
            } else {
                verticalWaterfall(size: geometry.size)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Waterfall chart with \(data.count) items")
    }
    
    // MARK: - Vertical Waterfall
    
    private func verticalWaterfall(size: CGSize) -> some View {
        let labelHeight: CGFloat = 30
        let chartHeight = size.height - labelHeight - 20
        let barWidth = (size.width - CGFloat(data.count + 1) * barSpacing) / CGFloat(data.count)
        
        return ZStack(alignment: .bottom) {
            // Axis and grid
            gridLines(width: size.width, height: chartHeight)
            
            // Bars and connectors
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    verticalBar(
                        item: item,
                        index: index,
                        barWidth: barWidth,
                        chartHeight: chartHeight
                    )
                }
            }
            .padding(.horizontal, barSpacing)
            
            // Connector lines
            if showConnectors {
                connectorLines(barWidth: barWidth, chartHeight: chartHeight, totalWidth: size.width)
            }
        }
    }
    
    @ViewBuilder
    private func verticalBar(item: WaterfallItem, index: Int, barWidth: CGFloat, chartHeight: CGFloat) -> some View {
        let color = barColor(for: item)
        let isSelected = selectedIndex == index
        let isHovered = hoveredIndex == index
        
        let (barTop, barBottom, barHeight) = calculateBarMetrics(index: index, chartHeight: chartHeight)
        
        VStack(spacing: 2) {
            // Value label above bar
            if showValues {
                valueLabel(for: item, index: index)
                    .opacity(animationProgress)
            }
            
            // Bar
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .frame(width: barWidth, height: barHeight * animationProgress)
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2)
                    .frame(width: barWidth, height: barHeight * animationProgress)
                
                if isHovered {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: barWidth, height: barHeight * animationProgress)
                }
            }
            .frame(height: chartHeight, alignment: .bottom)
            .offset(y: -barBottom)
            
            // Label
            Text(item.label)
                .font(.caption)
                .foregroundColor(theme.foregroundColor)
                .lineLimit(1)
                .frame(width: barWidth)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = selectedIndex == index ? nil : index
            }
        }
        .onHover { hovering in
            hoveredIndex = hovering ? index : nil
        }
        .accessibilityElement()
        .accessibilityLabel("\(item.label): \(String(format: valueFormat, item.value))")
    }
    
    @ViewBuilder
    private func valueLabel(for item: WaterfallItem, index: Int) -> some View {
        VStack(spacing: 0) {
            if showDelta && item.type != .total && item.type != .subtotal {
                Text((item.value >= 0 ? "+" : "") + String(format: valueFormat, item.value))
                    .font(.caption2)
                    .foregroundColor(item.value >= 0 ? positiveColor : negativeColor)
            }
            
            Text(String(format: valueFormat, runningTotals[index]))
                .font(.caption.bold())
                .foregroundColor(theme.foregroundColor)
        }
    }
    
    private func calculateBarMetrics(index: Int, chartHeight: CGFloat) -> (top: CGFloat, bottom: CGFloat, height: CGFloat) {
        let item = data[index]
        let total = runningTotals[index]
        let range = valueRange.max - valueRange.min
        guard range > 0 else { return (0, 0, 0) }
        
        let scale = chartHeight / CGFloat(range)
        let zeroY = CGFloat(valueRange.max) * scale
        
        switch item.type {
        case .total, .subtotal:
            let barTop = zeroY - CGFloat(total) * scale
            let barHeight = CGFloat(abs(total)) * scale
            return (barTop, zeroY - barHeight, barHeight)
            
        case .positive, .negative:
            let prevTotal = index > 0 ? runningTotals[index - 1] : 0
            let barStart = CGFloat(prevTotal - valueRange.min) / CGFloat(range) * chartHeight
            let barEnd = CGFloat(total - valueRange.min) / CGFloat(range) * chartHeight
            let barTop = chartHeight - max(barStart, barEnd)
            let barBottom = chartHeight - min(barStart, barEnd)
            let barHeight = abs(barEnd - barStart)
            return (barTop, barBottom, barHeight)
        }
    }
    
    // MARK: - Horizontal Waterfall
    
    private func horizontalWaterfall(size: CGSize) -> some View {
        let labelWidth: CGFloat = 80
        let chartWidth = size.width - labelWidth - 20
        let barHeight = (size.height - CGFloat(data.count + 1) * barSpacing) / CGFloat(data.count)
        
        return HStack(spacing: 0) {
            // Labels
            VStack(spacing: barSpacing) {
                ForEach(data) { item in
                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(theme.foregroundColor)
                        .frame(height: barHeight, alignment: .trailing)
                        .frame(width: labelWidth, alignment: .trailing)
                }
            }
            .padding(.vertical, barSpacing)
            
            // Bars
            VStack(spacing: barSpacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    horizontalBar(item: item, index: index, barHeight: barHeight, chartWidth: chartWidth)
                }
            }
            .padding(.vertical, barSpacing)
        }
    }
    
    @ViewBuilder
    private func horizontalBar(item: WaterfallItem, index: Int, barHeight: CGFloat, chartWidth: CGFloat) -> some View {
        let color = barColor(for: item)
        let isSelected = selectedIndex == index
        let total = runningTotals[index]
        let range = valueRange.max - valueRange.min
        let scale = chartWidth / CGFloat(range)
        
        let barWidth: CGFloat
        let barOffset: CGFloat
        
        switch item.type {
        case .total, .subtotal:
            barWidth = CGFloat(abs(total)) * scale * animationProgress
            barOffset = 0
        case .positive, .negative:
            let prevTotal = index > 0 ? runningTotals[index - 1] : 0
            barWidth = CGFloat(abs(item.value)) * scale * animationProgress
            barOffset = CGFloat(min(prevTotal, total) - valueRange.min) * scale
        }
        
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
                .frame(width: barWidth, height: barHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2)
                )
                .offset(x: barOffset)
            
            if showValues {
                Text(String(format: valueFormat, total))
                    .font(.caption)
                    .foregroundColor(theme.foregroundColor)
                    .opacity(animationProgress)
            }
            
            Spacer()
        }
        .frame(height: barHeight)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = selectedIndex == index ? nil : index
            }
        }
    }
    
    // MARK: - Grid Lines
    
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
    
    // MARK: - Connector Lines
    
    private func connectorLines(barWidth: CGFloat, chartHeight: CGFloat, totalWidth: CGFloat) -> some View {
        Canvas { context, size in
            let range = valueRange.max - valueRange.min
            guard range > 0 else { return }
            
            for index in 0..<(data.count - 1) {
                let total = runningTotals[index]
                let y = chartHeight - CGFloat((total - valueRange.min) / range) * chartHeight
                
                let startX = barSpacing + CGFloat(index + 1) * (barWidth + barSpacing) - barSpacing / 2
                let endX = startX + barSpacing
                
                var path = Path()
                path.move(to: CGPoint(x: startX, y: y))
                path.addLine(to: CGPoint(x: endX, y: y))
                
                context.stroke(
                    path,
                    with: .color(theme.gridColor),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                )
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Helpers
    
    private func barColor(for item: WaterfallItem) -> Color {
        if let color = item.color { return color }
        
        switch item.type {
        case .positive:
            return positiveColor
        case .negative:
            return negativeColor
        case .total, .subtotal:
            return totalColor
        }
    }
}

// MARK: - Supporting Types

/// A data item for waterfall charts
public struct WaterfallItem: Identifiable {
    public let id: UUID
    
    /// The label for this item
    public let label: String
    
    /// The value (positive or negative)
    public let value: Double
    
    /// The item type
    public let type: WaterfallItemType
    
    /// Optional custom color
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        label: String,
        value: Double,
        type: WaterfallItemType = .positive,
        color: Color? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.type = type.inferred(from: value)
        self.color = color
    }
}

/// Type of waterfall item
public enum WaterfallItemType {
    /// Positive change
    case positive
    
    /// Negative change
    case negative
    
    /// Running total
    case total
    
    /// Subtotal
    case subtotal
    
    func inferred(from value: Double) -> WaterfallItemType {
        switch self {
        case .total, .subtotal:
            return self
        default:
            return value >= 0 ? .positive : .negative
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct WaterfallChart_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            WaterfallItem(label: "Start", value: 100, type: .total),
            WaterfallItem(label: "Sales", value: 80, type: .positive),
            WaterfallItem(label: "Returns", value: -20, type: .negative),
            WaterfallItem(label: "Marketing", value: -30, type: .negative),
            WaterfallItem(label: "New Clients", value: 50, type: .positive),
            WaterfallItem(label: "End", value: 180, type: .total)
        ]
        
        VStack(spacing: 20) {
            WaterfallChart(data: data)
                .frame(height: 300)
            
            WaterfallChart(data: data, isHorizontal: true)
                .frame(height: 250)
        }
        .padding()
    }
}
#endif
