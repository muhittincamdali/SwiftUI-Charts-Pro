import SwiftUI

// MARK: - Chart Theme

/// Configuration for chart visual styling
public struct ChartTheme: Equatable {
    public let backgroundColor: Color
    public let foregroundColor: Color
    public let accentColor: Color
    public let gridColor: Color
    public let palette: [Color]
    public let font: Font
    public let titleFont: Font
    public let animationDuration: Double

    public init(
        backgroundColor: Color = .clear,
        foregroundColor: Color = .primary,
        accentColor: Color = .blue,
        gridColor: Color = Color.gray.opacity(0.2),
        palette: [Color] = [.blue, .green, .orange, .purple, .red, .cyan, .mint, .indigo],
        font: Font = .system(size: 12),
        titleFont: Font = .headline,
        animationDuration: Double = 0.5
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.accentColor = accentColor
        self.gridColor = gridColor
        self.palette = palette
        self.font = font
        self.titleFont = titleFont
        self.animationDuration = animationDuration
    }

    /// Get a color from the palette at a given index (wraps around)
    public func color(at index: Int) -> Color {
        palette[index % palette.count]
    }

    // MARK: - Preset Themes

    public static let `default` = ChartTheme()

    public static let dark = ChartTheme(
        backgroundColor: Color(.systemGray6),
        foregroundColor: .white,
        accentColor: .cyan,
        gridColor: Color.gray.opacity(0.15),
        palette: [.cyan, .mint, .yellow, .pink, .orange, .purple]
    )

    public static let pastel = ChartTheme(
        palette: [
            Color(red: 0.6, green: 0.8, blue: 1.0),
            Color(red: 0.6, green: 1.0, blue: 0.8),
            Color(red: 1.0, green: 0.8, blue: 0.6),
            Color(red: 0.9, green: 0.7, blue: 1.0),
            Color(red: 1.0, green: 0.7, blue: 0.7)
        ]
    )

    public static func == (lhs: ChartTheme, rhs: ChartTheme) -> Bool {
        lhs.animationDuration == rhs.animationDuration &&
        lhs.palette.count == rhs.palette.count
    }
}
