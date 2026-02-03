import SwiftUI

// MARK: - Chart View Protocol

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

// MARK: - Base Chart View

/// A container view that provides common chart functionality including
/// theming, tooltips, and export capabilities.
///
/// Use `BaseChartView` as a wrapper around custom chart content to get
/// consistent behavior across all chart types.
///
/// ```swift
/// BaseChartView(title: "Sales Data") {
///     // Your chart content
/// }
/// .chartTheme(.dark)
/// .onChartSelection { point in
///     print("Selected: \(point.label)")
/// }
/// ```
public struct BaseChartView<Content: View>: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The chart title displayed above the content
    public let title: String?
    
    /// Optional subtitle for additional context
    public let subtitle: String?
    
    /// The chart content builder
    public let content: () -> Content
    
    /// Selection callback handler
    private var onSelection: ((ChartDataPoint) -> Void)?
    
    /// State for managing tooltip display
    @State private var tooltipPoint: ChartDataPoint?
    @State private var showTooltip: Bool = false
    
    /// Creates a base chart view with title and content.
    ///
    /// - Parameters:
    ///   - title: The chart title
    ///   - subtitle: Optional subtitle
    ///   - content: The chart content view builder
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title section
            if let title = title {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.titleFont)
                        .foregroundColor(theme.foregroundColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.font)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            // Chart content with overlay for tooltip
            ZStack(alignment: .topLeading) {
                content()
                
                // Tooltip overlay
                if showTooltip, let point = tooltipPoint, configuration.tooltipsEnabled {
                    ChartTooltipView(dataPoint: point)
                        .offset(x: point.position.x, y: point.position.y)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(configuration.contentPadding)
        }
        .background(theme.backgroundColor)
        .animation(configuration.animated ? .easeInOut(duration: configuration.animationDuration) : nil, value: showTooltip)
    }
    
    /// Sets a selection handler for chart data points.
    public func onChartSelection(_ handler: @escaping (ChartDataPoint) -> Void) -> Self {
        var copy = self
        copy.onSelection = handler
        return copy
    }
    
    /// Updates the tooltip with the given data point.
    public func showTooltip(for point: ChartDataPoint?) {
        tooltipPoint = point
        showTooltip = point != nil
    }
}

// MARK: - Chart Tooltip View

/// A tooltip view displaying data point information.
struct ChartTooltipView: View {
    @Environment(\.chartTheme) private var theme
    
    let dataPoint: ChartDataPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dataPoint.label)
                .font(.caption.bold())
                .foregroundColor(theme.foregroundColor)
            
            HStack(spacing: 4) {
                if let color = dataPoint.color {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                
                Text(formatValue(dataPoint.value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else if value == value.rounded() {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Chart Configuration

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
    
    /// Whether to show legend
    public var showLegend: Bool
    
    /// Legend position
    public var legendPosition: LegendPosition

    /// Creates a chart configuration with default values.
    public init(
        animated: Bool = true,
        animationDuration: Double = 0.3,
        showGrid: Bool = true,
        gridColor: Color = .gray.opacity(0.2),
        labelFont: Font = .caption,
        labelColor: Color = .secondary,
        contentPadding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
        tooltipsEnabled: Bool = true,
        showLegend: Bool = true,
        legendPosition: LegendPosition = .bottom
    ) {
        self.animated = animated
        self.animationDuration = animationDuration
        self.showGrid = showGrid
        self.gridColor = gridColor
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.contentPadding = contentPadding
        self.tooltipsEnabled = tooltipsEnabled
        self.showLegend = showLegend
        self.legendPosition = legendPosition
    }
}

/// Position options for chart legend
public enum LegendPosition {
    case top
    case bottom
    case leading
    case trailing
}

// MARK: - Chart Data Point

/// A data point used across chart tooltips and interactions.
public struct ChartDataPoint: Identifiable, Equatable {
    public let id: UUID
    
    /// The label for this data point.
    public let label: String

    /// The numeric value.
    public let value: Double

    /// An optional color associated with this point.
    public let color: Color?

    /// The position of this point within the chart coordinate space.
    public var position: CGPoint
    
    /// Additional metadata for the data point
    public var metadata: [String: String]

    /// Creates a chart data point.
    public init(
        id: UUID = UUID(),
        label: String,
        value: Double,
        color: Color? = nil,
        position: CGPoint = .zero,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.color = color
        self.position = position
        self.metadata = metadata
    }
    
    public static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Environment Keys

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

// MARK: - View Modifiers

public extension View {
    /// Applies a chart configuration to this view and its descendants.
    func chartConfiguration(_ configuration: ChartConfiguration) -> some View {
        environment(\.chartConfiguration, configuration)
    }
    
    /// Enables or disables chart animations.
    func chartAnimated(_ animated: Bool) -> some View {
        transformEnvironment(\.chartConfiguration) { config in
            config.animated = animated
        }
    }
    
    /// Shows or hides the chart grid.
    func chartShowGrid(_ show: Bool) -> some View {
        transformEnvironment(\.chartConfiguration) { config in
            config.showGrid = show
        }
    }
    
    /// Enables or disables tooltips.
    func chartTooltipsEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\.chartConfiguration) { config in
            config.tooltipsEnabled = enabled
        }
    }
}
