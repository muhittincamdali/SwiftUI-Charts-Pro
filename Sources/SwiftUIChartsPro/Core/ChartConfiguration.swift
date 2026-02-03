import SwiftUI

// MARK: - Chart Axis Configuration

/// Configuration for chart axes including labels, ticks, and formatting.
public struct AxisConfiguration: Equatable {
    /// Whether to show the axis line
    public var showAxisLine: Bool
    
    /// Whether to show tick marks
    public var showTicks: Bool
    
    /// Whether to show labels
    public var showLabels: Bool
    
    /// The number of tick marks to display
    public var tickCount: Int
    
    /// The axis line color
    public var axisColor: Color
    
    /// The tick line color
    public var tickColor: Color
    
    /// The label color
    public var labelColor: Color
    
    /// The axis title
    public var title: String?
    
    /// Label rotation angle in degrees
    public var labelRotation: Double
    
    /// Number formatter for labels
    public var numberFormat: String
    
    /// Date formatter for time axes
    public var dateFormat: String?
    
    /// Creates an axis configuration.
    public init(
        showAxisLine: Bool = true,
        showTicks: Bool = true,
        showLabels: Bool = true,
        tickCount: Int = 5,
        axisColor: Color = .gray,
        tickColor: Color = .gray,
        labelColor: Color = .secondary,
        title: String? = nil,
        labelRotation: Double = 0,
        numberFormat: String = "%.1f",
        dateFormat: String? = nil
    ) {
        self.showAxisLine = showAxisLine
        self.showTicks = showTicks
        self.showLabels = showLabels
        self.tickCount = tickCount
        self.axisColor = axisColor
        self.tickColor = tickColor
        self.labelColor = labelColor
        self.title = title
        self.labelRotation = labelRotation
        self.numberFormat = numberFormat
        self.dateFormat = dateFormat
    }
    
    /// Default X axis configuration
    public static let defaultX = AxisConfiguration()
    
    /// Default Y axis configuration
    public static let defaultY = AxisConfiguration()
    
    /// Hidden axis configuration
    public static let hidden = AxisConfiguration(
        showAxisLine: false,
        showTicks: false,
        showLabels: false
    )
}

// MARK: - Chart Grid Configuration

/// Configuration for chart grid lines.
public struct GridConfiguration: Equatable {
    /// Whether to show horizontal grid lines
    public var showHorizontalLines: Bool
    
    /// Whether to show vertical grid lines
    public var showVerticalLines: Bool
    
    /// The grid line color
    public var gridColor: Color
    
    /// The grid line width
    public var lineWidth: CGFloat
    
    /// The dash pattern for grid lines
    public var dashPattern: [CGFloat]
    
    /// The number of horizontal grid lines
    public var horizontalLineCount: Int
    
    /// The number of vertical grid lines
    public var verticalLineCount: Int
    
    /// Creates a grid configuration.
    public init(
        showHorizontalLines: Bool = true,
        showVerticalLines: Bool = true,
        gridColor: Color = Color.gray.opacity(0.2),
        lineWidth: CGFloat = 0.5,
        dashPattern: [CGFloat] = [],
        horizontalLineCount: Int = 5,
        verticalLineCount: Int = 5
    ) {
        self.showHorizontalLines = showHorizontalLines
        self.showVerticalLines = showVerticalLines
        self.gridColor = gridColor
        self.lineWidth = lineWidth
        self.dashPattern = dashPattern
        self.horizontalLineCount = horizontalLineCount
        self.verticalLineCount = verticalLineCount
    }
    
    /// Default grid configuration
    public static let `default` = GridConfiguration()
    
    /// No grid lines
    public static let none = GridConfiguration(
        showHorizontalLines: false,
        showVerticalLines: false
    )
    
    /// Horizontal lines only
    public static let horizontalOnly = GridConfiguration(
        showVerticalLines: false
    )
    
    /// Vertical lines only
    public static let verticalOnly = GridConfiguration(
        showHorizontalLines: false
    )
    
    /// Dashed grid lines
    public static let dashed = GridConfiguration(
        dashPattern: [5, 5]
    )
}

// MARK: - Chart Legend Configuration

/// Configuration for chart legends.
public struct LegendConfiguration: Equatable {
    /// Whether to show the legend
    public var isVisible: Bool
    
    /// The position of the legend
    public var position: LegendPosition
    
    /// The alignment of legend items
    public var alignment: HorizontalAlignment
    
    /// The spacing between legend items
    public var spacing: CGFloat
    
    /// The size of color indicators
    public var indicatorSize: CGFloat
    
    /// The font for legend text
    public var font: Font
    
    /// The color for legend text
    public var textColor: Color
    
    /// Whether legend items are interactive
    public var isInteractive: Bool
    
    /// Creates a legend configuration.
    public init(
        isVisible: Bool = true,
        position: LegendPosition = .bottom,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 8,
        indicatorSize: CGFloat = 12,
        font: Font = .caption,
        textColor: Color = .primary,
        isInteractive: Bool = true
    ) {
        self.isVisible = isVisible
        self.position = position
        self.alignment = alignment
        self.spacing = spacing
        self.indicatorSize = indicatorSize
        self.font = font
        self.textColor = textColor
        self.isInteractive = isInteractive
    }
    
    /// Default legend configuration
    public static let `default` = LegendConfiguration()
    
    /// Hidden legend
    public static let hidden = LegendConfiguration(isVisible: false)
}

// MARK: - Chart Interaction Configuration

