import SwiftUI

// MARK: - Chart Accessibility

/// Comprehensive accessibility support for charts.
///
/// This module provides:
/// - VoiceOver descriptions for all chart types
/// - Rotor support for navigating data points
/// - Audio graphs for visually impaired users
/// - High contrast mode support
/// - Reduced motion alternatives
///
/// ```swift
/// LineChart(data: data)
///     .chartAccessibility(
///         label: "Revenue over time",
///         summary: "Shows monthly revenue from January to December"
///     )
/// ```

// MARK: - Accessibility Configuration

/// Configuration for chart accessibility features.
public struct ChartAccessibilityConfiguration {
    /// The main accessibility label
    public var label: String
    
    /// A summary description of the chart
    public var summary: String?
    
    /// Custom descriptions for each data point
    public var pointDescriptions: [String]?
    
    /// Whether to enable audio representation
    public var enableAudioGraph: Bool
    
    /// Whether to announce value changes
    public var announceChanges: Bool
    
    /// Custom value formatter for VoiceOver
    public var valueFormatter: ((Double) -> String)?
    
    /// Custom trend description
    public var trendDescription: String?
    
    public init(
        label: String,
        summary: String? = nil,
        pointDescriptions: [String]? = nil,
        enableAudioGraph: Bool = false,
        announceChanges: Bool = true,
        valueFormatter: ((Double) -> String)? = nil,
        trendDescription: String? = nil
    ) {
        self.label = label
        self.summary = summary
        self.pointDescriptions = pointDescriptions
        self.enableAudioGraph = enableAudioGraph
        self.announceChanges = announceChanges
        self.valueFormatter = valueFormatter
        self.trendDescription = trendDescription
    }
}

// MARK: - Accessibility Modifier

/// A view modifier that adds comprehensive accessibility support to charts.
public struct ChartAccessibilityModifier: ViewModifier {
    let configuration: ChartAccessibilityConfiguration
    let dataPoints: [AccessibleDataPoint]
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    
    public init(
        configuration: ChartAccessibilityConfiguration,
        dataPoints: [AccessibleDataPoint] = []
    ) {
        self.configuration = configuration
        self.dataPoints = dataPoints
    }
    
    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel(configuration.label)
            .accessibilityHint(configuration.summary ?? "")
            .accessibilityValue(buildValueDescription())
            .accessibilityAddTraits(.isImage)
            .accessibilityCustomContent("Trend", configuration.trendDescription ?? "")
            .accessibilityAction(named: "Read all values") {
                announceAllValues()
            }
    }
    
    private func buildValueDescription() -> String {
        guard !dataPoints.isEmpty else { return "" }
        
        var description = ""
        
        // Summary statistics
        let values = dataPoints.map { $0.value }
        if let min = values.min(), let max = values.max() {
            let formatter = configuration.valueFormatter ?? defaultFormatter
            description += "Range from \(formatter(min)) to \(formatter(max)). "
        }
        
        // Data point count
        description += "\(dataPoints.count) data points. "
        
        // Trend
        if let trend = calculateTrend(values: values) {
            description += trend
        }
        
        return description
    }
    
    private func announceAllValues() {
        let announcement = dataPoints.map { point in
            let formatter = configuration.valueFormatter ?? defaultFormatter
            return "\(point.label): \(formatter(point.value))"
        }.joined(separator: ". ")
        
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: announcement)
        #endif
    }
    
    private func calculateTrend(values: [Double]) -> String? {
        guard values.count >= 2 else { return nil }
        
        let first = values.first!
        let last = values.last!
        let change = last - first
        let percentChange = (change / first) * 100
        
        if abs(percentChange) < 1 {
            return "Stable trend."
        } else if change > 0 {
            return String(format: "Increasing trend, up %.1f%%.", percentChange)
        } else {
            return String(format: "Decreasing trend, down %.1f%%.", abs(percentChange))
        }
    }
    
    private func defaultFormatter(_ value: Double) -> String {
        if abs(value) >= 1_000_000 {
            return String(format: "%.1f million", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "%.1f thousand", value / 1_000)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Accessible Data Point

/// A data point with accessibility information.
public struct AccessibleDataPoint: Identifiable {
    public let id: UUID
    public let label: String
    public let value: Double
    public let customDescription: String?
    
    public init(
        id: UUID = UUID(),
        label: String,
        value: Double,
        customDescription: String? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.customDescription = customDescription
    }
    
    public var accessibilityLabel: String {
        customDescription ?? "\(label): \(String(format: "%.1f", value))"
    }
}

// MARK: - View Extensions

public extension View {
    /// Adds accessibility support to a chart.
    func chartAccessibility(
        label: String,
        summary: String? = nil,
        dataPoints: [AccessibleDataPoint] = []
    ) -> some View {
        modifier(ChartAccessibilityModifier(
            configuration: ChartAccessibilityConfiguration(
                label: label,
                summary: summary
            ),
            dataPoints: dataPoints
        ))
    }
    
    /// Adds full accessibility configuration to a chart.
    func chartAccessibility(configuration: ChartAccessibilityConfiguration, dataPoints: [AccessibleDataPoint] = []) -> some View {
        modifier(ChartAccessibilityModifier(configuration: configuration, dataPoints: dataPoints))
    }
}

// MARK: - Accessible Data Point Container

/// A container that makes chart data points individually accessible.
public struct AccessiblePointsContainer<Content: View>: View {
    let dataPoints: [AccessibleDataPoint]
    let content: Content
    
    @State private var focusedIndex: Int?
    
    public init(
        dataPoints: [AccessibleDataPoint],
        @ViewBuilder content: () -> Content
    ) {
        self.dataPoints = dataPoints
        self.content = content()
    }
    
    public var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    focusedIndex = min((focusedIndex ?? -1) + 1, dataPoints.count - 1)
                    announceCurrentPoint()
                case .decrement:
                    focusedIndex = max((focusedIndex ?? dataPoints.count) - 1, 0)
                    announceCurrentPoint()
                @unknown default:
                    break
                }
            }
    }
    
    private func announceCurrentPoint() {
        guard let index = focusedIndex, index < dataPoints.count else { return }
        let point = dataPoints[index]
        
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: point.accessibilityLabel)
        #endif
    }
}

