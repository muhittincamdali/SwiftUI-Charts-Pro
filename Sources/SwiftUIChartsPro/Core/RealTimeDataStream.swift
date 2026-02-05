import SwiftUI
import Combine

// MARK: - Real-Time Data Stream

/// A publisher for streaming real-time chart data with automatic buffering and throttling.
///
/// `RealTimeDataStream` handles high-frequency data updates efficiently by:
/// - Buffering incoming data to reduce render cycles
/// - Automatically managing window size for sliding views
/// - Supporting multiple update frequencies
/// - Providing backpressure handling
///
/// ```swift
/// let stream = RealTimeDataStream<Double>(
///     windowSize: 100,
///     updateFrequency: .fps60
/// )
///
/// // Push data
/// stream.push(value: 42.5)
///
/// // Observe in SwiftUI
/// @ObservedObject var stream: RealTimeDataStream<Double>
/// LineChart(data: stream.data)
/// ```
@MainActor
public final class RealTimeDataStream<T>: ObservableObject {
    
    // MARK: - Properties
    
    /// Current data window
    @Published public private(set) var data: [T] = []
    
    /// Whether the stream is active
    @Published public private(set) var isActive: Bool = false
    
    /// Current data rate (points per second)
    @Published public private(set) var dataRate: Double = 0
    
    /// Maximum window size
    public let windowSize: Int
    
    /// Update frequency
    public let updateFrequency: UpdateFrequency
    
    /// Buffer for incoming data
    private var buffer: [T] = []
    
    /// Lock for thread safety
    private let lock = NSLock()
    
    /// Timer for flushing buffer
    private var flushTimer: Timer?
    
    /// Timestamps for rate calculation
    private var timestamps: [Date] = []
    
    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Creates a real-time data stream.
    public init(
        windowSize: Int = 100,
        updateFrequency: UpdateFrequency = .fps30
    ) {
        self.windowSize = windowSize
        self.updateFrequency = updateFrequency
        
        setupFlushTimer()
    }
    
    deinit {
        flushTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Pushes a single value to the stream.
    public func push(value: T) {
        lock.lock()
        defer { lock.unlock() }
        
        buffer.append(value)
        timestamps.append(Date())
        
        // Clean old timestamps (keep last second)
        let cutoff = Date().addingTimeInterval(-1)
        timestamps = timestamps.filter { $0 > cutoff }
    }
    
    /// Pushes multiple values to the stream.
    public func push(values: [T]) {
        lock.lock()
        defer { lock.unlock() }
        
        buffer.append(contentsOf: values)
        let now = Date()
        timestamps.append(contentsOf: Array(repeating: now, count: values.count))
        
        let cutoff = now.addingTimeInterval(-1)
        timestamps = timestamps.filter { $0 > cutoff }
    }
    
    /// Starts the stream.
    public func start() {
        isActive = true
        setupFlushTimer()
    }
    
    /// Stops the stream.
    public func stop() {
        isActive = false
        flushTimer?.invalidate()
        flushTimer = nil
    }
    
    /// Clears all data.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        buffer.removeAll()
        data.removeAll()
        timestamps.removeAll()
    }
    
    /// Replaces all data.
    public func setData(_ newData: [T]) {
        lock.lock()
        defer { lock.unlock() }
        
        buffer.removeAll()
        data = Array(newData.suffix(windowSize))
    }
    
    // MARK: - Private Methods
    
    private func setupFlushTimer() {
        flushTimer?.invalidate()
        
        let interval = 1.0 / updateFrequency.fps
        flushTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.flush()
            }
        }
    }
    
    private func flush() {
        lock.lock()
        let bufferedData = buffer
        buffer.removeAll(keepingCapacity: true)
        let currentTimestampCount = timestamps.count
        lock.unlock()
        
        guard !bufferedData.isEmpty else { return }
        
        // Append new data and maintain window size
        var newData = data
        newData.append(contentsOf: bufferedData)
        
        if newData.count > windowSize {
            newData = Array(newData.suffix(windowSize))
        }
        
        // Update on main thread
        data = newData
        dataRate = Double(currentTimestampCount)
    }
}

// MARK: - Update Frequency

/// Update frequency options for real-time streams.
public enum UpdateFrequency: CaseIterable {
    case fps15
    case fps30
    case fps60
    case fps120
    case custom(Double)
    
    public var fps: Double {
        switch self {
        case .fps15: return 15
        case .fps30: return 30
        case .fps60: return 60
        case .fps120: return 120
        case .custom(let value): return value
        }
    }
    
    public static var allCases: [UpdateFrequency] {
        [.fps15, .fps30, .fps60, .fps120]
    }
}

// MARK: - Time Series Data Point

/// A data point with timestamp for time-series charts.
public struct TimeSeriesPoint<T>: Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let value: T
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), value: T) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
    }
}

// MARK: - Real-Time Line Chart

/// A line chart optimized for real-time data streaming.
public struct RealTimeLineChart: View {
    @ObservedObject var stream: RealTimeDataStream<Double>
    
    let color: Color
    let lineWidth: CGFloat
    let showPoints: Bool
    let showGrid: Bool
    let showDataRate: Bool
    
