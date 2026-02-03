import SwiftUI

/// A protocol that defines the common interface for all chart views.
///
/// Conform to `ChartViewStyle` to create custom chart types that integrate
/// with the tooltip and export systems.
///
/// ```swift
/// struct MyChart: ChartViewStyle {
///     typealias DataType = [Double]
///     func makeBody(data: [Double], configuration: ChartConfiguration) -> some View { ... }
/// }
/// ```
public protocol ChartViewStyle {
    associatedtype DataType
    associatedtype Body: View

    /// Creates the chart body from data and configuration.
    @ViewBuilder
    func makeBody(data: DataType, configuration: ChartConfiguration) -> Body
}

/// Configuration options shared across all chart types.
public struct ChartConfiguration {

    /// Whether to animate data changes.
    public var animated: Bool

    /// The duration of data change animations.
    public var animationDuration: Double

    /// Whether to show grid lines behind the chart.
    public var showGrid: Bool

    /// The color of grid lines.
    public var gridColor: Color

    /// The font used for axis labels.
    public var labelFont: Font

    /// The color of axis labels.
    public var labelColor: Color

    /// Padding around the chart content area.
    public var contentPadding: EdgeInsets

    /// Whether tooltips are enabled.
    public var tooltipsEnabled: Bool

    /// Creates a chart configuration with default values.
    public init(
        animated: Bool = true,
        animationDuration: Double = 0.3,
        showGrid: Bool = true,
        gridColor: Color = .gray.opacity(0.2),
        labelFont: Font = .caption,
        labelColor: Color = .secondary,
        contentPadding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
        tooltipsEnabled: Bool = true
    ) {
        self.animated = animated
        self.animationDuration = animationDuration
        self.showGrid = showGrid
        self.gridColor = gridColor
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.contentPadding = contentPadding
        self.tooltipsEnabled = tooltipsEnabled
    }
}

/// A data point used across chart tooltips and interactions.
public struct ChartDataPoint: Identifiable {
    public let id = UUID()

    /// The label for this data point.
    public let label: String

    /// The numeric value.
    public let value: Double

    /// An optional color associated with this point.
    public let color: Color?

    /// The position of this point within the chart coordinate space.
    public var position: CGPoint

    /// Creates a chart data point.
    public init(label: String, value: Double, color: Color? = nil, position: CGPoint = .zero) {
        self.label = label
        self.value = value
        self.color = color
        self.position = position
    }
}

/// An environment key for passing chart configuration down the view hierarchy.
struct ChartConfigurationKey: EnvironmentKey {
    static let defaultValue = ChartConfiguration()
}

public extension EnvironmentValues {
    /// The current chart configuration.
    var chartConfiguration: ChartConfiguration {
        get { self[ChartConfigurationKey.self] }
        set { self[ChartConfigurationKey.self] = newValue }
    }
}