// MARK: - High Contrast Support

/// A modifier that applies high contrast colors when needed.
public struct HighContrastChartModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    
    let normalColors: [Color]
    let highContrastColors: [Color]
    
    public init(
        normalColors: [Color] = [],
        highContrastColors: [Color] = []
    ) {
        self.normalColors = normalColors
        self.highContrastColors = highContrastColors.isEmpty ? Self.defaultHighContrastPalette : highContrastColors
    }
    
    public func body(content: Content) -> some View {
        content
            .environment(\.chartHighContrastColors, contrast == .increased ? highContrastColors : normalColors)
    }
    
    static let defaultHighContrastPalette: [Color] = [
        .black,
        .white,
        Color(red: 0, green: 0, blue: 0.8),    // High contrast blue
        Color(red: 0.8, green: 0, blue: 0),    // High contrast red
        Color(red: 0, green: 0.6, blue: 0),    // High contrast green
        Color(red: 0.8, green: 0.4, blue: 0),  // High contrast orange
    ]
}

// MARK: - Environment Key for High Contrast Colors

struct ChartHighContrastColorsKey: EnvironmentKey {
    static let defaultValue: [Color] = []
}

extension EnvironmentValues {
    var chartHighContrastColors: [Color] {
        get { self[ChartHighContrastColorsKey.self] }
        set { self[ChartHighContrastColorsKey.self] = newValue }
    }
}

public extension View {
    /// Applies high contrast colors when increased contrast is enabled.
    func chartHighContrast(
        normalColors: [Color] = [],
        highContrastColors: [Color] = []
    ) -> some View {
        modifier(HighContrastChartModifier(
            normalColors: normalColors,
            highContrastColors: highContrastColors
        ))
    }
}

// MARK: - Reduced Motion Support

/// A modifier that respects reduced motion preferences.
public struct ReducedMotionChartModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let normalAnimation: Animation?
    let reducedAnimation: Animation?
    
    public init(
        normalAnimation: Animation? = .easeInOut(duration: 0.5),
        reducedAnimation: Animation? = nil
    ) {
        self.normalAnimation = normalAnimation
        self.reducedAnimation = reducedAnimation
    }
    
    public func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : normalAnimation, value: UUID())
    }
}

public extension View {
    /// Applies reduced motion alternatives when the preference is enabled.
    func chartReducedMotion(
        normalAnimation: Animation? = .easeInOut(duration: 0.5),
        reducedAnimation: Animation? = nil
    ) -> some View {
        modifier(ReducedMotionChartModifier(
            normalAnimation: normalAnimation,
            reducedAnimation: reducedAnimation
        ))
    }
}

// MARK: - Audio Graph

