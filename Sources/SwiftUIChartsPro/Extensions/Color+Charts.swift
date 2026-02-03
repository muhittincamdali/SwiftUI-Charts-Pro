import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Color Extensions for Charts

public extension Color {
    
    // MARK: - Component Access
    
    /// Returns the RGBA components of the color.
    var components: (red: Double, green: Double, blue: Double, alpha: Double) {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (Double(red), Double(green), Double(blue), Double(alpha))
        #else
        return (0.5, 0.5, 0.5, 1.0)
        #endif
    }
    
    /// Returns the HSL components of the color.
    var hslComponents: (hue: Double, saturation: Double, lightness: Double) {
        #if canImport(UIKit)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Convert HSB to HSL
        let lightness = (2 - saturation) * brightness / 2
        let s: CGFloat
        if lightness == 0 || lightness == 1 {
            s = 0
        } else if lightness < 0.5 {
            s = saturation * brightness / (lightness * 2)
        } else {
            s = saturation * brightness / (2 - lightness * 2)
        }
        
        return (Double(hue), Double(s), Double(lightness))
        #else
        return (0.5, 0.5, 0.5)
        #endif
    }
    
    /// The perceived brightness of the color (0-1).
    var luminance: Double {
        let c = components
        return 0.299 * c.red + 0.587 * c.green + 0.114 * c.blue
    }
    
    /// Whether the color is considered dark.
    var isDark: Bool {
        luminance < 0.5
    }
    
    /// Whether the color is considered light.
    var isLight: Bool {
        !isDark
    }
    
    // MARK: - Color Manipulation
    
    /// Returns a lighter version of the color.
    func lighter(by amount: Double = 0.2) -> Color {
        adjust(lightness: amount)
    }
    
    /// Returns a darker version of the color.
    func darker(by amount: Double = 0.2) -> Color {
        adjust(lightness: -amount)
    }
    
    /// Returns a more saturated version of the color.
    func saturated(by amount: Double = 0.2) -> Color {
        adjust(saturation: amount)
    }
    
    /// Returns a less saturated version of the color.
    func desaturated(by amount: Double = 0.2) -> Color {
        adjust(saturation: -amount)
    }
    
    /// Adjusts the color's lightness and saturation.
    func adjust(lightness: Double = 0, saturation: Double = 0) -> Color {
        let hsl = hslComponents
        let newL = max(0, min(1, hsl.lightness + lightness))
        let newS = max(0, min(1, hsl.saturation + saturation))
        
        return Color(hue: hsl.hue, saturation: newS, brightness: newL)
    }
    
    /// Returns the complementary color.
    var complementary: Color {
        let hsl = hslComponents
        let newHue = (hsl.hue + 0.5).truncatingRemainder(dividingBy: 1.0)
        return Color(hue: newHue, saturation: hsl.saturation, brightness: hsl.lightness)
    }
    
    /// Returns analogous colors.
    func analogous(angle: Double = 30) -> (Color, Color) {
        let hsl = hslComponents
        let angleNormalized = angle / 360
        
        let hue1 = (hsl.hue + angleNormalized).truncatingRemainder(dividingBy: 1.0)
        let hue2 = (hsl.hue - angleNormalized + 1).truncatingRemainder(dividingBy: 1.0)
        
        return (
            Color(hue: hue1, saturation: hsl.saturation, brightness: hsl.lightness),
            Color(hue: hue2, saturation: hsl.saturation, brightness: hsl.lightness)
        )
    }
    
    /// Returns triadic colors.
    var triadic: (Color, Color) {
        let hsl = hslComponents
        
        let hue1 = (hsl.hue + 1/3).truncatingRemainder(dividingBy: 1.0)
        let hue2 = (hsl.hue + 2/3).truncatingRemainder(dividingBy: 1.0)
        
        return (
            Color(hue: hue1, saturation: hsl.saturation, brightness: hsl.lightness),
            Color(hue: hue2, saturation: hsl.saturation, brightness: hsl.lightness)
        )
    }
    
    /// Blends this color with another color.
    func blend(with color: Color, ratio: Double = 0.5) -> Color {
        let c1 = components
        let c2 = color.components
        let t = max(0, min(1, ratio))
        
        return Color(
            red: c1.red + (c2.red - c1.red) * t,
            green: c1.green + (c2.green - c1.green) * t,
            blue: c1.blue + (c2.blue - c1.blue) * t,
            opacity: c1.alpha + (c2.alpha - c1.alpha) * t
        )
    }
    
    // MARK: - Contrast Colors
    
    /// Returns a contrasting color suitable for text.
    var contrastingTextColor: Color {
        isDark ? .white : .black
    }
    
    /// Returns a contrasting color with the given minimum contrast ratio.
    func contrasting(minimumRatio: Double = 4.5) -> Color {
        let white = Color.white
        let black = Color.black
        
        let whiteContrast = contrastRatio(with: white)
        let blackContrast = contrastRatio(with: black)
        
        if whiteContrast >= minimumRatio && whiteContrast >= blackContrast {
            return white
        } else if blackContrast >= minimumRatio {
            return black
        }
        
        // If neither meets the ratio, return the one with better contrast
        return whiteContrast > blackContrast ? white : black
    }
    
