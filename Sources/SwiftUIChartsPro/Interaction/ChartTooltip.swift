import SwiftUI

// MARK: - Chart Tooltip

/// A customizable tooltip view for displaying chart data details.
///
/// Tooltips provide contextual information when users interact with chart elements.
///
/// ```swift
/// ChartTooltip(
///     title: "Sales",
///     value: 1500,
///     subtitle: "January 2024"
/// )
/// ```
public struct ChartTooltip: View {
    @Environment(\.chartTheme) private var theme
    
    /// The tooltip title
    public let title: String
    
    /// The main value to display
    public let value: Double
    
    /// Optional subtitle
    public let subtitle: String?
    
    /// Optional color indicator
    public let color: Color?
    
    /// Value format string
    public let valueFormat: String
    
    /// Unit suffix
    public let unit: String
    
    /// Additional key-value pairs
    public let details: [(String, String)]
    
    /// Tooltip style
    public let style: TooltipStyle
    
    /// Arrow direction
    public let arrowDirection: ArrowDirection
    
    /// Creates a chart tooltip.
    public init(
        title: String,
        value: Double,
        subtitle: String? = nil,
        color: Color? = nil,
        valueFormat: String = "%.2f",
        unit: String = "",
        details: [(String, String)] = [],
        style: TooltipStyle = .material,
        arrowDirection: ArrowDirection = .bottom
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.valueFormat = valueFormat
        self.unit = unit
        self.details = details
        self.style = style
        self.arrowDirection = arrowDirection
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                if let color = color {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                }
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(textColor)
            }
            
            // Value
            Text("\(String(format: valueFormat, value))\(unit)")
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(valueColor)
            
            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(subtitleColor)
            }
            
            // Additional details
            if !details.isEmpty {
                Divider()
                    .background(dividerColor)
                
                ForEach(details, id: \.0) { key, value in
                    HStack {
                        Text(key)
                            .foregroundColor(subtitleColor)
                        Spacer()
                        Text(value)
                            .foregroundColor(textColor)
                    }
                    .font(.caption2)
                }
            }
        }
        .padding(10)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(arrow, alignment: arrowAlignment)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
    }
    
    // MARK: - Style Properties
    
    private var background: some View {
        Group {
            switch style {
            case .material:
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            case .solid(let color):
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
            case .gradient(let colors):
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            case .themed:
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.gridColor, lineWidth: 1)
                    )
            }
        }
    }
    
    private var textColor: Color {
        switch style {
        case .material, .themed:
            return theme.foregroundColor
        case .solid(let bgColor):
            return bgColor.isDark ? .white : .black
        case .gradient:
            return .white
        }
    }
    
    private var valueColor: Color {
        color ?? theme.accentColor
    }
    
    private var subtitleColor: Color {
        textColor.opacity(0.7)
    }
    
    private var dividerColor: Color {
        textColor.opacity(0.2)
    }
    
    private var shadowColor: Color {
        Color.black.opacity(0.15)
    }
    
    private var shadowRadius: CGFloat {
        style == .material ? 8 : 4
    }
    
    // MARK: - Arrow
    
    @ViewBuilder
    private var arrow: some View {
        if arrowDirection != .none {
            ArrowShape(direction: arrowDirection)
                .fill(arrowColor)
                .frame(width: 12, height: 8)
                .offset(arrowOffset)
        }
    }
    
    private var arrowColor: Color {
        switch style {
        case .material:
            return Color.gray.opacity(0.3)
        case .solid(let color):
            return color
        case .gradient(let colors):
            return colors.first ?? .clear
        case .themed:
            return theme.backgroundColor
        }
    }
    
    private var arrowAlignment: Alignment {
        switch arrowDirection {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        case .none: return .center
        }
    }
    
    private var arrowOffset: CGSize {
        switch arrowDirection {
        case .top: return CGSize(width: 0, height: -8)
        case .bottom: return CGSize(width: 0, height: 8)
        case .leading: return CGSize(width: -8, height: 0)
        case .trailing: return CGSize(width: 8, height: 0)
        case .none: return .zero
        }
    }
}

// MARK: - Arrow Shape

private struct ArrowShape: Shape {
    let direction: ArrowDirection
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch direction {
        case .top:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .bottom:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        case .leading:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .trailing:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .none:
            break
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Supporting Types

/// Tooltip visual style
public enum TooltipStyle {
    /// Material blur background
    case material
    
    /// Solid color background
    case solid(Color)
    
    /// Gradient background
    case gradient([Color])
    
    /// Uses chart theme colors
    case themed
}

/// Arrow direction for tooltips
public enum ArrowDirection {
    case top
    case bottom
    case leading
    case trailing
    case none
}

// MARK: - Color Extension

private extension Color {
    var isDark: Bool {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance < 0.5
        #else
        return true
        #endif
    }
}

// MARK: - Tooltip Position Modifier

/// A view modifier that positions a tooltip relative to an anchor point.
public struct TooltipPositionModifier: ViewModifier {
    let anchor: CGPoint
    let offset: CGSize
    let isVisible: Bool
    
    public func body(content: Content) -> some View {
        content
            .position(x: anchor.x + offset.width, y: anchor.y + offset.height)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
    }
}

public extension View {
    /// Positions the tooltip at the specified anchor with optional offset.
    func tooltipPosition(anchor: CGPoint, offset: CGSize = .zero, isVisible: Bool = true) -> some View {
        modifier(TooltipPositionModifier(anchor: anchor, offset: offset, isVisible: isVisible))
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ChartTooltip_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ChartTooltip(
                title: "Revenue",
                value: 15234.56,
                subtitle: "Q1 2024",
                color: .blue,
                unit: " USD",
                details: [
                    ("Growth", "+12.5%"),
                    ("Target", "14,000 USD")
                ]
            )
            
            ChartTooltip(
                title: "Users",
                value: 1500,
                color: .green,
                valueFormat: "%.0f",
                style: .solid(.black),
                arrowDirection: .top
            )
            
            ChartTooltip(
                title: "Conversion",
                value: 3.45,
                unit: "%",
                style: .gradient([.purple, .pink]),
                arrowDirection: .none
            )
        }
        .padding()
    }
}
#endif
