import SwiftUI

// MARK: - Candlestick Chart

/// A financial chart showing open, high, low, and close prices.
///
/// Candlestick charts are essential for financial analysis, showing price
/// movements over time with visual indicators for bullish and bearish periods.
///
/// ```swift
/// let data = [
///     CandlestickData(date: Date(), open: 100, high: 110, low: 95, close: 105),
///     CandlestickData(date: Date().addingTimeInterval(86400), open: 105, high: 115, low: 100, close: 108)
/// ]
///
/// CandlestickChart(data: data)
/// ```
public struct CandlestickChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The candlestick data points
    public let data: [CandlestickData]
    
    /// Color for bullish (price up) candles
    public let bullishColor: Color
    
    /// Color for bearish (price down) candles
    public let bearishColor: Color
    
    /// Width of each candlestick body
    public let candleWidth: CGFloat
    
    /// Width of the wick/shadow line
    public let wickWidth: CGFloat
    
    /// Spacing between candles
    public let spacing: CGFloat
    
    /// Whether to show volume bars
    public let showVolume: Bool
    
    /// Height ratio for volume section
    public let volumeHeightRatio: CGFloat
    
    /// Whether to show grid lines
    public let showGrid: Bool
    
    /// Number of price levels for grid
    public let priceLevels: Int
    
    /// Whether to show price labels
    public let showPriceLabels: Bool
    
    /// Whether to show date labels
    public let showDateLabels: Bool
    
    /// Date format for labels
    public let dateFormat: String
    
    /// Price format
    public let priceFormat: String
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedIndex: Int?
    @State private var hoveredIndex: Int?
    
    /// Creates a candlestick chart.
    public init(
        data: [CandlestickData],
        bullishColor: Color = .green,
        bearishColor: Color = .red,
        candleWidth: CGFloat = 8,
        wickWidth: CGFloat = 1,
        spacing: CGFloat = 4,
        showVolume: Bool = true,
        volumeHeightRatio: CGFloat = 0.2,
        showGrid: Bool = true,
        priceLevels: Int = 5,
        showPriceLabels: Bool = true,
        showDateLabels: Bool = true,
        dateFormat: String = "MM/dd",
        priceFormat: String = "%.2f"
    ) {
        self.data = data
        self.bullishColor = bullishColor
        self.bearishColor = bearishColor
        self.candleWidth = candleWidth
        self.wickWidth = wickWidth
        self.spacing = spacing
        self.showVolume = showVolume
        self.volumeHeightRatio = volumeHeightRatio
        self.showGrid = showGrid
        self.priceLevels = priceLevels
        self.showPriceLabels = showPriceLabels
        self.showDateLabels = showDateLabels
        self.dateFormat = dateFormat
        self.priceFormat = priceFormat
    }
    
    private var priceRange: (min: Double, max: Double) {
        let lows = data.map { $0.low }
        let highs = data.map { $0.high }
        let minPrice = lows.min() ?? 0
        let maxPrice = highs.max() ?? 100
        let padding = (maxPrice - minPrice) * 0.1
        return (minPrice - padding, maxPrice + padding)
    }
    
    private var volumeMax: Double {
        data.compactMap { $0.volume }.max() ?? 1
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let labelWidth: CGFloat = showPriceLabels ? 60 : 0
            let dateHeight: CGFloat = showDateLabels ? 20 : 0
            let volumeHeight = showVolume ? geometry.size.height * volumeHeightRatio : 0
            let chartWidth = geometry.size.width - labelWidth
            let chartHeight = geometry.size.height - dateHeight - volumeHeight
            
            VStack(spacing: 0) {
                // Main price chart
                ZStack(alignment: .topLeading) {
                    // Grid
                    if showGrid {
                        priceGrid(width: chartWidth, height: chartHeight)
                    }
                    
                    // Price labels
                    if showPriceLabels {
                        priceLabels(height: chartHeight)
                            .offset(x: chartWidth)
                    }
                    
                    // Candlesticks
                    HStack(spacing: spacing) {
                        ForEach(Array(data.enumerated()), id: \.offset) { index, candle in
                            candlestickView(
                                candle: candle,
                                index: index,
                                height: chartHeight
                            )
                        }
                    }
                    .padding(.horizontal, spacing)
                    
                    // Selection tooltip
                    if let index = selectedIndex, index < data.count {
                        tooltipView(for: data[index])
                    }
                }
                .frame(height: chartHeight)
                
                // Volume chart
                if showVolume {
                    volumeChart(width: chartWidth, height: volumeHeight)
                }
                
                // Date labels
                if showDateLabels {
                    dateLabels(width: chartWidth)
                        .frame(height: dateHeight)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Candlestick chart with \(data.count) candles")
    }
    
    // MARK: - Price Grid
    
    private func priceGrid(width: CGFloat, height: CGFloat) -> some View {
        let prices = generatePriceLevels()
        
        return ZStack(alignment: .topLeading) {
            ForEach(prices, id: \.self) { price in
                let y = priceToY(price, height: height)
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(theme.gridColor, style: StrokeStyle(lineWidth: 0.5, dash: [4, 2]))
            }
        }
    }
    
    private func generatePriceLevels() -> [Double] {
        let range = priceRange.max - priceRange.min
        let step = range / Double(priceLevels - 1)
        
        return (0..<priceLevels).map { i in
            priceRange.min + step * Double(i)
        }
    }
    
    private func priceToY(_ price: Double, height: CGFloat) -> CGFloat {
        let range = priceRange.max - priceRange.min
        guard range > 0 else { return height / 2 }
        return height - (CGFloat((price - priceRange.min) / range) * height)
    }
    
    // MARK: - Price Labels
    
    private func priceLabels(height: CGFloat) -> some View {
        let prices = generatePriceLevels()
        
        return ZStack(alignment: .topLeading) {
            ForEach(prices, id: \.self) { price in
                let y = priceToY(price, height: height)
                
                Text(String(format: priceFormat, price))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(x: 30, y: y)
            }
        }
        .frame(width: 60)
    }
    
    // MARK: - Candlestick View
    
    @ViewBuilder
    private func candlestickView(candle: CandlestickData, index: Int, height: CGFloat) -> some View {
        let isBullish = candle.close >= candle.open
        let color = isBullish ? bullishColor : bearishColor
        let isSelected = selectedIndex == index
        let isHovered = hoveredIndex == index
        
        let highY = priceToY(candle.high, height: height)
        let lowY = priceToY(candle.low, height: height)
        let openY = priceToY(candle.open, height: height)
        let closeY = priceToY(candle.close, height: height)
        
        let bodyTop = min(openY, closeY)
        let bodyBottom = max(openY, closeY)
        let bodyHeight = max(1, bodyBottom - bodyTop)
        
        ZStack {
            // Wick (high to low)
            Rectangle()
                .fill(color)
                .frame(width: wickWidth, height: (lowY - highY) * animationProgress)
                .position(x: candleWidth / 2, y: highY + (lowY - highY) / 2)
            
            // Body
            RoundedRectangle(cornerRadius: 1)
                .fill(isBullish ? color.opacity(0.3) : color)
                .frame(width: candleWidth, height: bodyHeight * animationProgress)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(color, lineWidth: 1)
                )
                .position(x: candleWidth / 2, y: bodyTop + bodyHeight / 2)
            
            // Selection highlight
            if isSelected || isHovered {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(theme.accentColor, lineWidth: 2)
                    .frame(width: candleWidth + 4, height: (lowY - highY) + 4)
                    .position(x: candleWidth / 2, y: highY + (lowY - highY) / 2)
            }
        }
        .frame(width: candleWidth, height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = selectedIndex == index ? nil : index
            }
        }
        .onHover { hovering in
            hoveredIndex = hovering ? index : nil
        }
        .accessibilityElement()
        .accessibilityLabel("Candle \(index + 1): Open \(String(format: priceFormat, candle.open)), Close \(String(format: priceFormat, candle.close))")
    }
    
    // MARK: - Volume Chart
    
    private func volumeChart(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, candle in
                if let volume = candle.volume {
                    let isBullish = candle.close >= candle.open
                    let color = isBullish ? bullishColor : bearishColor
                    let barHeight = CGFloat(volume / volumeMax) * height * animationProgress
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color.opacity(0.5))
                        .frame(width: candleWidth, height: barHeight)
                }
            }
        }
        .frame(height: height, alignment: .bottom)
        .padding(.horizontal, spacing)
        .background(
            Rectangle()
                .fill(theme.gridColor.opacity(0.1))
        )
    }
    
    // MARK: - Date Labels
    
    private func dateLabels(width: CGFloat) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        
        let labelInterval = max(1, data.count / 5)
        
        return HStack(spacing: spacing) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, candle in
                if index % labelInterval == 0 {
                    Text(formatter.string(from: candle.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: candleWidth)
                } else {
                    Spacer()
                        .frame(width: candleWidth)
                }
            }
        }
        .padding(.horizontal, spacing)
    }
    
    // MARK: - Tooltip
    
    @ViewBuilder
    private func tooltipView(for candle: CandlestickData) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        
        VStack(alignment: .leading, spacing: 4) {
            Text(formatter.string(from: candle.date))
                .font(.caption.bold())
            
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("O: \(String(format: priceFormat, candle.open))")
                    Text("H: \(String(format: priceFormat, candle.high))")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("L: \(String(format: priceFormat, candle.low))")
                    Text("C: \(String(format: priceFormat, candle.close))")
                }
            }
            .font(.caption2)
            
            if let volume = candle.volume {
                Text("Vol: \(formatVolume(volume))")
                    .font(.caption2)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
        )
        .foregroundColor(theme.foregroundColor)
        .position(x: 80, y: 50)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", volume / 1_000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Candlestick Data