    /// Calculates the contrast ratio with another color.
    func contrastRatio(with color: Color) -> Double {
        let l1 = max(luminance, color.luminance)
        let l2 = min(luminance, color.luminance)
        return (l1 + 0.05) / (l2 + 0.05)
    }
    
    // MARK: - Palette Generation
    
    /// Generates a monochromatic palette.
    func monochromatic(count: Int) -> [Color] {
        guard count > 0 else { return [] }
        
        var colors: [Color] = []
        let step = 1.0 / Double(count + 1)
        
        for i in 1...count {
            let lightness = step * Double(i) - 0.5
            colors.append(adjust(lightness: lightness))
        }
        
        return colors
    }
    
    /// Generates an opacity-based palette.
    func opacityPalette(count: Int) -> [Color] {
        guard count > 0 else { return [] }
        
        return (1...count).map { i in
            self.opacity(Double(i) / Double(count))
        }
    }
    
    // MARK: - Chart-Specific Palettes
    
    /// Default chart color palette.
    static var chartPalette: [Color] {
        [.blue, .green, .orange, .purple, .red, .cyan, .mint, .indigo, .yellow, .pink]
    }
    
    /// Sequential color palette (light to dark of a single hue).
    static func sequentialPalette(hue: Color, count: Int) -> [Color] {
        guard count > 0 else { return [] }
        
        return (0..<count).map { i in
            let ratio = Double(i) / Double(count - 1)
            return hue.adjust(lightness: 0.3 - ratio * 0.5)
        }
    }
    
    /// Diverging color palette (two hues meeting at a neutral middle).
    static func divergingPalette(from: Color, to: Color, count: Int) -> [Color] {
        guard count > 0 else { return [] }
        
        let midpoint = count / 2
        var colors: [Color] = []
        
        for i in 0..<count {
            if i < midpoint {
                let ratio = Double(i) / Double(midpoint)
                colors.append(from.adjust(lightness: 0.3 - ratio * 0.3))
            } else if i == midpoint && count % 2 == 1 {
                colors.append(Color.gray.opacity(0.5))
            } else {
                let ratio = Double(i - midpoint) / Double(count - midpoint - 1)
                colors.append(to.adjust(lightness: -0.3 + ratio * 0.3))
            }
        }
        
        return colors
    }
    
    /// Categorical color palette with maximum visual distinction.
    static func categoricalPalette(count: Int) -> [Color] {
        guard count > 0 else { return [] }
        
        let goldenAngle = 137.508 / 360.0 // Golden angle for optimal distribution
        
        return (0..<count).map { i in
            let hue = (Double(i) * goldenAngle).truncatingRemainder(dividingBy: 1.0)
            return Color(hue: hue, saturation: 0.7, brightness: 0.8)
        }
    }
    
    // MARK: - Hex Conversion
    
    /// Creates a color from a hex string.
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        guard hexString.count == 6 || hexString.count == 8 else { return nil }
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgb) else { return nil }
        
        if hexString.count == 6 {
            self.init(
                red: Double((rgb >> 16) & 0xFF) / 255.0,
                green: Double((rgb >> 8) & 0xFF) / 255.0,
                blue: Double(rgb & 0xFF) / 255.0
            )
        } else {
            self.init(
                red: Double((rgb >> 24) & 0xFF) / 255.0,
                green: Double((rgb >> 16) & 0xFF) / 255.0,
                blue: Double((rgb >> 8) & 0xFF) / 255.0,
                opacity: Double(rgb & 0xFF) / 255.0
            )
        }
    }
    
    /// Returns the hex string representation of the color.
    var hexString: String {
        let c = components
        let r = Int(c.red * 255)
        let g = Int(c.green * 255)
        let b = Int(c.blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Gradient Extensions

public extension LinearGradient {
    
    /// Creates a chart-friendly linear gradient.
    static func chartGradient(colors: [Color], direction: GradientDirection = .vertical) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: direction.startPoint,
            endPoint: direction.endPoint
        )
    }
}

/// Gradient direction helper.
public enum GradientDirection {
    case vertical
    case horizontal
    case diagonal
    case reverseDiagonal
    
    var startPoint: UnitPoint {
        switch self {
        case .vertical: return .top
        case .horizontal: return .leading
        case .diagonal: return .topLeading
        case .reverseDiagonal: return .topTrailing
        }
    }
    
    var endPoint: UnitPoint {
        switch self {
        case .vertical: return .bottom
        case .horizontal: return .trailing
        case .diagonal: return .bottomTrailing
        case .reverseDiagonal: return .bottomLeading
        }
    }
}

// MARK: - Preview

#if DEBUG
struct Color_Charts_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Original and lighter/darker
            HStack {
                Color.blue
                Color.blue.lighter()
                Color.blue.darker()
            }
            .frame(height: 50)
            
            // Complementary
            HStack {
                Color.orange
                Color.orange.complementary
            }
            .frame(height: 50)
            
            // Categorical palette
            HStack(spacing: 2) {
                ForEach(Color.categoricalPalette(count: 8), id: \.self) { color in
                    color
                }
            }
            .frame(height: 50)
            
            // Sequential palette
            HStack(spacing: 2) {
                ForEach(Color.sequentialPalette(hue: .blue, count: 6), id: \.self) { color in
                    color
                }
            }
            .frame(height: 50)
        }
        .padding()
    }
}
#endif
