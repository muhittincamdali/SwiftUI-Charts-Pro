import SwiftUI

// MARK: - Chart Data Set

/// A labeled set of data points for charts
public struct ChartDataSet: Identifiable {
    public let id = UUID()
    public let label: String
    public let values: [Double]
    public let color: Color
    public let secondaryColor: Color?

    public init(
        label: String,
        values: [Double],
        color: Color = .blue,
        secondaryColor: Color? = nil
    ) {
        self.label = label
        self.values = values
        self.color = color
        self.secondaryColor = secondaryColor
    }

    public var min: Double { values.min() ?? 0 }
    public var max: Double { values.max() ?? 0 }
    public var sum: Double { values.reduce(0, +) }
    public var average: Double { values.isEmpty ? 0 : sum / Double(values.count) }
}

// MARK: - Candlestick Data

/// OHLC data point for candlestick charts
public struct CandleData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let volume: Double?

    public init(date: Date, open: Double, high: Double, low: Double, close: Double, volume: Double? = nil) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }

    public var isBullish: Bool { close >= open }
    public var bodyHeight: Double { abs(close - open) }
    public var wickHeight: Double { high - low }
}

// MARK: - Bubble Data

/// Data point for bubble charts
public struct BubbleData: Identifiable {
    public let id = UUID()
    public let x: Double
    public let y: Double
    public let size: Double
    public let label: String
    public let color: Color

    public init(x: Double, y: Double, size: Double, label: String = "", color: Color = .blue) {
        self.x = x
        self.y = y
        self.size = size
        self.label = label
        self.color = color
    }
}

// MARK: - Sankey Data

/// Node for Sankey diagrams
public struct SankeyNode: Identifiable {
    public let id: String
    public let label: String
    public let color: Color

    public init(id: String, label: String, color: Color = .blue) {
        self.id = id
        self.label = label
        self.color = color
    }
}

/// Link between nodes in Sankey diagrams
public struct SankeyLink: Identifiable {
    public let id = UUID()
    public let source: String
    public let target: String
    public let value: Double

    public init(source: String, target: String, value: Double) {
        self.source = source
        self.target = target
        self.value = value
    }
}

// MARK: - Gantt Data

/// Task for Gantt charts
public struct GanttTask: Identifiable {
    public let id: String
    public let label: String
    public let start: Date
    public let end: Date
    public let color: Color
    public let progress: Double

    public init(id: String, label: String, start: Date, end: Date, color: Color = .blue, progress: Double = 0) {
        self.id = id
        self.label = label
        self.start = start
        self.end = end
        self.color = color
        self.progress = Swift.min(1, Swift.max(0, progress))
    }

    public var duration: TimeInterval { end.timeIntervalSince(start) }
}

// MARK: - Treemap Data

/// Item for treemap charts
public struct TreemapItem: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Double
    public let color: Color
    public let children: [TreemapItem]

    public init(label: String, value: Double, color: Color = .blue, children: [TreemapItem] = []) {
        self.label = label
        self.value = value
        self.color = color
        self.children = children
    }
}

// MARK: - Word Cloud Data

/// Item for word cloud charts
public struct WordCloudItem: Identifiable {
    public let id = UUID()
    public let text: String
    public let weight: Double
    public let color: Color?

    public init(text: String, weight: Double, color: Color? = nil) {
        self.text = text
        self.weight = weight
        self.color = color
    }
}
