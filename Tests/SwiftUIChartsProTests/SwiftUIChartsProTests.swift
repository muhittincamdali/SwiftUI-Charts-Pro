import XCTest
@testable import SwiftUIChartsPro

final class SwiftUIChartsProTests: XCTestCase {
    
    // MARK: - Line Chart Tests
    
    func testLineDataSeriesCreation() {
        let series = LineDataSeries(
            name: "Test",
            values: [1, 2, 3, 4, 5],
            color: .blue
        )
        
        XCTAssertEqual(series.name, "Test")
        XCTAssertEqual(series.values.count, 5)
        XCTAssertEqual(series.values[0], 1)
        XCTAssertEqual(series.values[4], 5)
    }
    
    func testLineDataSeriesWithGradient() {
        let series = LineDataSeries(
            name: "Gradient",
            values: [10, 20, 30],
            gradient: LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
        )
        
        XCTAssertNotNil(series.gradient)
    }
    
    // MARK: - Bar Chart Tests
    
    func testBarDataSeriesCreation() {
        let series = BarDataSeries(
            name: "Sales",
            values: [100, 150, 200],
            color: .green
        )
        
        XCTAssertEqual(series.name, "Sales")
        XCTAssertEqual(series.values.count, 3)
    }
    
    // MARK: - Pie Chart Tests
    
    func testPieSliceCreation() {
        let slice = PieSlice(
            label: "iOS",
            value: 60,
            color: .blue
        )
        
        XCTAssertEqual(slice.label, "iOS")
        XCTAssertEqual(slice.value, 60)
    }
    
    func testPieChartTotalCalculation() {
        let slices = [
            PieSlice(label: "A", value: 30),
            PieSlice(label: "B", value: 40),
            PieSlice(label: "C", value: 30)
        ]
        
        let total = slices.reduce(0) { $0 + $1.value }
        XCTAssertEqual(total, 100)
    }
    
    // MARK: - Area Chart Tests
    
    func testAreaDataSeriesCreation() {
        let series = AreaDataSeries(
            name: "Traffic",
            values: [50, 60, 70, 80, 90],
            color: .orange
        )
        
        XCTAssertEqual(series.name, "Traffic")
        XCTAssertEqual(series.values.count, 5)
    }
    
    // MARK: - Scatter Plot Tests
    
    func testScatterDataSeriesCreation() {
        let points = [(x: 1.0, y: 2.0), (x: 3.0, y: 4.0), (x: 5.0, y: 6.0)]
        let series = ScatterDataSeries(
            name: "Correlation",
            points: points,
            color: .purple
        )
        
        XCTAssertEqual(series.name, "Correlation")
        XCTAssertEqual(series.points.count, 3)
        XCTAssertEqual(series.points[0].x, 1.0)
        XCTAssertEqual(series.points[0].y, 2.0)
    }
    
    // MARK: - Radar Chart Tests
    
    func testRadarDataSeriesCreation() {
        let series = RadarDataSeries(
            name: "Skills",
            values: [80, 90, 70, 60, 85],
            color: .red
        )
        
        XCTAssertEqual(series.name, "Skills")
        XCTAssertEqual(series.values.count, 5)
    }
    
    // MARK: - Theme Tests
    
    func testDefaultTheme() {
        let theme = ChartTheme.default
        
        XCTAssertEqual(theme.name, "Default")
        XCTAssertFalse(theme.colorPalette.isEmpty)
    }
    
    func testDarkTheme() {
        let theme = ChartTheme.dark
        
        XCTAssertEqual(theme.name, "Dark")
    }
    
    func testMidnightTheme() {
        let theme = ChartTheme.midnight
        
        XCTAssertEqual(theme.name, "Midnight")
    }
    
    // MARK: - Configuration Tests
    
    func testChartConfigurationDefaults() {
        let config = ChartConfiguration()
        
        XCTAssertTrue(config.animated)
        XCTAssertEqual(config.animationDuration, 0.3)
        XCTAssertTrue(config.showGrid)
        XCTAssertTrue(config.tooltipsEnabled)
        XCTAssertTrue(config.showLegend)
    }
    
    func testChartConfigurationCustom() {
        let config = ChartConfiguration(
            animated: false,
            animationDuration: 0.5,
            showGrid: false,
            tooltipsEnabled: false,
            showLegend: false
        )
        
        XCTAssertFalse(config.animated)
        XCTAssertEqual(config.animationDuration, 0.5)
        XCTAssertFalse(config.showGrid)
        XCTAssertFalse(config.tooltipsEnabled)
        XCTAssertFalse(config.showLegend)
    }
    
    // MARK: - Data Point Tests
    
    func testChartDataPointCreation() {
        let point = ChartDataPoint(
            label: "January",
            value: 100,
            color: .blue,
            position: CGPoint(x: 50, y: 100)
        )
        
        XCTAssertEqual(point.label, "January")
        XCTAssertEqual(point.value, 100)
        XCTAssertEqual(point.position.x, 50)
    }
    
    func testAccessibleDataPointCreation() {
        let point = AccessibleDataPoint(
            label: "Q1 Revenue",
            value: 50000,
            customDescription: "First quarter revenue of fifty thousand dollars"
        )
        
        XCTAssertEqual(point.label, "Q1 Revenue")
        XCTAssertEqual(point.value, 50000)
        XCTAssertNotNil(point.customDescription)
    }
    
    // MARK: - High Performance Renderer Tests
    
    @MainActor
    func testHighPerformanceRendererCreation() async {
        let data = (0..<1000).map { Double($0) }
        let renderer = HighPerformanceRenderer(data: data)
        
        XCTAssertEqual(renderer.originalCount, 1000)
    }
    
