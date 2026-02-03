import SwiftUI

// MARK: - Chart Accessibility

/// Accessibility utilities and modifiers for charts.
///
/// These utilities help make charts accessible to users of assistive technologies
/// by providing meaningful labels, hints, and navigation support.

// MARK: - Accessibility Label Builder

/// Builds accessibility labels for chart elements.
public struct ChartAccessibilityLabel {
    
    /// Creates an accessibility label for a data point.
    public static func forDataPoint(
        label: String,
        value: Double,
        format: String = "%.2f",
        unit: String = "",
        context: String? = nil
    ) -> String {
        var result = "\(label): \(String(format: format, value))\(unit)"
        if let context = context {
            result += ", \(context)"
        }
        return result
    }
    
    /// Creates an accessibility label for a percentage.
    public static func forPercentage(
        label: String,
        percentage: Double,
        of total: String? = nil
    ) -> String {
        var result = "\(label): \(String(format: "%.1f", percentage)) percent"
        if let total = total {
            result += " of \(total)"
        }
        return result
    }
    
    /// Creates an accessibility label for a trend.
    public static func forTrend(
        label: String,
        currentValue: Double,
        previousValue: Double,
        format: String = "%.2f"
    ) -> String {
        let change = currentValue - previousValue
        let percentChange = previousValue != 0 ? (change / previousValue) * 100 : 0
        let direction = change >= 0 ? "increased" : "decreased"
        
        return "\(label): \(String(format: format, currentValue)), \(direction) by \(String(format: "%.1f", abs(percentChange))) percent"
    }
    
    /// Creates an accessibility label for a range.
    public static func forRange(
        label: String,
        low: Double,
        high: Double,
        format: String = "%.2f"
    ) -> String {
        "\(label): from \(String(format: format, low)) to \(String(format: format, high))"
    }
    
    /// Creates a summary label for a chart.
    public static func forChartSummary(
        chartType: String,
        dataPointCount: Int,
        seriesCount: Int = 1,
        additionalInfo: String? = nil
    ) -> String {
        var result = "\(chartType) with \(dataPointCount) data points"
        if seriesCount > 1 {
            result += " across \(seriesCount) series"
        }
        if let info = additionalInfo {
            result += ". \(info)"
        }
        return result
    }
}

// MARK: - Accessibility Hint Builder

/// Builds accessibility hints for interactive chart elements.
public struct ChartAccessibilityHint {
    
    /// Hint for selectable elements
    public static let selectable = "Double tap to select"
    
    /// Hint for expandable elements
    public static let expandable = "Double tap to expand"
    
    /// Hint for zoomable charts
    public static let zoomable = "Pinch to zoom, double tap to reset"
    
    /// Hint for draggable elements
    public static let draggable = "Use drag gesture to adjust value"
    
    /// Hint for navigable charts
    public static let navigable = "Swipe left or right to navigate between data points"
    
    /// Creates a custom hint.
    public static func custom(_ action: String) -> String {
        action
    }
}

// MARK: - Chart Accessibility Modifier

/// A view modifier that adds comprehensive accessibility support to charts.
public struct ChartAccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let isElement: Bool
    let sortPriority: Double
    let customActions: [AccessibilityCustomAction]
    
    public init(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isElement: Bool = true,
        sortPriority: Double = 0,
        customActions: [AccessibilityCustomAction] = []
    ) {
        self.label = label
        self.hint = hint
        self.value = value
        self.traits = traits
        self.isElement = isElement
        self.sortPriority = sortPriority
        self.customActions = customActions
    }
    
    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: isElement ? .ignore : .contain)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            .accessibilitySortPriority(sortPriority)
            .accessibilityActions {
                ForEach(customActions, id: \.name) { action in
                    Button(action.name) {
                        _ = action.handler()
                    }
                }
            }
    }
}

/// A custom accessibility action.
public struct AccessibilityCustomAction: Identifiable {
    public let id = UUID()
    public let name: String
    public let handler: () -> Bool
    
    public init(name: String, handler: @escaping () -> Bool) {
        self.name = name
        self.handler = handler
    }
}

public extension View {
    /// Adds chart accessibility support to this view.
    func chartAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        customActions: [AccessibilityCustomAction] = []
    ) -> some View {
        modifier(ChartAccessibilityModifier(
            label: label,
            hint: hint,
            value: value,
            traits: traits,
            customActions: customActions
        ))
    }
}

// MARK: - Accessibility Rotor Support

/// A collection of data points for accessibility rotor navigation.
public struct ChartAccessibilityRotor<ID: Hashable>: View {
    let title: String
    let items: [(id: ID, label: String, namespace: Namespace.ID)]
    
    public init(
        title: String,
        items: [(id: ID, label: String, namespace: Namespace.ID)]
    ) {
        self.title = title
        self.items = items
    }
    
