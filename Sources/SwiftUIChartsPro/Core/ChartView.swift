import SwiftUI

// MARK: - Chart Protocol

/// Base protocol for all chart views
public protocol ChartViewProtocol: View {
    associatedtype DataType
    var data: DataType { get }
    var theme: ChartTheme { get }
}

// MARK: - Chart Selection Handler

/// Closure type for handling chart element selection
public typealias ChartSelectionHandler = (Int, Double) -> Void

// MARK: - Chart Modifier Keys

private struct ChartThemeKey: EnvironmentKey {
    static let defaultValue: ChartTheme = .default
}

private struct ChartTooltipKey: EnvironmentKey {
    static let defaultValue: AnyView? = nil
}

extension EnvironmentValues {
    public var chartTheme: ChartTheme {
        get { self[ChartThemeKey.self] }
        set { self[ChartThemeKey.self] = newValue }
    }

    var chartTooltipView: AnyView? {
        get { self[ChartTooltipKey.self] }
        set { self[ChartTooltipKey.self] = newValue }
    }
}

// MARK: - Chart View Modifiers

public extension View {
    /// Apply a chart theme to the chart
    func chartTheme(_ theme: ChartTheme) -> some View {
        environment(\.chartTheme, theme)
    }

    /// Add a tooltip builder to the chart
    func chartTooltip<Content: View>(
        @ViewBuilder content: @escaping (Double, String) -> Content
    ) -> some View {
        environment(\.chartTooltipView, AnyView(content(0, "")))
    }

    /// Handle chart element selection
    func onChartSelection(_ handler: @escaping ChartSelectionHandler) -> some View {
        self.onPreferenceChange(ChartSelectionPreference.self) { selection in
            if let selection = selection {
                handler(selection.index, selection.value)
            }
        }
    }
}

// MARK: - Selection Preference

struct ChartSelection: Equatable {
    let index: Int
    let value: Double
}

struct ChartSelectionPreference: PreferenceKey {
    static let defaultValue: ChartSelection? = nil
    static func reduce(value: inout ChartSelection?, nextValue: () -> ChartSelection?) {
        value = nextValue() ?? value
    }
}

// MARK: - Axis Configuration

/// Configuration for chart axes
public struct AxisConfiguration {
    public let showGrid: Bool
    public let showLabels: Bool
    public let labelCount: Int
    public let gridLineStyle: StrokeStyle
    public let labelFont: Font
    public let labelColor: Color

    public init(
        showGrid: Bool = true,
        showLabels: Bool = true,
        labelCount: Int = 5,
        gridLineStyle: StrokeStyle = StrokeStyle(lineWidth: 0.5, dash: [4, 4]),
        labelFont: Font = .caption2,
        labelColor: Color = .secondary
    ) {
        self.showGrid = showGrid
        self.showLabels = showLabels
        self.labelCount = labelCount
        self.gridLineStyle = gridLineStyle
        self.labelFont = labelFont
        self.labelColor = labelColor
    }

    public static let `default` = AxisConfiguration()
    public static let hidden = AxisConfiguration(showGrid: false, showLabels: false)
}

// MARK: - Chart Legend

/// A reusable chart legend component
public struct ChartLegend: View {
    public let items: [(label: String, color: Color)]
    public let orientation: Axis

    public init(items: [(label: String, color: Color)], orientation: Axis = .horizontal) {
        self.items = items
        self.orientation = orientation
    }

    public var body: some View {
        let layout = orientation == .horizontal
            ? AnyLayout(HStackLayout(spacing: 16))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 8))

        layout {
            ForEach(0..<items.count, id: \.self) { index in
                HStack(spacing: 6) {
                    Circle()
                        .fill(items[index].color)
                        .frame(width: 8, height: 8)
                    Text(items[index].label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