    @MainActor
    func testHighPerformanceRendererSampling() async {
        let data = (0..<10000).map { Double($0) }
        let renderer = HighPerformanceRenderer(
            data: data,
            samplingStrategy: .uniform
        )
        
        let sampled = renderer.optimizedData(targetPoints: 100)
        
        XCTAssertEqual(sampled.count, 100)
    }
    
    @MainActor
    func testHighPerformanceRendererLTTB() async {
        let data = (0..<5000).map { Double($0) }
        let renderer = HighPerformanceRenderer(
            data: data,
            samplingStrategy: .largestTriangle(buckets: 500)
        )
        
        let sampled = renderer.optimizedData(targetPoints: 500)
        
        XCTAssertLessThanOrEqual(sampled.count, 502) // Allow for first/last points
    }
    
    // MARK: - Real-Time Stream Tests
    
    @MainActor
    func testRealTimeStreamCreation() async {
        let stream = RealTimeDataStream<Double>(
            windowSize: 100,
            updateFrequency: .fps30
        )
        
        XCTAssertEqual(stream.windowSize, 100)
        XCTAssertTrue(stream.data.isEmpty)
    }
    
    @MainActor
    func testRealTimeStreamPush() async {
        let stream = RealTimeDataStream<Double>(windowSize: 10)
        
        stream.push(value: 42.0)
        stream.start()
        
        // Wait for flush
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(stream.data.isEmpty)
    }
    
    // MARK: - Animation Preset Tests
    
    func testAnimationPresets() {
        XCTAssertNil(ChartAnimationPreset.none.animation)
        XCTAssertNotNil(ChartAnimationPreset.quick.animation)
        XCTAssertNotNil(ChartAnimationPreset.smooth.animation)
        XCTAssertNotNil(ChartAnimationPreset.spring.animation)
        XCTAssertNotNil(ChartAnimationPreset.elastic.animation)
    }
    
    func testAnimationDurations() {
        XCTAssertEqual(ChartAnimationPreset.none.duration, 0)
        XCTAssertEqual(ChartAnimationPreset.quick.duration, 0.2)
        XCTAssertEqual(ChartAnimationPreset.smooth.duration, 0.5)
    }
    
    // MARK: - Export Tests
    
    @MainActor
    func testExportOptionsDefaults() async {
        let options = ChartExporter.ExportOptions()
        
        XCTAssertEqual(options.scale, 2.0)
        XCTAssertEqual(options.jpegQuality, 0.9)
        XCTAssertTrue(options.includeTitle)
        XCTAssertTrue(options.includeLegend)
    }
    
    // MARK: - Sampling Strategy Tests
    
    func testSamplingStrategies() {
        let strategies: [SamplingStrategy] = [
            .none,
            .uniform,
            .largestTriangle(buckets: 100),
            .minMax,
            .adaptive(threshold: 0.5)
        ]
        
        XCTAssertEqual(strategies.count, 5)
    }
    
    // MARK: - Benchmark Tests
    
    func testBenchmarkDataGeneration() {
        let data = ChartBenchmark.generateTestData(count: 1000)
        
        XCTAssertEqual(data.count, 1000)
        XCTAssertTrue(data.allSatisfy { $0.y >= 0 && $0.y <= 120 })
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityConfiguration() {
        let config = ChartAccessibilityConfiguration(
            label: "Sales Chart",
            summary: "Monthly sales from January to December",
            enableAudioGraph: true,
            announceChanges: true
        )
        
        XCTAssertEqual(config.label, "Sales Chart")
        XCTAssertNotNil(config.summary)
        XCTAssertTrue(config.enableAudioGraph)
    }
    
    func testChartDescriptionGenerator() {
        let description = ChartDescriptionGenerator.describeLineChart(
            title: "Revenue",
            seriesNames: ["2024"],
            values: [[100, 150, 200, 180, 220]],
            labels: ["Jan", "Feb", "Mar", "Apr", "May"]
        )
        
        XCTAssertTrue(description.contains("Revenue"))
        XCTAssertTrue(description.contains("2024"))
    }
    
    // MARK: - Build Info Tests
    
    func testBuildInfo() {
        XCTAssertEqual(BuildInfo.version, "2.0.0")
        XCTAssertFalse(BuildInfo.platforms.isEmpty)
        XCTAssertTrue(BuildInfo.platforms.contains("iOS 15+"))
    }
    
    func testChartFeatures() {
        XCTAssertTrue(ChartFeatures.realTimeStreaming)
        XCTAssertTrue(ChartFeatures.highPerformanceRendering)
        XCTAssertTrue(ChartFeatures.exportSupport)
        XCTAssertTrue(ChartFeatures.accessibility)
        XCTAssertEqual(ChartFeatures.maxOptimalDataPoints, 1_000_000)
    }
}

// MARK: - Performance Tests

final class PerformanceTests: XCTestCase {
    
    @MainActor
    func testLargeDatasetPerformance() async {
        let data = (0..<100_000).map { Double($0) }
        
        measure {
            let renderer = HighPerformanceRenderer(
                data: data,
                samplingStrategy: .largestTriangle(buckets: 1000)
            )
            _ = renderer.optimizedData(targetPoints: 1000)
        }
    }
    
    func testDataPointCreationPerformance() {
        measure {
            for i in 0..<10000 {
                _ = ChartDataPoint(
                    label: "Point \(i)",
                    value: Double(i),
                    position: CGPoint(x: CGFloat(i), y: CGFloat(i))
                )
            }
        }
    }
}
