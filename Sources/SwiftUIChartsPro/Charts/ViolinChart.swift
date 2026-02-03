import SwiftUI

// MARK: - Violin Chart

/// A chart combining box plots with kernel density estimation.
///
/// Violin charts show the distribution shape of data, providing more
/// information than traditional box plots about data density.
///
/// ```swift
/// let data = [
///     ViolinData(label: "Group A", values: generateNormalData(mean: 50, std: 10)),
///     ViolinData(label: "Group B", values: generateNormalData(mean: 60, std: 15))
/// ]
///
/// ViolinChart(data: data)
/// ```
public struct ViolinChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The violin data sets
    public let data: [ViolinData]
    
    /// Whether to show box plot inside violin
    public let showBoxPlot: Bool
    
    /// Whether to show individual data points
    public let showPoints: Bool
    
    /// Whether to show median line
    public let showMedian: Bool
    
    /// Whether to show mean marker
    public let showMean: Bool
    
    /// Width of each violin
    public let violinWidth: CGFloat
    
    /// Fill opacity
    public let fillOpacity: Double
    
    /// Bandwidth for kernel density estimation
    public let bandwidth: Double?
    
    /// Number of points for density curve
    public let densityPoints: Int
    
    /// Whether violins are horizontal
    public let isHorizontal: Bool
    
    /// Whether to mirror the violin (symmetric)
    public let isMirrored: Bool
    
    /// Value format string
    public let valueFormat: String
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var hoveredIndex: Int?
    
    /// Creates a violin chart.
    public init(
        data: [ViolinData],
        showBoxPlot: Bool = true,
        showPoints: Bool = false,
        showMedian: Bool = true,
        showMean: Bool = true,
        violinWidth: CGFloat = 60,
        fillOpacity: Double = 0.5,
        bandwidth: Double? = nil,
        densityPoints: Int = 50,
        isHorizontal: Bool = false,
        isMirrored: Bool = true,
        valueFormat: String = "%.1f"
    ) {
        self.data = data
        self.showBoxPlot = showBoxPlot
        self.showPoints = showPoints
        self.showMedian = showMedian
        self.showMean = showMean
        self.violinWidth = violinWidth
        self.fillOpacity = fillOpacity
        self.bandwidth = bandwidth
        self.densityPoints = densityPoints
        self.isHorizontal = isHorizontal
        self.isMirrored = isMirrored
        self.valueFormat = valueFormat
    }
    
    private var valueRange: (min: Double, max: Double) {
        var allValues: [Double] = []
        for item in data {
            allValues.append(contentsOf: item.values)
        }
        
        let min = allValues.min() ?? 0
        let max = allValues.max() ?? 100
        let padding = (max - min) * 0.1
        
        return (min - padding, max + padding)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if isHorizontal {
                horizontalViolin(size: geometry.size)
            } else {
                verticalViolin(size: geometry.size)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Violin chart with \(data.count) groups")
    }
    
    // MARK: - Vertical Violin
    
    private func verticalViolin(size: CGSize) -> some View {
        let labelHeight: CGFloat = 30
        let axisWidth: CGFloat = 50
        let chartHeight = size.height - labelHeight
        let chartWidth = size.width - axisWidth
        let spacing = (chartWidth - CGFloat(data.count) * violinWidth) / CGFloat(data.count + 1)
        
        return ZStack(alignment: .topLeading) {
            // Grid
            gridLines(width: chartWidth, height: chartHeight)
                .offset(x: axisWidth)
            
            // Y axis labels
            yAxisLabels(height: chartHeight)
            
            // Violins
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 4) {
                        violinView(item: item, index: index, chartHeight: chartHeight)
                            .frame(width: violinWidth, height: chartHeight)
                        
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
                tooltipView(for: data[index])
            }
        }
    }
    
    @ViewBuilder
    private func violinView(item: ViolinData, index: Int, chartHeight: CGFloat) -> some View {
        let color = item.color ?? theme.color(at: index)
        let isSelected = selectedIndex == index
        let isHovered = hoveredIndex == index
        
        let density = calculateKernelDensity(values: item.values)
        let maxDensity = density.map { $0.density }.max() ?? 1
        
        let range = valueRange.max - valueRange.min
        guard range > 0 else { return EmptyView().eraseToAnyView() }
        
        ZStack {
            // Violin shape
            violinPath(density: density, maxDensity: maxDensity, chartHeight: chartHeight)
                .fill(color.opacity(fillOpacity * animationProgress))
            
            violinPath(density: density, maxDensity: maxDensity, chartHeight: chartHeight)
                .stroke(color, lineWidth: isSelected ? 3 : 2)
                .opacity(animationProgress)
            
            // Box plot overlay
            if showBoxPlot {
                boxPlotOverlay(values: item.values, color: color, chartHeight: chartHeight)
            }
            
            // Median line
            if showMedian {
                let median = item.median
                let y = chartHeight - CGFloat((median - valueRange.min) / range) * chartHeight
                
                Path { path in
                    path.move(to: CGPoint(x: violinWidth * 0.2, y: y))
                    path.addLine(to: CGPoint(x: violinWidth * 0.8, y: y))
                }
                .stroke(Color.white, lineWidth: 2)
                .opacity(animationProgress)
            }
            
            // Mean marker
            if showMean {
                let mean = item.mean
                let y = chartHeight - CGFloat((mean - valueRange.min) / range) * chartHeight
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .position(x: violinWidth / 2, y: y)
                    .opacity(animationProgress)
            }
            
            // Data points
            if showPoints {
                ForEach(Array(item.values.enumerated()), id: \.offset) { _, value in
                    let y = chartHeight - CGFloat((value - valueRange.min) / range) * chartHeight
                    let jitter = CGFloat.random(in: -violinWidth * 0.1...violinWidth * 0.1)
                    
                    Circle()
                        .fill(color.opacity(0.5))
                        .frame(width: 4, height: 4)
                        .position(x: violinWidth / 2 + jitter, y: y)
                        .opacity(animationProgress)
                }
            }
            
            // Hover highlight
            if isHovered {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: violinWidth + 10, height: chartHeight)
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
    
    private func violinPath(density: [DensityPoint], maxDensity: Double, chartHeight: CGFloat) -> Path {
        let range = valueRange.max - valueRange.min
        guard range > 0, maxDensity > 0 else { return Path() }
        
        let scale: (Double) -> CGFloat = { value in
            chartHeight - CGFloat((value - valueRange.min) / range) * chartHeight
        }
        
        let widthScale = (violinWidth / 2) / CGFloat(maxDensity)
        
        return Path { path in
            // Right side
            if let first = density.first {
                path.move(to: CGPoint(
                    x: violinWidth / 2 + CGFloat(first.density) * widthScale * animationProgress,
                    y: scale(first.value)
                ))
            }
            
            for point in density.dropFirst() {
                let x = violinWidth / 2 + CGFloat(point.density) * widthScale * animationProgress
                let y = scale(point.value)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            // Left side (mirror)
            if isMirrored {
                for point in density.reversed() {
                    let x = violinWidth / 2 - CGFloat(point.density) * widthScale * animationProgress
                    let y = scale(point.value)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            path.closeSubpath()
        }
    }
    
    @ViewBuilder
    private func boxPlotOverlay(values: [Double], color: Color, chartHeight: CGFloat) -> some View {
        let sorted = values.sorted()
        let n = sorted.count
        guard n > 0 else { return EmptyView().eraseToAnyView() }
        
        let q1 = sorted[n / 4]
        let median = n % 2 == 0 ? (sorted[n/2 - 1] + sorted[n/2]) / 2 : sorted[n/2]
        let q3 = sorted[(3 * n) / 4]
        
        let range = valueRange.max - valueRange.min
        guard range > 0 else { return EmptyView().eraseToAnyView() }
        
        let q1Y = chartHeight - CGFloat((q1 - valueRange.min) / range) * chartHeight
        let medianY = chartHeight - CGFloat((median - valueRange.min) / range) * chartHeight
        let q3Y = chartHeight - CGFloat((q3 - valueRange.min) / range) * chartHeight
        
        let boxWidth: CGFloat = 8
        
        ZStack {
            // Box
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: boxWidth, height: abs(q1Y - q3Y) * animationProgress)
                .position(x: violinWidth / 2, y: (q1Y + q3Y) / 2)
            
            // Median
            Rectangle()
                .fill(color)
                .frame(width: boxWidth, height: 2)
                .position(x: violinWidth / 2, y: medianY)
        }
        .opacity(animationProgress)
        .eraseToAnyView()
    }
    
    // MARK: - Horizontal Violin
    
    private func horizontalViolin(size: CGSize) -> some View {
        let labelWidth: CGFloat = 80
        let chartWidth = size.width - labelWidth
        let chartHeight = size.height - 30
        let spacing = (chartHeight - CGFloat(data.count) * violinWidth) / CGFloat(data.count + 1)
        
        return ZStack(alignment: .topLeading) {
            // Grid
            horizontalGridLines(width: chartWidth, height: chartHeight)
                .offset(x: labelWidth)
            
            // Violins
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Text(item.label)
                            .font(.caption)
                            .foregroundColor(theme.foregroundColor)
                            .frame(width: labelWidth, alignment: .trailing)
                        
                        horizontalViolinView(item: item, index: index, chartWidth: chartWidth)
                            .frame(width: chartWidth, height: violinWidth)
                    }
                }
            }
            .padding(.top, spacing)
        }
    }
    
    @ViewBuilder
    private func horizontalViolinView(item: ViolinData, index: Int, chartWidth: CGFloat) -> some View {
        let color = item.color ?? theme.color(at: index)
        let density = calculateKernelDensity(values: item.values)
        let maxDensity = density.map { $0.density }.max() ?? 1
        
        let range = valueRange.max - valueRange.min
        guard range > 0 else { return EmptyView().eraseToAnyView() }
        
        let scale: (Double) -> CGFloat = { value in
            CGFloat((value - valueRange.min) / range) * chartWidth
        }
        
        let heightScale = (violinWidth / 2) / CGFloat(maxDensity)
        
        Path { path in
            if let first = density.first {
                path.move(to: CGPoint(
                    x: scale(first.value),
                    y: violinWidth / 2 - CGFloat(first.density) * heightScale * animationProgress
                ))
            }
            
            for point in density.dropFirst() {
                path.addLine(to: CGPoint(
                    x: scale(point.value),
                    y: violinWidth / 2 - CGFloat(point.density) * heightScale * animationProgress
                ))
            }
            
            if isMirrored {
                for point in density.reversed() {
                    path.addLine(to: CGPoint(
                        x: scale(point.value),
                        y: violinWidth / 2 + CGFloat(point.density) * heightScale * animationProgress
                    ))
                }
            }
            
            path.closeSubpath()
        }
        .fill(color.opacity(fillOpacity * animationProgress))
        .overlay(
            Path { path in
                // Same path for stroke
            }
            .stroke(color, lineWidth: 2)
        )
        .eraseToAnyView()
    }
    
    // MARK: - Kernel Density Estimation
    
    private func calculateKernelDensity(values: [Double]) -> [DensityPoint] {
        guard !values.isEmpty else { return [] }
        
        let sorted = values.sorted()
        let n = Double(values.count)
        
        // Calculate bandwidth using Silverman's rule
        let std = standardDeviation(values)
        let iqr = interquartileRange(values)
        let h = bandwidth ?? 0.9 * min(std, iqr / 1.34) * pow(n, -0.2)
        
        let min = sorted.first! - 3 * h
        let max = sorted.last! + 3 * h
        let step = (max - min) / Double(densityPoints - 1)
        
        var density: [DensityPoint] = []
        
        for i in 0..<densityPoints {
            let x = min + Double(i) * step
            var sum = 0.0
            
            for value in values {
                let u = (x - value) / h
                sum += gaussianKernel(u)
            }
            
            let d = sum / (n * h)
            density.append(DensityPoint(value: x, density: d))
        }
        
        return density
    }
    
    private func gaussianKernel(_ u: Double) -> Double {
        exp(-0.5 * u * u) / sqrt(2 * .pi)
    }
    
    private func standardDeviation(_ values: [Double]) -> Double {
        let n = Double(values.count)
        guard n > 1 else { return 1 }
        
        let mean = values.reduce(0, +) / n
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / (n - 1)
        return sqrt(variance)
    }
    
    private func interquartileRange(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let n = sorted.count
        return sorted[(3 * n) / 4] - sorted[n / 4]
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
    
    @ViewBuilder
    private func tooltipView(for item: ViolinData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.label)
                .font(.caption.bold())
            
            Text("N: \(item.values.count)")
            Text("Mean: \(String(format: valueFormat, item.mean))")
            Text("Median: \(String(format: valueFormat, item.median))")
            Text("Std: \(String(format: valueFormat, standardDeviation(item.values)))")
        }
        .font(.caption2)
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

/// Data for a single violin
public struct ViolinData: Identifiable {
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
    
    var mean: Double {
        values.reduce(0, +) / Double(values.count)
    }
    
    var median: Double {
        let sorted = values.sorted()
        let n = sorted.count
        return n % 2 == 0 ? (sorted[n/2 - 1] + sorted[n/2]) / 2 : sorted[n/2]
    }
}

/// A point in the density estimation
private struct DensityPoint {
    let value: Double
    let density: Double
}

// MARK: - View Extension

private extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ViolinChart_Previews: PreviewProvider {
    static func generateNormalData(mean: Double, std: Double, count: Int) -> [Double] {
        (0..<count).map { _ in
            // Box-Muller transform for normal distribution
            let u1 = Double.random(in: 0.001...0.999)
            let u2 = Double.random(in: 0.001...0.999)
            let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
            return mean + std * z
        }
    }
    
    static var previews: some View {
        let data = [
            ViolinData(label: "Group A", values: generateNormalData(mean: 50, std: 10, count: 100), color: .blue),
            ViolinData(label: "Group B", values: generateNormalData(mean: 65, std: 15, count: 100), color: .green),
            ViolinData(label: "Group C", values: generateNormalData(mean: 45, std: 8, count: 100), color: .orange)
        ]
        
        ViolinChart(data: data)
            .frame(height: 400)
            .padding()
    }
}
#endif
