import SwiftUI

// MARK: - Heatmap Chart

/// A color-coded matrix chart for visualizing 2D data distributions.
///
/// Heatmaps are excellent for showing patterns in large datasets where
/// the intensity of values is represented by color gradients.
///
/// ```swift
/// let data = [
///     [1.0, 2.0, 3.0],
///     [4.0, 5.0, 6.0],
///     [7.0, 8.0, 9.0]
/// ]
///
/// HeatmapChart(
///     data: data,
///     rowLabels: ["A", "B", "C"],
///     columnLabels: ["X", "Y", "Z"]
/// )
/// ```
public struct HeatmapChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration

    /// The 2D data matrix
    public let data: [[Double]]
    
    /// Labels for each row
    public let rowLabels: [String]
    
    /// Labels for each column
    public let columnLabels: [String]
    
    /// The color range for the gradient (min, max)
    public let colorRange: (Color, Color)
    
    /// Whether to display values in cells
    public let showValues: Bool
    
    /// Corner radius for cells
    public let cornerRadius: CGFloat
    
    /// Spacing between cells
    public let cellSpacing: CGFloat
    
    /// Format string for displayed values
    public let valueFormat: String
    
    /// Whether to show the color scale legend
    public let showLegend: Bool
    
    /// Custom color interpolation function
    public let colorInterpolation: ColorInterpolation

    @State private var selectedCell: CellPosition?
    @State private var animationProgress: CGFloat = 0
    @State private var hoveredCell: CellPosition?

    /// Creates a heatmap chart.
    ///
    /// - Parameters:
    ///   - data: 2D array of values
    ///   - rowLabels: Labels for rows
    ///   - columnLabels: Labels for columns
    ///   - colorRange: Gradient color range
    ///   - showValues: Whether to show values in cells
    ///   - cornerRadius: Cell corner radius
    ///   - cellSpacing: Spacing between cells
    ///   - valueFormat: Number format for values
    ///   - showLegend: Whether to show color scale
    ///   - colorInterpolation: Color interpolation method
    public init(
        data: [[Double]],
        rowLabels: [String] = [],
        columnLabels: [String] = [],
        colorRange: (Color, Color) = (.blue.opacity(0.1), .blue),
        showValues: Bool = true,
        cornerRadius: CGFloat = 4,
        cellSpacing: CGFloat = 2,
        valueFormat: String = "%.1f",
        showLegend: Bool = true,
        colorInterpolation: ColorInterpolation = .linear
    ) {
        self.data = data
        self.rowLabels = rowLabels
        self.columnLabels = columnLabels
        self.colorRange = colorRange
        self.showValues = showValues
        self.cornerRadius = cornerRadius
        self.cellSpacing = cellSpacing
        self.valueFormat = valueFormat
        self.showLegend = showLegend
        self.colorInterpolation = colorInterpolation
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Column headers
            if !columnLabels.isEmpty {
                columnHeaderView
            }

            // Grid rows
            ForEach(0..<rowCount, id: \.self) { row in
                rowView(row: row)
            }

            // Color scale legend
            if showLegend {
                colorScaleLegend
                    .padding(.top, 12)
            }
        }
        .padding(4)
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Heatmap chart with \(rowCount) rows and \(columnCount) columns")
    }
    
    // MARK: - Column Header View
    
    private var columnHeaderView: some View {
        HStack(spacing: cellSpacing) {
            if !rowLabels.isEmpty {
                Text("")
                    .frame(width: rowLabelWidth)
            }
            ForEach(0..<columnCount, id: \.self) { col in
                Text(col < columnLabels.count ? columnLabels[col] : "")
                    .font(theme.font)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
            }
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - Row View
    
    private func rowView(row: Int) -> some View {
        HStack(spacing: cellSpacing) {
            // Row label
            if !rowLabels.isEmpty {
                Text(row < rowLabels.count ? rowLabels[row] : "")
                    .font(theme.font)
                    .foregroundColor(.secondary)
                    .frame(width: rowLabelWidth, alignment: .trailing)
                    .lineLimit(1)
            }

            // Cells
            ForEach(0..<columnCount, id: \.self) { col in
                cellView(row: row, col: col)
            }
        }
    }

    // MARK: - Cell View

    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {
        let value = cellValue(row: row, col: col)
        let normalized = normalizedValue(value)
        let isSelected = selectedCell?.row == row && selectedCell?.col == col
        let isHovered = hoveredCell?.row == row && hoveredCell?.col == col

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(interpolatedColor(normalized))
                .opacity(animationProgress)

            if showValues {
                Text(String(format: valueFormat, value))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(textColorForBackground(normalized))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isSelected ? theme.accentColor : (isHovered ? theme.foregroundColor.opacity(0.5) : .clear), lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedCell?.row == row && selectedCell?.col == col {
                    selectedCell = nil
                } else {
                    selectedCell = CellPosition(row: row, col: col)
                }
            }
        }
        .onHover { hovering in
            hoveredCell = hovering ? CellPosition(row: row, col: col) : nil
        }
        .accessibilityElement()
        .accessibilityLabel(cellAccessibilityLabel(row: row, col: col, value: value))
        .accessibilityValue(String(format: valueFormat, value))
    }
    
    private func cellAccessibilityLabel(row: Int, col: Int, value: Double) -> String {
        let rowLabel = row < rowLabels.count ? rowLabels[row] : "Row \(row + 1)"
        let colLabel = col < columnLabels.count ? columnLabels[col] : "Column \(col + 1)"
        return "\(rowLabel), \(colLabel): \(String(format: valueFormat, value))"
    }
    
    private func textColorForBackground(_ normalized: Double) -> Color {
        normalized > 0.5 ? .white : theme.foregroundColor
    }

    // MARK: - Color Scale Legend

    private var colorScaleLegend: some View {
        HStack(spacing: 4) {
            Text(String(format: valueFormat, globalMin))
                .font(.caption2)
                .foregroundColor(.secondary)

            LinearGradient(
                colors: generateGradientColors(),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 8)
            .cornerRadius(4)

            Text(String(format: valueFormat, globalMax))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement()
        .accessibilityLabel("Color scale from \(String(format: valueFormat, globalMin)) to \(String(format: valueFormat, globalMax))")
    }
    
    private func generateGradientColors() -> [Color] {
        switch colorInterpolation {
        case .linear:
            return [colorRange.0, colorRange.1]
        case .stepped(let steps):
            return (0..<steps).map { i in
                interpolatedColor(Double(i) / Double(steps - 1))
            }
        case .diverging(let midColor):
            return [colorRange.0, midColor, colorRange.1]
        }
    }

    // MARK: - Helpers

    private var rowCount: Int { data.count }
    private var columnCount: Int { data.first?.count ?? 0 }
    private var rowLabelWidth: CGFloat { 60 }

    private func cellValue(row: Int, col: Int) -> Double {
        guard row < data.count, col < data[row].count else { return 0 }
        return data[row][col]
    }

    private var globalMin: Double {
        data.flatMap { $0 }.min() ?? 0
    }

    private var globalMax: Double {
        data.flatMap { $0 }.max() ?? 1
    }

    private func normalizedValue(_ value: Double) -> Double {
        let range = globalMax - globalMin
        guard range > 0 else { return 0.5 }
        return (value - globalMin) / range
    }

    private func interpolatedColor(_ fraction: Double) -> Color {
        let clamped = min(1, max(0, fraction))
        
        switch colorInterpolation {
        case .linear:
            return linearInterpolate(colorRange.0, colorRange.1, fraction: clamped)
        case .stepped(let steps):
            let step = Int(clamped * Double(steps - 1))
            return linearInterpolate(colorRange.0, colorRange.1, fraction: Double(step) / Double(steps - 1))
        case .diverging(let midColor):
            if clamped < 0.5 {
                return linearInterpolate(colorRange.0, midColor, fraction: clamped * 2)
            } else {
                return linearInterpolate(midColor, colorRange.1, fraction: (clamped - 0.5) * 2)
            }
        }
    }
    
    private func linearInterpolate(_ from: Color, _ to: Color, fraction: Double) -> Color {
        let fromComponents = from.rgbaComponents
        let toComponents = to.rgbaComponents
        
        return Color(
            red: fromComponents.red + (toComponents.red - fromComponents.red) * fraction,
            green: fromComponents.green + (toComponents.green - fromComponents.green) * fraction,
            blue: fromComponents.blue + (toComponents.blue - fromComponents.blue) * fraction,
            opacity: fromComponents.alpha + (toComponents.alpha - fromComponents.alpha) * fraction
        )
    }
}

// MARK: - Supporting Types

/// Cell position in the heatmap
private struct CellPosition: Equatable {
    let row: Int
    let col: Int
}

/// Color interpolation method for heatmaps
public enum ColorInterpolation {
    /// Linear interpolation between two colors
    case linear
    
    /// Stepped interpolation with discrete colors
    case stepped(Int)
    
    /// Diverging interpolation with a middle color
    case diverging(Color)
}

// MARK: - Color Extension

private extension Color {
    var rgbaComponents: (red: Double, green: Double, blue: Double, alpha: Double) {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #else
        // Fallback for macOS
        return (0.5, 0.5, 0.5, 1.0)
        #endif
    }
}

// MARK: - Preview Provider

#if DEBUG
struct HeatmapChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData: [[Double]] = [
            [1.0, 2.0, 3.0, 4.0, 5.0],
            [2.0, 4.0, 6.0, 8.0, 10.0],
            [3.0, 6.0, 9.0, 12.0, 15.0],
            [4.0, 8.0, 12.0, 16.0, 20.0],
            [5.0, 10.0, 15.0, 20.0, 25.0]
        ]
        
        VStack(spacing: 20) {
            HeatmapChart(
                data: sampleData,
                rowLabels: ["A", "B", "C", "D", "E"],
                columnLabels: ["Mon", "Tue", "Wed", "Thu", "Fri"]
            )
            .frame(height: 250)
            
            HeatmapChart(
                data: sampleData,
                colorRange: (.green.opacity(0.1), .green),
                showValues: false,
                colorInterpolation: .diverging(.yellow)
            )
            .frame(height: 200)
        }
        .padding()
    }
}
#endif
