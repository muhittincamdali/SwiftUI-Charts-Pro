import XCTest
@testable import SwiftUIChartsPro

final class SwiftUIChartsProTests: XCTestCase {
    
    // MARK: - ChartDataSet Tests
    
    func testChartDataSetCreation() {
        let dataSet = ChartDataSet(name: "Revenue", values: [100.0, 200.0, 150.0, 300.0])
        
        XCTAssertEqual(dataSet.name, "Revenue")
        XCTAssertEqual(dataSet.count, 4)
        XCTAssertFalse(dataSet.isEmpty)
    }
    
    func testChartDataSetStatistics() {
        let dataSet = ChartDataSet(name: "Test", values: [10.0, 20.0, 30.0, 40.0, 50.0])
        
        XCTAssertEqual(dataSet.minimum, 10.0)
        XCTAssertEqual(dataSet.maximum, 50.0)
        XCTAssertEqual(dataSet.sum, 150.0)
        XCTAssertEqual(dataSet.average, 30.0)
        XCTAssertEqual(dataSet.range, 40.0)
    }
    
    func testChartDataSetNormalization() {
        let dataSet = ChartDataSet(name: "Test", values: [0.0, 50.0, 100.0])
        let normalized = dataSet.normalized
        
        XCTAssertEqual(normalized.count, 3)
        XCTAssertEqual(normalized[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(normalized[1], 0.5, accuracy: 0.001)
        XCTAssertEqual(normalized[2], 1.0, accuracy: 0.001)
    }
    
    // MARK: - ChartMath Tests
    
    func testMean() {
        let values = [10.0, 20.0, 30.0, 40.0, 50.0]
        XCTAssertEqual(ChartMath.mean(values), 30.0)
    }
    
    func testMedian() {
        let oddValues = [10.0, 20.0, 30.0, 40.0, 50.0]
        XCTAssertEqual(ChartMath.median(oddValues), 30.0)
        
        let evenValues = [10.0, 20.0, 30.0, 40.0]
        XCTAssertEqual(ChartMath.median(evenValues), 25.0)
    }
    
    func testVariance() {
        let values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
        let variance = ChartMath.variance(values)
        XCTAssertEqual(variance, 4.571, accuracy: 0.01)
    }
    
    func testStandardDeviation() {
        let values = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
        let std = ChartMath.standardDeviation(values)
        XCTAssertEqual(std, 2.138, accuracy: 0.01)
    }
    
    func testPercentile() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        
        XCTAssertEqual(ChartMath.percentile(values, p: 0), 1.0, accuracy: 0.01)
        XCTAssertEqual(ChartMath.percentile(values, p: 50), 5.5, accuracy: 0.01)
        XCTAssertEqual(ChartMath.percentile(values, p: 100), 10.0, accuracy: 0.01)
    }
    
    func testQuartiles() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let quartiles = ChartMath.quartiles(values)
        
        XCTAssertEqual(quartiles.q1, 3.25, accuracy: 0.1)
        XCTAssertEqual(quartiles.q2, 5.5, accuracy: 0.1)
        XCTAssertEqual(quartiles.q3, 7.75, accuracy: 0.1)
    }
    
    func testCorrelation() {
        let x = [1.0, 2.0, 3.0, 4.0, 5.0]
        let y = [2.0, 4.0, 6.0, 8.0, 10.0]
        
        let correlation = ChartMath.correlation(x, y)
        XCTAssertEqual(correlation, 1.0, accuracy: 0.001)
    }
    
    func testLinearRegression() {
        let x = [1.0, 2.0, 3.0, 4.0, 5.0]
        let y = [2.0, 4.0, 6.0, 8.0, 10.0]
        
        let regression = ChartMath.linearRegression(x, y)
        
        XCTAssertEqual(regression.slope, 2.0, accuracy: 0.001)
        XCTAssertEqual(regression.intercept, 0.0, accuracy: 0.001)
        XCTAssertEqual(regression.rSquared, 1.0, accuracy: 0.001)
    }
    