    @State private var animationProgress: CGFloat = 1
    
    public init(
        stream: RealTimeDataStream<Double>,
        color: Color = .blue,
        lineWidth: CGFloat = 2,
        showPoints: Bool = false,
        showGrid: Bool = true,
        showDataRate: Bool = true
    ) {
        self.stream = stream
        self.color = color
        self.lineWidth = lineWidth
        self.showPoints = showPoints
        self.showGrid = showGrid
        self.showDataRate = showDataRate
    }
    
    private var minValue: Double {
        stream.data.min() ?? 0
    }
    
    private var maxValue: Double {
        stream.data.max() ?? 100
    }
    
    private var valueRange: Double {
        max(maxValue - minValue, 0.001)
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            if showDataRate {
                HStack {
                    Circle()
                        .fill(stream.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text("\(Int(stream.dataRate)) pts/sec")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(stream.data.count)/\(stream.windowSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
            }
            
            GeometryReader { geometry in
                let chartArea = CGRect(
                    x: 40,
                    y: 8,
                    width: geometry.size.width - 56,
                    height: geometry.size.height - 24
                )
                
                ZStack(alignment: .topLeading) {
                    // Grid
                    if showGrid {
                        gridView(chartArea: chartArea)
                    }
                    
                    // Y-axis labels
                    yAxisLabels(chartArea: chartArea)
                    
                    // Line
                    linePath(chartArea: chartArea)
                        .offset(x: chartArea.minX, y: chartArea.minY)
                    
                    // Points
                    if showPoints && stream.data.count <= 100 {
                        pointsView(chartArea: chartArea)
                            .offset(x: chartArea.minX, y: chartArea.minY)
                    }
                }
            }
        }
    }
    
    private func gridView(chartArea: CGRect) -> some View {
        ZStack {
            ForEach(0...4, id: \.self) { i in
                let y = chartArea.minY + chartArea.height * CGFloat(i) / 4
                
                Path { path in
                    path.move(to: CGPoint(x: chartArea.minX, y: y))
                    path.addLine(to: CGPoint(x: chartArea.maxX, y: y))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            }
        }
    }
    
    private func yAxisLabels(chartArea: CGRect) -> some View {
        ForEach(0...4, id: \.self) { i in
            let value = maxValue - valueRange * Double(i) / 4
            let y = chartArea.minY + chartArea.height * CGFloat(i) / 4
            
            Text(formatValue(value))
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .position(x: 20, y: y)
        }
    }
    
    private func linePath(chartArea: CGRect) -> some View {
        Path { path in
            guard stream.data.count >= 2 else { return }
            
            for (index, value) in stream.data.enumerated() {
                let x = chartArea.width * CGFloat(index) / CGFloat(max(stream.data.count - 1, 1))
                let normalizedY = (value - minValue) / valueRange
                let y = chartArea.height * (1 - CGFloat(normalizedY))
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(
            LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func pointsView(chartArea: CGRect) -> some View {
        ForEach(Array(stream.data.enumerated()), id: \.offset) { index, value in
            let x = chartArea.width * CGFloat(index) / CGFloat(max(stream.data.count - 1, 1))
            let normalizedY = (value - minValue) / valueRange
            let y = chartArea.height * (1 - CGFloat(normalizedY))
            
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .position(x: x, y: y)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if abs(value) >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else if value == value.rounded() {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - WebSocket Data Source

/// A WebSocket-based data source for real-time charts.
@MainActor
public final class WebSocketDataSource: ObservableObject {
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var lastError: Error?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    private var messageHandler: ((String) -> Void)?
    
    public init(url: URL) {
        self.url = url
    }
    
    public func connect(onMessage: @escaping (String) -> Void) {
        self.messageHandler = onMessage
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        isConnected = true
        receiveMessage()
    }
    
    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    public func send(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                Task { @MainActor in
                    self?.lastError = error
                }
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    Task { @MainActor in
                        self?.messageHandler?(text)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            self?.messageHandler?(text)
                        }
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving
                self?.receiveMessage()
                
            case .failure(let error):
                Task { @MainActor in
                    self?.lastError = error
                    self?.isConnected = false
                }
            }
        }
    }
}

// MARK: - Data Generator (for testing)

/// Generates simulated real-time data for testing.
@MainActor
public final class SimulatedDataGenerator: ObservableObject {
    @Published public private(set) var isRunning: Bool = false
    
    private var timer: Timer?
    private var baseValue: Double = 50
    private let stream: RealTimeDataStream<Double>
    
    public init(stream: RealTimeDataStream<Double>) {
        self.stream = stream
    }
    
    public func start(interval: TimeInterval = 0.05) {
        guard !isRunning else { return }
        
        isRunning = true
        stream.start()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.generateValue()
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        stream.stop()
    }
    
    private func generateValue() {
        // Random walk with mean reversion
        let noise = Double.random(in: -2...2)
        let meanReversion = (50 - baseValue) * 0.05
        baseValue += noise + meanReversion
        baseValue = max(0, min(100, baseValue))
        
        stream.push(value: baseValue)
    }
}
