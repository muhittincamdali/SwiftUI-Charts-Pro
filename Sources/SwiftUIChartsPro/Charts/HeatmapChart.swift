import SwiftUI

// MARK: - Heatmap Chart

/// A color-coded matrix chart for visualizing 2D data distributions
public struct HeatmapChart: View {
    @Environment(\.chartTheme) private var theme

    public let data: [[Double]]
    public let rowLabels: [String]
    public let columnLabels: [String]
    public let colorRange: (Color, Color)
    public let showValues: Bool
    public let cornerRadius: CGFloat
    public let cellSpacing: CGFloat
    public let valueFormat: String

    @State private var selectedCell: (row: Int, col: Int)?
    @State private var animationProgress: CGFloat = 0

    public init(
        data: [[Double]],
        rowLabels: [String] = [],
        columnLabels: [String] = [],
        colorRange: (Color, Color) = (.blue.opacity(0.1), .blue),
        showValues: Bool = true,
        cornerRadius: CGFloat = 4,
        cellSpacing: CGFloat = 2,
        valueFormat: String = "%.1f"
    ) {
        self.data = data
        self.rowLabels = rowLabels
        self.columnLabels = columnLabels
        self.colorRange = colorRange
        self.showValues = showValues
        self.cornerRadius = cornerRadius
        self.cellSpacing = cellSpacing
        self.valueFormat = valueFormat
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Column headers
            if !columnLabels.isEmpty {
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

            // Grid rows
            ForEach(0..<rowCount, id: \.self) { row in
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

            // Color scale legend
            colorScaleLegend
                .padding(.top, 12)
        }
        .padding(4)
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
    }

    // MARK: - Cell View

    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {
        let value = cellValue(row: row, col: col)
        let normalized = normalizedValue(value)
        let isSelected = selectedCell?.row == row && selectedCell?.col == col

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(interpolatedColor(normalized))
                .opacity(animationProgress)

            if showValues {
                Text(String(format: valueFormat, value))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(normalized > 0.5 ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedCell?.row == row && selectedCell?.col == col {
                    selectedCell = nil
                } else {
                    selectedCell = (row, col)
                }
            }
        }
    }

    // MARK: - Color Scale Legend

    private var colorScaleLegend: some View {
        HStack(spacing: 4) {
            Text(String(format: valueFormat, globalMin))
                .font(.caption2)
                .foregroundColor(.secondary)

            LinearGradient(
                colors: [colorRange.0, colorRange.1],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 8)
            .cornerRadius(4)

            Text(String(format: valueFormat, globalMax))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private var rowCount: Int { data.count }
    private var columnCount: Int { data.first?.count ?? 0 }
    private var rowLabelWidth: CGFloat { 50 }

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
        return Color(
            red: lerp(colorRange.0, colorRange.1, component: \.red, fraction: clamped),
            green: lerp(colorRange.0, colorRange.1, component: \.green, fraction: clamped),
            blue: lerp(colorRange.0, colorRange.1, component: \.blue, fraction: clamped)
        )
    }

    private func lerp(_ from: Color, _ to: Color, component: KeyPath<Color.Resolved, Float>, fraction: Double) -> Double {
        // Simplified interpolation using opacity as a proxy
        return fraction
    }
}