    func testNormalization() {
        let values = [10.0, 20.0, 30.0, 40.0, 50.0]
        let normalized = ChartMath.normalize(values)
        
        XCTAssertEqual(normalized[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(normalized[2], 0.5, accuracy: 0.001)
        XCTAssertEqual(normalized[4], 1.0, accuracy: 0.001)
    }
    
    func testNiceTickValues() {
        let ticks = ChartMath.niceTickValues(min: 0, max: 100, count: 6)
        
        XCTAssertGreaterThan(ticks.count, 0)
        XCTAssertLessThanOrEqual(ticks.first ?? 0, 0)
        XCTAssertGreaterThanOrEqual(ticks.last ?? 0, 100)
    }
    
    func testSimpleMovingAverage() {
        let values = [10.0, 20.0, 30.0, 40.0, 50.0]
        let sma = ChartMath.simpleMovingAverage(values, window: 3)
        
        XCTAssertEqual(sma.count, 3)
        XCTAssertEqual(sma[0], 20.0, accuracy: 0.001)
        XCTAssertEqual(sma[1], 30.0, accuracy: 0.001)
        XCTAssertEqual(sma[2], 40.0, accuracy: 0.001)
    }
    
    func testDegreesToRadians() {
        XCTAssertEqual(ChartMath.degreesToRadians(0), 0, accuracy: 0.001)
        XCTAssertEqual(ChartMath.degreesToRadians(90), .pi / 2, accuracy: 0.001)
        XCTAssertEqual(ChartMath.degreesToRadians(180), .pi, accuracy: 0.001)
        XCTAssertEqual(ChartMath.degreesToRadians(360), 2 * .pi, accuracy: 0.001)
    }
    
    // MARK: - Data Model Tests
    
    func testLabeledDataPoint() {
        let point = LabeledDataPoint(label: "Test", value: 42.0, color: .blue)
        
        XCTAssertEqual(point.label, "Test")
        XCTAssertEqual(point.value, 42.0)
        XCTAssertNotNil(point.color)
    }
    
    func testXYDataPoint() {
        let point = XYDataPoint(x: 10, y: 20, label: "Point", size: 30, color: .red)
        
        XCTAssertEqual(point.x, 10)
        XCTAssertEqual(point.y, 20)
        XCTAssertEqual(point.label, "Point")
        XCTAssertEqual(point.size, 30)
    }
    
    func testHierarchyNode() {
        let leaf1 = HierarchyNode(name: "Leaf1", value: 100)
        let leaf2 = HierarchyNode(name: "Leaf2", value: 200)
        let root = HierarchyNode(name: "Root", children: [leaf1, leaf2])
        
        XCTAssertEqual(root.name, "Root")
        XCTAssertEqual(root.children.count, 2)
        XCTAssertEqual(root.totalValue, 300)
        XCTAssertFalse(root.isLeaf)
        XCTAssertTrue(leaf1.isLeaf)
    }
    
    func testFlowConnection() {
        let connection = FlowConnection(source: "A", target: "B", value: 100)
        
        XCTAssertEqual(connection.source, "A")
        XCTAssertEqual(connection.target, "B")
        XCTAssertEqual(connection.value, 100)
    }
    
    func testGanttTask() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 5)
        let task = GanttTask(name: "Task 1", startDate: startDate, endDate: endDate, progress: 0.5)
        
        XCTAssertEqual(task.name, "Task 1")
        XCTAssertEqual(task.progress, 0.5)
        XCTAssertEqual(task.durationInDays, 5)
    }
    
    func testRangeDataPoint() {
        let point = RangeDataPoint(label: "Range", low: 10, high: 50, open: 20, close: 40)
        
        XCTAssertEqual(point.range, 40)
        XCTAssertEqual(point.midpoint, 30)
    }
    
    // MARK: - Theme Tests
    
    func testChartThemeDefaults() {
        let theme = ChartTheme.default
        
        XCTAssertEqual(theme.palette.count, 8)
        XCTAssertEqual(theme.animationDuration, 0.5)
    }
    
    func testChartThemeColorAccess() {
        let theme = ChartTheme.default
        
        // Should wrap around
        XCTAssertNotNil(theme.color(at: 0))
        XCTAssertNotNil(theme.color(at: 10))
    }
    
    func testChartThemeBuilder() {
        let theme = ChartThemeBuilder()
            .animationDuration(1.0)
            .cornerRadius(12)
            .build()
        
        XCTAssertEqual(theme.animationDuration, 1.0)
        XCTAssertEqual(theme.cornerRadius, 12)
    }
    