/// Data for a single candlestick.
public struct CandlestickData: Identifiable, Equatable {
    public let id: UUID
    
    /// The date/time for this candle
    public let date: Date
    
    /// Opening price
    public let open: Double
    
    /// Highest price
    public let high: Double
    
    /// Lowest price
    public let low: Double
    
    /// Closing price
    public let close: Double
    
    /// Trading volume (optional)
    public var volume: Double?
    
    /// Creates candlestick data.
    public init(
        id: UUID = UUID(),
        date: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volume: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
    
    /// Whether the candle is bullish (close >= open)
    public var isBullish: Bool { close >= open }
    
    /// The body size (difference between open and close)
    public var bodySize: Double { abs(close - open) }
    
    /// The wick/shadow size
    public var wickSize: Double { high - low }
    
    /// The upper shadow size
    public var upperShadow: Double { high - max(open, close) }
    
    /// The lower shadow size
    public var lowerShadow: Double { min(open, close) - low }
}

// MARK: - Preview Provider

#if DEBUG
struct CandlestickChart_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let today = Date()
        
        let data = (0..<20).map { i -> CandlestickData in
            let date = calendar.date(byAdding: .day, value: i, to: today) ?? today
            let base = 100.0 + Double(i) * 0.5 + Double.random(in: -5...5)
            let open = base + Double.random(in: -2...2)
            let close = base + Double.random(in: -2...2)
            let high = max(open, close) + Double.random(in: 0...3)
            let low = min(open, close) - Double.random(in: 0...3)
            let volume = Double.random(in: 100_000...500_000)
            
            return CandlestickData(date: date, open: open, high: high, low: low, close: close, volume: volume)
        }
        
        CandlestickChart(data: data)
            .frame(height: 400)
            .padding()
    }
}
#endif
