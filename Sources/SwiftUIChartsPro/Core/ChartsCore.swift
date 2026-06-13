import SwiftUI

/// Main entry point for the SwiftUI Charts Pro toolkit.
public enum SwiftUIChartsPro {
    public static let version = "2.0.0"
}

/// A standard data point for charting.
public struct ChartDataPoint: Identifiable, Sendable {
    public let id: UUID
    public let value: Double
    public let label: String
    
    public init(value: Double, label: String) {
        self.id = UUID()
        self.value = value
        self.label = label
    }
}