    // MARK: - Configuration Tests
    
    func testChartConfiguration() {
        let config = ChartConfiguration(
            animated: false,
            showGrid: true,
            tooltipsEnabled: false
        )
        
        XCTAssertFalse(config.animated)
        XCTAssertTrue(config.showGrid)
        XCTAssertFalse(config.tooltipsEnabled)
    }
    
    func testAxisConfiguration() {
        let config = AxisConfiguration(
            showAxisLine: true,
            tickCount: 10,
            title: "X Axis"
        )
        
        XCTAssertTrue(config.showAxisLine)
        XCTAssertEqual(config.tickCount, 10)
        XCTAssertEqual(config.title, "X Axis")
    }
    
    func testGridConfiguration() {
        let config = GridConfiguration.dashed
        
        XCTAssertTrue(config.showHorizontalLines)
        XCTAssertFalse(config.dashPattern.isEmpty)
    }
    
    // MARK: - Sample Data Tests
    
    func testSampleDataLabeledPoints() {
        let points = SampleData.labeledPoints(count: 10)
        
        XCTAssertEqual(points.count, 10)
        XCTAssertTrue(points.allSatisfy { !$0.label.isEmpty })
    }
    
    func testSampleDataHierarchy() {
        let root = SampleData.hierarchy(depth: 2, breadth: 3)
        
        XCTAssertEqual(root.name, "Root")
        XCTAssertEqual(root.children.count, 3)
    }
    
    func testSampleDataCandlesticks() {
        let candles = SampleData.candlesticks(count: 10)
        
        XCTAssertEqual(candles.count, 10)
        XCTAssertTrue(candles.allSatisfy { $0.high >= $0.low })
        XCTAssertTrue(candles.allSatisfy { $0.high >= max($0.open, $0.close) })
        XCTAssertTrue(candles.allSatisfy { $0.low <= min($0.open, $0.close) })
    }
    
    // MARK: - BoxPlotStatistics Tests
    
    func testBoxPlotStatistics() {
        let values = Array(stride(from: 1.0, through: 100.0, by: 1.0))
        let stats = BoxPlotStatistics(values: values)
        
        XCTAssertEqual(stats.min, 1.0, accuracy: 1)
        XCTAssertEqual(stats.max, 100.0, accuracy: 1)
        XCTAssertEqual(stats.median, 50.5, accuracy: 1)
        XCTAssertEqual(stats.mean, 50.5, accuracy: 0.1)
    }
    
    // MARK: - Accessibility Label Tests
    
    func testAccessibilityLabelForDataPoint() {
        let label = ChartAccessibilityLabel.forDataPoint(
            label: "Revenue",
            value: 1500,
            format: "%.0f",
            unit: " USD"
        )
        
        XCTAssertTrue(label.contains("Revenue"))
        XCTAssertTrue(label.contains("1500"))
        XCTAssertTrue(label.contains("USD"))
    }
    
    func testAccessibilityLabelForTrend() {
        let label = ChartAccessibilityLabel.forTrend(
            label: "Sales",
            currentValue: 110,
            previousValue: 100
        )
        
        XCTAssertTrue(label.contains("Sales"))
        XCTAssertTrue(label.contains("increased"))
        XCTAssertTrue(label.contains("10"))
    }
    
    // MARK: - Chart Description Tests
    
    func testLineChartDescription() {
        let description = ChartDescriptionGenerator.describeLineChart(
            title: "Sales",
            dataPoints: [10, 20, 30, 40, 50]
        )
        
        XCTAssertTrue(description.contains("Sales"))
        XCTAssertTrue(description.contains("5 data points"))
        XCTAssertTrue(description.contains("upward"))
    }
    
    func testBarChartDescription() {
        let description = ChartDescriptionGenerator.describeBarChart(
            title: "Revenue",
            bars: [("Q1", 100), ("Q2", 150), ("Q3", 80)]
        )
        
        XCTAssertTrue(description.contains("Revenue"))
        XCTAssertTrue(description.contains("3 bars"))
        XCTAssertTrue(description.contains("Q2"))
    }
}