/// Generates audio representations of chart data.
@MainActor
public final class ChartAudioGraph: ObservableObject {
    @Published public private(set) var isPlaying = false
    
    private var dataPoints: [Double] = []
    private var playbackTimer: Timer?
    
    public init() {}
    
    /// Plays an audio representation of the data.
    public func play(dataPoints: [Double], duration: TimeInterval = 2.0) {
        guard !dataPoints.isEmpty else { return }
        
        self.dataPoints = dataPoints
        isPlaying = true
        
        let interval = duration / TimeInterval(dataPoints.count)
        var currentIndex = 0
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self, currentIndex < self.dataPoints.count else {
                timer.invalidate()
                Task { @MainActor in
                    self?.isPlaying = false
                }
                return
            }
            
            let value = self.dataPoints[currentIndex]
            self.playTone(for: value)
            currentIndex += 1
        }
    }
    
    /// Stops playback.
    public func stop() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
    }
    
    private func playTone(for value: Double) {
        // Placeholder for audio generation
        // In a full implementation, this would use AVAudioEngine
        // to generate tones based on the data value
        
        // Map value to frequency (e.g., 200Hz - 800Hz)
        let normalized = min(max(value / 100, 0), 1)
        let frequency = 200 + normalized * 600
        
        // Trigger haptic feedback as a fallback
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: normalized > 0.5 ? .medium : .light)
        impact.impactOccurred()
        #endif
    }
}

// MARK: - Semantic Description Generator

/// Generates semantic descriptions for charts.
public struct ChartDescriptionGenerator {
    
    /// Generates a description for a line chart.
    public static func describeLineChart(
        title: String?,
        seriesNames: [String],
        values: [[Double]],
        labels: [String]
    ) -> String {
        var description = ""
        
        if let title = title {
            description += "\(title). "
        }
        
        description += "Line chart with \(seriesNames.count) series"
        if !labels.isEmpty {
            description += " and \(labels.count) data points"
        }
        description += ". "
        
        for (index, series) in seriesNames.enumerated() {
            if index < values.count {
                let seriesValues = values[index]
                if let min = seriesValues.min(), let max = seriesValues.max() {
                    let trend = describeTrend(seriesValues)
                    description += "\(series): ranges from \(formatValue(min)) to \(formatValue(max)), \(trend). "
                }
            }
        }
        
        return description
    }
    
    /// Generates a description for a bar chart.
    public static func describeBarChart(
        title: String?,
        categoryLabels: [String],
        values: [Double]
    ) -> String {
        var description = ""
        
        if let title = title {
            description += "\(title). "
        }
        
        description += "Bar chart with \(categoryLabels.count) categories. "
        
        if let maxIndex = values.firstIndex(of: values.max() ?? 0),
           let minIndex = values.firstIndex(of: values.min() ?? 0) {
            if maxIndex < categoryLabels.count && minIndex < categoryLabels.count {
                description += "Highest: \(categoryLabels[maxIndex]) at \(formatValue(values[maxIndex])). "
                description += "Lowest: \(categoryLabels[minIndex]) at \(formatValue(values[minIndex])). "
            }
        }
        
        return description
    }
    
    /// Generates a description for a pie chart.
    public static func describePieChart(
        title: String?,
        sliceLabels: [String],
        values: [Double]
    ) -> String {
        var description = ""
        
        if let title = title {
            description += "\(title). "
        }
        
        let total = values.reduce(0, +)
        description += "Pie chart with \(sliceLabels.count) slices. "
        
        // Describe top 3 slices
        let sortedIndices = values.indices.sorted { values[$0] > values[$1] }
        let topSlices = sortedIndices.prefix(3)
        
        for index in topSlices {
            if index < sliceLabels.count {
                let percentage = (values[index] / total) * 100
                description += "\(sliceLabels[index]): \(String(format: "%.1f%%", percentage)). "
            }
        }
        
        return description
    }
    
    private static func describeTrend(_ values: [Double]) -> String {
        guard values.count >= 2 else { return "stable" }
        
        let first = values.first!
        let last = values.last!
        let change = ((last - first) / first) * 100
        
        if abs(change) < 5 {
            return "stable"
        } else if change > 0 {
            return "trending up \(String(format: "%.0f%%", change))"
        } else {
            return "trending down \(String(format: "%.0f%%", abs(change)))"
        }
    }
    
    private static func formatValue(_ value: Double) -> String {
        if abs(value) >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.1f", value)
        }
    }
}