/// Configuration for chart interactions like selection and zooming.
public struct InteractionConfiguration: Equatable {
    /// Whether tap selection is enabled
    public var tapSelectionEnabled: Bool
    
    /// Whether drag selection is enabled
    public var dragSelectionEnabled: Bool
    
    /// Whether pinch zoom is enabled
    public var pinchZoomEnabled: Bool
    
    /// Whether pan is enabled
    public var panEnabled: Bool
    
    /// Whether long press is enabled
    public var longPressEnabled: Bool
    
    /// The minimum scale for zooming
    public var minScale: CGFloat
    
    /// The maximum scale for zooming
    public var maxScale: CGFloat
    
    /// The selection feedback style
    public var selectionFeedback: SelectionFeedback
    
    /// Creates an interaction configuration.
    public init(
        tapSelectionEnabled: Bool = true,
        dragSelectionEnabled: Bool = false,
        pinchZoomEnabled: Bool = false,
        panEnabled: Bool = false,
        longPressEnabled: Bool = false,
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 5.0,
        selectionFeedback: SelectionFeedback = .highlight
    ) {
        self.tapSelectionEnabled = tapSelectionEnabled
        self.dragSelectionEnabled = dragSelectionEnabled
        self.pinchZoomEnabled = pinchZoomEnabled
        self.panEnabled = panEnabled
        self.longPressEnabled = longPressEnabled
        self.minScale = minScale
        self.maxScale = maxScale
        self.selectionFeedback = selectionFeedback
    }
    
    /// Default interaction configuration
    public static let `default` = InteractionConfiguration()
    
    /// No interactions
    public static let none = InteractionConfiguration(
        tapSelectionEnabled: false
    )
    
    /// Full interaction support
    public static let full = InteractionConfiguration(
        tapSelectionEnabled: true,
        dragSelectionEnabled: true,
        pinchZoomEnabled: true,
        panEnabled: true,
        longPressEnabled: true
    )
}

/// Selection feedback styles
public enum SelectionFeedback: Equatable {
    /// Highlight the selected element
    case highlight
    
    /// Show a tooltip
    case tooltip
    
    /// Scale the selected element
    case scale
    
    /// Custom feedback
    case custom
}

// MARK: - Full Chart Configuration

/// Complete configuration for a chart view combining all settings.
public struct FullChartConfiguration: Equatable {
    /// Animation settings
    public var animated: Bool
    public var animationDuration: Double
    
    /// Grid configuration
    public var grid: GridConfiguration
    
    /// X axis configuration
    public var xAxis: AxisConfiguration
    
    /// Y axis configuration
    public var yAxis: AxisConfiguration
    
    /// Legend configuration
    public var legend: LegendConfiguration
    
    /// Interaction configuration
    public var interaction: InteractionConfiguration
    
    /// Content padding
    public var contentPadding: EdgeInsets
    
    /// Whether to show tooltips
    public var showTooltips: Bool
    
    /// Creates a full chart configuration.
    public init(
        animated: Bool = true,
        animationDuration: Double = 0.3,
        grid: GridConfiguration = .default,
        xAxis: AxisConfiguration = .defaultX,
        yAxis: AxisConfiguration = .defaultY,
        legend: LegendConfiguration = .default,
        interaction: InteractionConfiguration = .default,
        contentPadding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        showTooltips: Bool = true
    ) {
        self.animated = animated
        self.animationDuration = animationDuration
        self.grid = grid
        self.xAxis = xAxis
        self.yAxis = yAxis
        self.legend = legend
        self.interaction = interaction
        self.contentPadding = contentPadding
        self.showTooltips = showTooltips
    }
    
    /// Default configuration
    public static let `default` = FullChartConfiguration()
    
    /// Minimal configuration with hidden extras
    public static let minimal = FullChartConfiguration(
        grid: .none,
        xAxis: .hidden,
        yAxis: .hidden,
        legend: .hidden,
        interaction: .none
    )
}

// MARK: - Environment Key

private struct FullChartConfigurationKey: EnvironmentKey {
    static let defaultValue = FullChartConfiguration.default
}

public extension EnvironmentValues {
    /// The full chart configuration
    var fullChartConfiguration: FullChartConfiguration {
        get { self[FullChartConfigurationKey.self] }
        set { self[FullChartConfigurationKey.self] = newValue }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Applies a full chart configuration
    func fullChartConfiguration(_ config: FullChartConfiguration) -> some View {
        environment(\.fullChartConfiguration, config)
    }
    
    /// Configures the X axis
    func chartXAxis(_ config: AxisConfiguration) -> some View {
        transformEnvironment(\.fullChartConfiguration) { fullConfig in
            fullConfig.xAxis = config
        }
    }
    
    /// Configures the Y axis
    func chartYAxis(_ config: AxisConfiguration) -> some View {
        transformEnvironment(\.fullChartConfiguration) { fullConfig in
            fullConfig.yAxis = config
        }
    }
    
    /// Configures the grid
    func chartGrid(_ config: GridConfiguration) -> some View {
        transformEnvironment(\.fullChartConfiguration) { fullConfig in
            fullConfig.grid = config
        }
    }
    
    /// Configures the legend
    func chartLegend(_ config: LegendConfiguration) -> some View {
        transformEnvironment(\.fullChartConfiguration) { fullConfig in
            fullConfig.legend = config
        }
    }
    
    /// Configures interactions
    func chartInteraction(_ config: InteractionConfiguration) -> some View {
        transformEnvironment(\.fullChartConfiguration) { fullConfig in
            fullConfig.interaction = config
        }
    }
}
