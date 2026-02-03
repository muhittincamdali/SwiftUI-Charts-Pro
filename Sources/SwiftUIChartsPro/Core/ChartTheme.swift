import SwiftUI

// MARK: - Chart Theme

/// Configuration for chart visual styling.
///
/// Create custom themes to match your app's design system or use built-in presets.
///
/// ```swift
/// RadarChart(data: data)
///     .chartTheme(.dark)
///
/// // Custom theme
/// let custom = ChartTheme(
///     accentColor: .orange,
///     palette: [.orange, .red, .yellow]
/// )
/// ```
public struct ChartTheme: Equatable, Sendable {
    /// Background color for the chart container
    public let backgroundColor: Color
    
    /// Primary foreground color for text and lines
    public let foregroundColor: Color
    
    /// Accent color for highlights and selections
    public let accentColor: Color
    
    /// Color for grid lines
    public let gridColor: Color
    
    /// Color palette for data series
    public let palette: [Color]
    
    /// Font for labels and values
    public let font: Font
    
    /// Font for chart titles
    public let titleFont: Font
    
    /// Duration for animations
    public let animationDuration: Double
    
    /// Corner radius for chart elements
    public let cornerRadius: CGFloat
    
    /// Shadow settings for chart elements
    public let shadowRadius: CGFloat
    
    /// Border width for selections
    public let selectionBorderWidth: CGFloat

    /// Creates a chart theme with customizable properties.
    ///
    /// - Parameters:
    ///   - backgroundColor: Background color
    ///   - foregroundColor: Primary text/line color
    ///   - accentColor: Highlight color
    ///   - gridColor: Grid line color
    ///   - palette: Data series color palette
    ///   - font: Label font
    ///   - titleFont: Title font
    ///   - animationDuration: Animation duration in seconds
    ///   - cornerRadius: Element corner radius
    ///   - shadowRadius: Shadow blur radius
    ///   - selectionBorderWidth: Border width for selections
    public init(
        backgroundColor: Color = .clear,
        foregroundColor: Color = .primary,
        accentColor: Color = .blue,
        gridColor: Color = Color.gray.opacity(0.2),
        palette: [Color] = [.blue, .green, .orange, .purple, .red, .cyan, .mint, .indigo],
        font: Font = .system(size: 12),
        titleFont: Font = .headline,
        animationDuration: Double = 0.5,
        cornerRadius: CGFloat = 8,
        shadowRadius: CGFloat = 4,
        selectionBorderWidth: CGFloat = 2
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.accentColor = accentColor
        self.gridColor = gridColor
        self.palette = palette
        self.font = font
        self.titleFont = titleFont
        self.animationDuration = animationDuration
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.selectionBorderWidth = selectionBorderWidth
    }

    /// Get a color from the palette at a given index (wraps around)
    ///
    /// - Parameter index: The index to retrieve
    /// - Returns: A color from the palette
    public func color(at index: Int) -> Color {
        guard !palette.isEmpty else { return accentColor }
        return palette[index % palette.count]
    }
    
    /// Get multiple colors from the palette
    ///
    /// - Parameter count: Number of colors needed
    /// - Returns: An array of colors
    public func colors(count: Int) -> [Color] {
        (0..<count).map { color(at: $0) }
    }

    // MARK: - Preset Themes

    /// Default theme with standard colors
    public static let `default` = ChartTheme()
    
    /// Dark theme optimized for dark backgrounds
    public static let dark = ChartTheme(
        backgroundColor: Color(.systemGray6),
        foregroundColor: .white,
        accentColor: .cyan,
        gridColor: Color.gray.opacity(0.15),
        palette: [.cyan, .mint, .yellow, .pink, .orange, .purple, .green, .red]
    )
    
    /// Light theme for bright interfaces
    public static let light = ChartTheme(
        backgroundColor: .white,
        foregroundColor: .black,
        accentColor: .blue,
        gridColor: Color.gray.opacity(0.25),
        palette: [.blue, .indigo, .purple, .pink, .red, .orange, .yellow, .green]
    )

