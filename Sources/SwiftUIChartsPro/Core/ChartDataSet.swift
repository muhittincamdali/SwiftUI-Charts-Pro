import SwiftUI

// MARK: - Chart Data Set

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
    public var values: [T]

    /// An optional color for rendering this data set.
    public var color: Color

    /// Whether this data set is visible in the chart.
    public var isVisible: Bool
    
    /// Optional metadata dictionary
    public var metadata: [String: Any]

    /// Creates a chart data set.
    ///
    /// - Parameters:
    ///   - name: The display name.
    ///   - values: The data values.
    ///   - color: The rendering color.
    ///   - isVisible: Initial visibility state.
    ///   - metadata: Additional metadata.
    public init(
        name: String,
        values: [T],
        color: Color = .blue,
        isVisible: Bool = true,
        metadata: [String: Any] = [:]
    ) {
        self.name = name
        self.values = values
        self.color = color
        self.isVisible = isVisible
        self.metadata = metadata
    }

    /// The number of data points in this set.
    public var count: Int { values.count }

    /// Whether the data set is empty.
    public var isEmpty: Bool { values.isEmpty }
    
    /// Subscript access to values
    public subscript(index: Int) -> T {
        get { values[index] }
        set { values[index] = newValue }
    }
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
    
    /// Returns the median value
    var median: T? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / T(2)
        }
        return sorted[mid]
    }
    
    /// Returns the standard deviation
    var standardDeviation: T? {
        guard let avg = average, values.count > 1 else { return nil }
        let variance = values.reduce(T(0)) { result, value in
            let diff = value - avg
            return result + diff * diff
        } / T(values.count - 1)
        return sqrt(Double(variance)) as? T
    }
    
    /// Returns quartile values (Q1, Q2, Q3)
    var quartiles: (q1: T, q2: T, q3: T)? {
        guard values.count >= 4 else { return nil }
        let sorted = values.sorted()
        let n = sorted.count
        
        let q2 = sorted[n / 2]
        let q1 = sorted[n / 4]
        let q3 = sorted[(3 * n) / 4]
        
        return (q1, q2, q3)
    }
}

// MARK: - Integer Statistics

public extension ChartDataSet where T: BinaryInteger {
    
    /// The minimum value in the data set.
    var minimum: T? { values.min() }
    
    /// The maximum value in the data set.
    var maximum: T? { values.max() }
    
    /// The sum of all values.
    var sum: T { values.reduce(0, +) }
    
    /// The average as a Double
    var average: Double? {
        guard !values.isEmpty else { return nil }
        return Double(sum) / Double(values.count)
    }
}

// MARK: - Identifiable

extension ChartDataSet: Identifiable {
    public var id: String { name }
}

// MARK: - Labeled Data Point

/// A data point with a label and value, used in many chart types.
public struct LabeledDataPoint: Identifiable, Equatable {
    public let id: UUID
    public let label: String
    public let value: Double
    public var color: Color?
    
    public init(id: UUID = UUID(), label: String, value: Double, color: Color? = nil) {
        self.id = id
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - XY Data Point

/// A two-dimensional data point for scatter and bubble charts.
public struct XYDataPoint: Identifiable, Equatable {
    public let id: UUID
    public let x: Double
    public let y: Double
    public var label: String?
    public var size: Double
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        x: Double,
        y: Double,
        label: String? = nil,
        size: Double = 1.0,
        color: Color? = nil
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.label = label
        self.size = size
        self.color = color
    }
}

// MARK: - Time Series Data Point

/// A data point with a date component for time series charts.
public struct TimeSeriesDataPoint: Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let value: Double
    public var label: String?
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        label: String? = nil,
        color: Color? = nil
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.label = label
        self.color = color
    }
}

// MARK: - Range Data Point

/// A data point with a range of values (for box plots, candlesticks, etc.)
public struct RangeDataPoint: Identifiable, Equatable {
    public let id: UUID
    public let label: String
    public let low: Double
    public let high: Double
    public var open: Double?
    public var close: Double?
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        label: String,
        low: Double,
        high: Double,
        open: Double? = nil,
        close: Double? = nil,
        color: Color? = nil
    ) {
        self.id = id
        self.label = label
        self.low = low
        self.high = high
        self.open = open
        self.close = close
        self.color = color
    }
    
    /// The range between low and high
    public var range: Double { high - low }
    
    /// The midpoint of the range
    public var midpoint: Double { (low + high) / 2 }
}

// MARK: - Hierarchical Data

/// A hierarchical data node for treemaps, sunbursts, etc.
public struct HierarchyNode: Identifiable {
    public let id: UUID
    public let name: String
    public var value: Double
    public var children: [HierarchyNode]
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        name: String,
        value: Double = 0,
        children: [HierarchyNode] = [],
        color: Color? = nil
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.children = children
        self.color = color
    }
    
    /// The total value including all descendants
    public var totalValue: Double {
        if children.isEmpty {
            return value
        }
        return children.reduce(0) { $0 + $1.totalValue }
    }
    
    /// Whether this is a leaf node
    public var isLeaf: Bool { children.isEmpty }
    
    /// The depth of the tree from this node
    public var maxDepth: Int {
        if children.isEmpty { return 0 }
        return 1 + (children.map { $0.maxDepth }.max() ?? 0)
    }
    
    /// Flattens the hierarchy into an array
    public func flatten() -> [HierarchyNode] {
        var result = [self]
        for child in children {
            result.append(contentsOf: child.flatten())
        }
        return result
    }
}

// MARK: - Flow Data

/// A connection between two nodes in flow diagrams (Sankey, Chord)
public struct FlowConnection: Identifiable {
    public let id: UUID
    public let source: String
    public let target: String
    public let value: Double
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        source: String,
        target: String,
        value: Double,
        color: Color? = nil
    ) {
        self.id = id
        self.source = source
        self.target = target
        self.value = value
        self.color = color
    }
}

// MARK: - Gantt Task

/// A task for Gantt charts with start/end dates and dependencies.
public struct GanttTask: Identifiable {
    public let id: UUID
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public var progress: Double
    public var dependencies: [UUID]
    public var color: Color?
    public var group: String?
    
    public init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        progress: Double = 0,
        dependencies: [UUID] = [],
        color: Color? = nil,
        group: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.progress = min(1, max(0, progress))
        self.dependencies = dependencies
        self.color = color
        self.group = group
    }
    
    /// The duration of the task
    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    /// The duration in days
    public var durationInDays: Int {
        Int(duration / 86400)
    }
}

// MARK: - Word Cloud Item

/// An item for word cloud visualization.
public struct WordCloudItem: Identifiable {
    public let id: UUID
    public let text: String
    public let weight: Double
    public var color: Color?
    
    public init(
        id: UUID = UUID(),
        text: String,
        weight: Double,
        color: Color? = nil
    ) {
        self.id = id
        self.text = text
        self.weight = weight
        self.color = color
    }
}
