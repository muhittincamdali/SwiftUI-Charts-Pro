import Foundation
import SwiftUI

// MARK: - Chart Math Utilities

/// Mathematical utilities for chart calculations.
public enum ChartMath {
    
    // MARK: - Statistical Functions
    
    /// Calculates the mean of an array of values.
    public static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    /// Calculates the median of an array of values.
    public static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let n = sorted.count
        
        if n % 2 == 0 {
            return (sorted[n/2 - 1] + sorted[n/2]) / 2
        }
        return sorted[n/2]
    }
    
    /// Calculates the mode of an array of values.
    public static func mode(_ values: [Double], precision: Int = 2) -> Double? {
        guard !values.isEmpty else { return nil }
        
        let factor = pow(10.0, Double(precision))
        let rounded = values.map { round($0 * factor) / factor }
        
        var counts: [Double: Int] = [:]
        for value in rounded {
            counts[value, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Calculates the variance of an array of values.
    public static func variance(_ values: [Double], population: Bool = false) -> Double {
        guard values.count > 1 else { return 0 }
        
        let avg = mean(values)
        let sumSquaredDiff = values.reduce(0) { $0 + ($1 - avg) * ($1 - avg) }
        
        let divisor = population ? Double(values.count) : Double(values.count - 1)
        return sumSquaredDiff / divisor
    }
    
    /// Calculates the standard deviation of an array of values.
    public static func standardDeviation(_ values: [Double], population: Bool = false) -> Double {
        sqrt(variance(values, population: population))
    }
    
    /// Calculates the coefficient of variation.
    public static func coefficientOfVariation(_ values: [Double]) -> Double {
        let avg = mean(values)
        guard avg != 0 else { return 0 }
        return standardDeviation(values) / avg
    }
    
    /// Calculates the skewness of a distribution.
    public static func skewness(_ values: [Double]) -> Double {
        let n = Double(values.count)
        guard n > 2 else { return 0 }
        
        let avg = mean(values)
        let std = standardDeviation(values)
        guard std > 0 else { return 0 }
        
        let sumCubed = values.reduce(0) { result, value in
            let z = (value - avg) / std
            return result + z * z * z
        }
        
        return (n / ((n - 1) * (n - 2))) * sumCubed
    }
    
    /// Calculates the kurtosis of a distribution.
    public static func kurtosis(_ values: [Double]) -> Double {
        let n = Double(values.count)
        guard n > 3 else { return 0 }
        
        let avg = mean(values)
        let std = standardDeviation(values)
        guard std > 0 else { return 0 }
        
        let sumFourth = values.reduce(0) { result, value in
            let z = (value - avg) / std
            return result + z * z * z * z
        }
        
        let coefficient = (n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))
        let correction = (3 * (n - 1) * (n - 1)) / ((n - 2) * (n - 3))
        
        return coefficient * sumFourth - correction
    }
    
    /// Calculates percentile value.
    public static func percentile(_ values: [Double], p: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        guard p >= 0 && p <= 100 else { return 0 }
        
        let sorted = values.sorted()
        let index = (p / 100) * Double(sorted.count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        
        if lower == upper {
            return sorted[lower]
        }
        
        let fraction = index - Double(lower)
        return sorted[lower] + fraction * (sorted[upper] - sorted[lower])
    }
    
    /// Calculates quartiles (Q1, Q2, Q3).
    public static func quartiles(_ values: [Double]) -> (q1: Double, q2: Double, q3: Double) {
        (
            percentile(values, p: 25),
            percentile(values, p: 50),
            percentile(values, p: 75)
        )
    }
    
    /// Calculates the interquartile range.
    public static func interquartileRange(_ values: [Double]) -> Double {
        let q = quartiles(values)
        return q.q3 - q.q1
    }
    
    // MARK: - Correlation & Regression
    
    /// Calculates Pearson correlation coefficient.
    public static func correlation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let meanX = mean(x)
        let meanY = mean(y)
        
        var sumXY: Double = 0
        var sumX2: Double = 0
        var sumY2: Double = 0
        
        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }
        
        let denominator = sqrt(sumX2 * sumY2)
        guard denominator > 0 else { return 0 }
        
        return sumXY / denominator
    }
    
    /// Performs simple linear regression.
    public static func linearRegression(_ x: [Double], _ y: [Double]) -> (slope: Double, intercept: Double, rSquared: Double) {
        guard x.count == y.count, x.count > 1 else {
            return (0, 0, 0)
        }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).reduce(0) { $0 + $1.0 * $1.1 }
        let sumX2 = x.reduce(0) { $0 + $1 * $1 }
        
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return (0, 0, 0) }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        let r = correlation(x, y)
        let rSquared = r * r
        
        return (slope, intercept, rSquared)
    }
    
    /// Predicts Y value from linear regression.
    public static func predict(x: Double, slope: Double, intercept: Double) -> Double {
        slope * x + intercept
    }
    
    // MARK: - Normalization
    
    /// Normalizes values to a 0-1 range.
    public static func normalize(_ values: [Double]) -> [Double] {
        guard let min = values.min(), let max = values.max(), max != min else {
            return values.map { _ in 0.5 }
        }
        return values.map { ($0 - min) / (max - min) }
    }
    
    /// Normalizes values to a custom range.
    public static func normalize(_ values: [Double], to range: ClosedRange<Double>) -> [Double] {
        guard let min = values.min(), let max = values.max(), max != min else {
            return values.map { _ in (range.lowerBound + range.upperBound) / 2 }
        }
        
        let normalized = normalize(values)
        let rangeSize = range.upperBound - range.lowerBound
        return normalized.map { $0 * rangeSize + range.lowerBound }
    }
    
    /// Applies z-score normalization.
    public static func zScoreNormalize(_ values: [Double]) -> [Double] {
        let avg = mean(values)
        let std = standardDeviation(values)
        guard std > 0 else { return values.map { _ in 0 } }
        return values.map { ($0 - avg) / std }
    }
    
    // MARK: - Scale Calculations
    
    /// Generates nice tick values for an axis.
    public static func niceTickValues(min: Double, max: Double, count: Int) -> [Double] {
        guard max > min, count > 1 else { return [] }
        
        let range = max - min
        let roughStep = range / Double(count - 1)
        
        // Find the magnitude
        let magnitude = pow(10, floor(log10(roughStep)))
        
        // Calculate nice step
        let residual = roughStep / magnitude
        let niceStep: Double
        
        if residual <= 1.5 {
            niceStep = magnitude
        } else if residual <= 3 {
            niceStep = 2 * magnitude
        } else if residual <= 7 {
            niceStep = 5 * magnitude
        } else {
            niceStep = 10 * magnitude
        }
        
        // Generate ticks
        let niceMin = floor(min / niceStep) * niceStep
        let niceMax = ceil(max / niceStep) * niceStep
        
        var ticks: [Double] = []
        var current = niceMin
        
        while current <= niceMax {
            ticks.append(current)
            current += niceStep
        }
        
        return ticks
    }
    
    /// Calculates optimal bin count for histograms using Sturges' rule.
    public static func optimalBinCount(_ values: [Double]) -> Int {
        max(1, Int(ceil(log2(Double(values.count)) + 1)))
    }
    
    /// Calculates optimal bin width using Freedman-Diaconis rule.
    public static func optimalBinWidth(_ values: [Double]) -> Double {
        let iqr = interquartileRange(values)
        let n = Double(values.count)
        return 2 * iqr * pow(n, -1/3)
    }
    
    // MARK: - Geometry
    
    /// Converts degrees to radians.
    public static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
    
    /// Converts radians to degrees.
    public static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
    
    /// Calculates point on a circle.
    public static func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let radians = degreesToRadians(angle)
        return CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
    }
    
    /// Calculates distance between two points.
    public static func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
    
    /// Calculates angle between two points in degrees.
    public static func angle(from p1: CGPoint, to p2: CGPoint) -> Double {
        radiansToDegrees(atan2(Double(p2.y - p1.y), Double(p2.x - p1.x)))
    }
    
    /// Linear interpolation between two values.
    public static func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
        a + (b - a) * t
    }
    
    /// Clamps a value to a range.
    public static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }
    
    // MARK: - Moving Averages
    
    /// Calculates simple moving average.
    public static func simpleMovingAverage(_ values: [Double], window: Int) -> [Double] {
        guard window > 0, window <= values.count else { return values }
        
        var result: [Double] = []
        
        for i in (window - 1)..<values.count {
            let windowValues = Array(values[(i - window + 1)...i])
            result.append(mean(windowValues))
        }
        
        return result
    }
    
    /// Calculates exponential moving average.
    public static func exponentialMovingAverage(_ values: [Double], alpha: Double) -> [Double] {
        guard !values.isEmpty else { return [] }
        
        var result: [Double] = [values[0]]
        
        for i in 1..<values.count {
            let ema = alpha * values[i] + (1 - alpha) * result[i - 1]
            result.append(ema)
        }
        
        return result
    }
}

// MARK: - Preview

#if DEBUG
struct ChartMath_Previews: PreviewProvider {
    static var previews: some View {
        let values = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0]
        
        VStack(alignment: .leading, spacing: 10) {
            Text("Mean: \(ChartMath.mean(values), specifier: "%.2f")")
            Text("Median: \(ChartMath.median(values), specifier: "%.2f")")
            Text("Std Dev: \(ChartMath.standardDeviation(values), specifier: "%.2f")")
            Text("Variance: \(ChartMath.variance(values), specifier: "%.2f")")
            
            let q = ChartMath.quartiles(values)
            Text("Quartiles: Q1=\(q.q1, specifier: "%.1f"), Q2=\(q.q2, specifier: "%.1f"), Q3=\(q.q3, specifier: "%.1f")")
        }
        .font(.system(.body, design: .monospaced))
        .padding()
    }
}
#endif