    /// Pastel theme with soft colors
    public static let pastel = ChartTheme(
        palette: [
            Color(red: 0.6, green: 0.8, blue: 1.0),
            Color(red: 0.6, green: 1.0, blue: 0.8),
            Color(red: 1.0, green: 0.8, blue: 0.6),
            Color(red: 0.9, green: 0.7, blue: 1.0),
            Color(red: 1.0, green: 0.7, blue: 0.7),
            Color(red: 0.7, green: 0.9, blue: 0.7),
            Color(red: 1.0, green: 0.9, blue: 0.6),
            Color(red: 0.8, green: 0.8, blue: 1.0)
        ]
    )
    
    /// Vibrant theme with saturated colors
    public static let vibrant = ChartTheme(
        accentColor: .orange,
        palette: [
            Color(red: 1.0, green: 0.4, blue: 0.4),
            Color(red: 1.0, green: 0.7, blue: 0.2),
            Color(red: 0.4, green: 0.9, blue: 0.4),
            Color(red: 0.3, green: 0.7, blue: 1.0),
            Color(red: 0.8, green: 0.4, blue: 1.0),
            Color(red: 1.0, green: 0.5, blue: 0.7),
            Color(red: 0.2, green: 0.9, blue: 0.8),
            Color(red: 1.0, green: 0.6, blue: 0.0)
        ]
    )
    
    /// Monochrome theme using shades of a single color
    public static let monochrome = ChartTheme(
        accentColor: .blue,
        palette: [
            Color.blue.opacity(1.0),
            Color.blue.opacity(0.8),
            Color.blue.opacity(0.6),
            Color.blue.opacity(0.4),
            Color.blue.opacity(0.3),
            Color.blue.opacity(0.2),
            Color.blue.opacity(0.15),
            Color.blue.opacity(0.1)
        ]
    )
    
    /// Ocean theme with blue-green colors
    public static let ocean = ChartTheme(
        accentColor: .teal,
        palette: [
            Color(red: 0.0, green: 0.6, blue: 0.8),
            Color(red: 0.0, green: 0.8, blue: 0.7),
            Color(red: 0.2, green: 0.5, blue: 0.7),
            Color(red: 0.0, green: 0.7, blue: 0.5),
            Color(red: 0.3, green: 0.7, blue: 0.9),
            Color(red: 0.1, green: 0.6, blue: 0.6),
            Color(red: 0.4, green: 0.8, blue: 0.8),
            Color(red: 0.0, green: 0.5, blue: 0.6)
        ]
    )
    
    /// Sunset theme with warm colors
    public static let sunset = ChartTheme(
        accentColor: .orange,
        palette: [
            Color(red: 1.0, green: 0.4, blue: 0.3),
            Color(red: 1.0, green: 0.6, blue: 0.2),
            Color(red: 1.0, green: 0.8, blue: 0.4),
            Color(red: 0.9, green: 0.5, blue: 0.5),
            Color(red: 0.8, green: 0.4, blue: 0.6),
            Color(red: 1.0, green: 0.5, blue: 0.0),
            Color(red: 0.9, green: 0.3, blue: 0.4),
            Color(red: 1.0, green: 0.7, blue: 0.5)
        ]
    )
    
    /// Forest theme with green colors
    public static let forest = ChartTheme(
        accentColor: .green,
        palette: [
            Color(red: 0.2, green: 0.6, blue: 0.3),
            Color(red: 0.4, green: 0.7, blue: 0.4),
            Color(red: 0.3, green: 0.5, blue: 0.3),
            Color(red: 0.5, green: 0.8, blue: 0.5),
            Color(red: 0.1, green: 0.5, blue: 0.2),
            Color(red: 0.6, green: 0.8, blue: 0.4),
            Color(red: 0.3, green: 0.6, blue: 0.4),
            Color(red: 0.4, green: 0.6, blue: 0.3)
        ]
    )

