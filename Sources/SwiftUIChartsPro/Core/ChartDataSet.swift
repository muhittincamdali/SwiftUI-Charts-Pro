import SwiftUI

/// A generic container for chart data with support for metadata and statistics.
///
/// `ChartDataSet` provides a uniform way to hold typed data along with
/// computed statistics like min, max, and average.
///
/// ```swift
/// let dataSet = ChartDataSet(name: "Revenue", values: [100, 200, 150, 300])
/// print(dataSet.average) // 187.5
/// ```
public struct ChartDataSet<T> {

    /// The display name of this data set.
    public let name: String

    /// The raw data values.
    public let values: [T]

    /// An optional color for rendering this data set.
    public let color: Color

    /// Whether this data set is visible in the chart.
    public var isVisible: Bool

    /// Creates a chart data set.
    ///
    /// - Parameters:
    ///   - name: The display name.
    ///   - values: The data values.
    ///   - color: The rendering color.
    ///   - isVisible: Initial visibility state.
    public init(name: String, values: [T], color: Color = .blue, isVisible: Bool = true) {
        self.name = name
        self.values = values
        self.color = color
        self.isVisible = isVisible
    }

    /// The number of data points in this set.
    public var count: Int { values.count }

    /// Whether the data set is empty.
    public var isEmpty: Bool { values.isEmpty }
}

// MARK: - Numeric Statistics

public extension ChartDataSet where T: BinaryFloatingPoint {

    /// The minimum value in the data set.
    var minimum: T? { values.min() }

    /// The maximum value in the data set.
    var maximum: T? { values.max() }

    /// The sum of all values.
    var sum: T { values.reduce(0, +) }

    /// The average of all values.
    var average: T? {
        guard !values.isEmpty else { return nil }
        return sum / T(values.count)
    }

    /// The range between min and max values.
    var range: T? {
        guard let min = minimum, let max = maximum else { return nil }
        return max - min
    }

    /// Normalizes all values to a 0...1 range.
    var normalized: [T] {
        guard let min = minimum, let max = maximum, max != min else {
            return values.map { _ in T(0.5) }
        }
        return values.map { ($0 - min) / (max - min) }
    }
}

// MARK: - Identifiable

extension ChartDataSet: Identifiable {
    public var id: String { name }
}