    public var body: some View {
        EmptyView()
            .accessibilityRotor(title) {
                ForEach(items, id: \.id) { item in
                    AccessibilityRotorEntry(item.label, id: item.id, in: item.namespace)
                }
            }
    }
}

// MARK: - Audio Graph Support

/// Configuration for audio graph representation of chart data.
public struct AudioGraphConfiguration {
    /// Minimum pitch (Hz)
    public let minPitch: Double
    
    /// Maximum pitch (Hz)
    public let maxPitch: Double
    
    /// Duration per data point (seconds)
    public let noteDuration: Double
    
    /// Pause between notes (seconds)
    public let pauseDuration: Double
    
    /// Creates an audio graph configuration.
    public init(
        minPitch: Double = 200,
        maxPitch: Double = 800,
        noteDuration: Double = 0.3,
        pauseDuration: Double = 0.1
    ) {
        self.minPitch = minPitch
        self.maxPitch = maxPitch
        self.noteDuration = noteDuration
        self.pauseDuration = pauseDuration
    }
    
    /// Calculates the pitch for a normalized value (0-1).
    public func pitch(for normalizedValue: Double) -> Double {
        minPitch + (maxPitch - minPitch) * normalizedValue
    }
}

// MARK: - Chart Description Generator

/// Generates human-readable descriptions of chart data.
public struct ChartDescriptionGenerator {
    
    /// Generates a description for a line chart.
    public static func describeLineChart(
        title: String,
        dataPoints: [Double],
        labels: [String]? = nil
    ) -> String {
        guard !dataPoints.isEmpty else {
            return "\(title): No data available"
        }
        
        let min = dataPoints.min() ?? 0
        let max = dataPoints.max() ?? 0
        let avg = dataPoints.reduce(0, +) / Double(dataPoints.count)
        
        let trend: String
        if let first = dataPoints.first, let last = dataPoints.last {
            if last > first * 1.05 {
                trend = "showing an upward trend"
            } else if last < first * 0.95 {
                trend = "showing a downward trend"
            } else {
                trend = "relatively stable"
            }
        } else {
            trend = ""
        }
        
        return """
        \(title): Line chart with \(dataPoints.count) data points, \
        ranging from \(String(format: "%.1f", min)) to \(String(format: "%.1f", max)), \
        with an average of \(String(format: "%.1f", avg)), \(trend).
        """
    }
    
    /// Generates a description for a pie/donut chart.
    public static func describePieChart(
        title: String,
        segments: [(label: String, value: Double)]
    ) -> String {
        guard !segments.isEmpty else {
            return "\(title): No data available"
        }
        
        let total = segments.reduce(0) { $0 + $1.value }
        let sortedSegments = segments.sorted { $0.value > $1.value }
        
        var description = "\(title): Pie chart with \(segments.count) segments. "
        
        // Describe top segments
        let topSegments = sortedSegments.prefix(3)
        let descriptions = topSegments.map { segment in
            let percentage = total > 0 ? (segment.value / total) * 100 : 0
            return "\(segment.label) at \(String(format: "%.1f", percentage)) percent"
        }
        
        description += "Top segments: " + descriptions.joined(separator: ", ")
        
        if segments.count > 3 {
            description += ", and \(segments.count - 3) more."
        } else {
            description += "."
        }
        
        return description
    }
    
    /// Generates a description for a bar chart.
    public static func describeBarChart(
        title: String,
        bars: [(label: String, value: Double)]
    ) -> String {
        guard !bars.isEmpty else {
            return "\(title): No data available"
        }
        
        let sorted = bars.sorted { $0.value > $1.value }
        let highest = sorted.first!
        let lowest = sorted.last!
        
        return """
        \(title): Bar chart with \(bars.count) bars. \
        Highest value is \(highest.label) at \(String(format: "%.1f", highest.value)). \
        Lowest value is \(lowest.label) at \(String(format: "%.1f", lowest.value)).
        """
    }
}

// MARK: - VoiceOver Announcement Helper

/// Helper for making VoiceOver announcements.
public struct VoiceOverAnnouncement {
    
    /// Announces a message via VoiceOver.
    public static func announce(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
    
    /// Announces a screen change.
    public static func announceScreenChange(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .screenChanged, argument: message)
        #endif
    }
    
    /// Announces a layout change.
    public static func announceLayoutChange(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .layoutChanged, argument: message)
        #endif
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ChartAccessibility_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Accessibility Demo")
                .chartAccessibility(
                    label: "Sales Chart",
                    hint: ChartAccessibilityHint.selectable,
                    value: "Showing January to December 2024"
                )
            
            Text(ChartAccessibilityLabel.forDataPoint(
                label: "Revenue",
                value: 15000,
                unit: " USD",
                context: "Q1 2024"
            ))
        }
        .padding()
    }
}
#endif