    public static func == (lhs: ChartTheme, rhs: ChartTheme) -> Bool {
        lhs.animationDuration == rhs.animationDuration &&
        lhs.palette.count == rhs.palette.count &&
        lhs.cornerRadius == rhs.cornerRadius
    }
}

// MARK: - Environment Key

private struct ChartThemeKey: EnvironmentKey {
    static let defaultValue = ChartTheme.default
}

public extension EnvironmentValues {
    /// The current chart theme
    var chartTheme: ChartTheme {
        get { self[ChartThemeKey.self] }
        set { self[ChartThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier

public extension View {
    /// Applies a chart theme to this view and its descendants.
    ///
    /// - Parameter theme: The theme to apply
    /// - Returns: A view with the theme applied
    func chartTheme(_ theme: ChartTheme) -> some View {
        environment(\.chartTheme, theme)
    }
}

// MARK: - Theme Builder

/// A builder for creating custom themes fluently.
///
/// ```swift
/// let theme = ChartThemeBuilder()
///     .backgroundColor(.black)
///     .accentColor(.cyan)
///     .palette([.cyan, .mint, .teal])
///     .build()
/// ```
public struct ChartThemeBuilder {
    private var backgroundColor: Color = .clear
    private var foregroundColor: Color = .primary
    private var accentColor: Color = .blue
    private var gridColor: Color = Color.gray.opacity(0.2)
    private var palette: [Color] = [.blue, .green, .orange, .purple, .red, .cyan, .mint, .indigo]
    private var font: Font = .system(size: 12)
    private var titleFont: Font = .headline
    private var animationDuration: Double = 0.5
    private var cornerRadius: CGFloat = 8
    private var shadowRadius: CGFloat = 4
    private var selectionBorderWidth: CGFloat = 2
    
    public init() {}
    
    public func backgroundColor(_ color: Color) -> ChartThemeBuilder {
        var builder = self
        builder.backgroundColor = color
        return builder
    }
    
    public func foregroundColor(_ color: Color) -> ChartThemeBuilder {
        var builder = self
        builder.foregroundColor = color
        return builder
    }
    
    public func accentColor(_ color: Color) -> ChartThemeBuilder {
        var builder = self
        builder.accentColor = color
        return builder
    }
    
    public func gridColor(_ color: Color) -> ChartThemeBuilder {
        var builder = self
        builder.gridColor = color
        return builder
    }
    
    public func palette(_ colors: [Color]) -> ChartThemeBuilder {
        var builder = self
        builder.palette = colors
        return builder
    }
    
    public func font(_ font: Font) -> ChartThemeBuilder {
        var builder = self
        builder.font = font
        return builder
    }
    
    public func titleFont(_ font: Font) -> ChartThemeBuilder {
        var builder = self
        builder.titleFont = font
        return builder
    }
    
    public func animationDuration(_ duration: Double) -> ChartThemeBuilder {
        var builder = self
        builder.animationDuration = duration
        return builder
    }
    
    public func cornerRadius(_ radius: CGFloat) -> ChartThemeBuilder {
        var builder = self
        builder.cornerRadius = radius
        return builder
    }
    
    public func shadowRadius(_ radius: CGFloat) -> ChartThemeBuilder {
        var builder = self
        builder.shadowRadius = radius
        return builder
    }
    
    public func selectionBorderWidth(_ width: CGFloat) -> ChartThemeBuilder {
        var builder = self
        builder.selectionBorderWidth = width
        return builder
    }
    
    /// Builds the final theme
    public func build() -> ChartTheme {
        ChartTheme(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            accentColor: accentColor,
            gridColor: gridColor,
            palette: palette,
            font: font,
            titleFont: titleFont,
            animationDuration: animationDuration,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            selectionBorderWidth: selectionBorderWidth
        )
    }
}
