import SwiftUI

// MARK: - Word Cloud Chart

/// A visualization of text data where word size represents frequency or weight.
///
/// Word clouds are effective for displaying tag frequencies, keyword analysis,
/// or any text-based data where relative importance should be visualized.
///
/// ```swift
/// let words = [
///     WordCloudItem(text: "Swift", weight: 100),
///     WordCloudItem(text: "iOS", weight: 80),
///     WordCloudItem(text: "SwiftUI", weight: 90)
/// ]
///
/// WordCloudChart(words: words)
/// ```
public struct WordCloudChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The words to display
    public let words: [WordCloudItem]
    
    /// Minimum font size
    public let minFontSize: CGFloat
    
    /// Maximum font size
    public let maxFontSize: CGFloat
    
    /// Font weight
    public let fontWeight: Font.Weight
    
    /// Font design
    public let fontDesign: Font.Design
    
    /// Whether to use random colors from palette
    public let useRandomColors: Bool
    
    /// Whether to use random rotations
    public let useRandomRotations: Bool
    
    /// Allowed rotation angles
    public let rotationAngles: [Double]
    
    /// Padding between words
    public let wordPadding: CGFloat
    
    /// Layout algorithm
    public let layout: WordCloudLayout
    
    @State private var animationProgress: CGFloat = 0
    @State private var wordPositions: [UUID: WordPosition] = [:]
    @State private var selectedWord: UUID?
    @State private var hoveredWord: UUID?
    
    /// Creates a word cloud chart.
    public init(
        words: [WordCloudItem],
        minFontSize: CGFloat = 12,
        maxFontSize: CGFloat = 48,
        fontWeight: Font.Weight = .medium,
        fontDesign: Font.Design = .default,
        useRandomColors: Bool = true,
        useRandomRotations: Bool = true,
        rotationAngles: [Double] = [0, -90, 90],
        wordPadding: CGFloat = 4,
        layout: WordCloudLayout = .spiral
    ) {
        self.words = words
        self.minFontSize = minFontSize
        self.maxFontSize = maxFontSize
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.useRandomColors = useRandomColors
        self.useRandomRotations = useRandomRotations
        self.rotationAngles = rotationAngles
        self.wordPadding = wordPadding
        self.layout = layout
    }
    
    private var sortedWords: [WordCloudItem] {
        words.sorted { $0.weight > $1.weight }
    }
    
    private var weightRange: (min: Double, max: Double) {
        let weights = words.map { $0.weight }
        return (weights.min() ?? 1, weights.max() ?? 1)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(sortedWords.enumerated()), id: \.element.id) { index, word in
                    wordView(word: word, index: index, size: geometry.size)
                }
            }
            .onAppear {
                calculatePositions(size: geometry.size)
                withAnimation(.easeOut(duration: theme.animationDuration)) {
                    animationProgress = 1
                }
            }
            .onChange(of: geometry.size) { newSize in
                calculatePositions(size: newSize)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Word cloud with \(words.count) words")
    }
    
    // MARK: - Word View
    
    @ViewBuilder
    private func wordView(word: WordCloudItem, index: Int, size: CGSize) -> some View {
        let fontSize = fontSizeFor(weight: word.weight)
        let color = wordColor(for: word, index: index)
        let rotation = wordRotation(for: word)
        let position = wordPositions[word.id] ?? WordPosition(x: size.width / 2, y: size.height / 2, rotation: 0)
        let isSelected = selectedWord == word.id
        let isHovered = hoveredWord == word.id
        
        Text(word.text)
            .font(.system(size: fontSize * animationProgress, weight: fontWeight, design: fontDesign))
            .foregroundColor(color)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(isSelected ? 1.2 : (isHovered ? 1.1 : 1.0))
            .opacity(animationProgress)
            .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 4)
            .position(x: position.x, y: position.y)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedWord = selectedWord == word.id ? nil : word.id
                }
            }
            .onHover { hovering in
                hoveredWord = hovering ? word.id : nil
            }
            .accessibilityElement()
            .accessibilityLabel("\(word.text), weight: \(Int(word.weight))")
    }
    
    // MARK: - Helpers
    
    private func fontSizeFor(weight: Double) -> CGFloat {
        let range = weightRange.max - weightRange.min
        guard range > 0 else { return (minFontSize + maxFontSize) / 2 }
        
        let normalized = (weight - weightRange.min) / range
        return minFontSize + (maxFontSize - minFontSize) * CGFloat(normalized)
    }
    
    private func wordColor(for word: WordCloudItem, index: Int) -> Color {
        if let color = word.color {
            return color
        }
        if useRandomColors {
            return theme.color(at: index)
        }
        return theme.accentColor
    }
    
    private func wordRotation(for word: WordCloudItem) -> Double {
        guard useRandomRotations, !rotationAngles.isEmpty else { return 0 }
        
        // Use word text hash for consistent rotation
        let hash = abs(word.text.hashValue)
        return rotationAngles[hash % rotationAngles.count]
    }
    
    // MARK: - Layout Calculation
    
    private func calculatePositions(size: CGSize) {
        var newPositions: [UUID: WordPosition] = [:]
        var occupiedRects: [CGRect] = []
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for (index, word) in sortedWords.enumerated() {
            let fontSize = fontSizeFor(weight: word.weight)
            let rotation = wordRotation(for: word)
            let wordSize = estimateWordSize(word.text, fontSize: fontSize, rotation: rotation)
            
            var position: CGPoint
            
            switch layout {
            case .spiral:
                position = findSpiralPosition(
                    wordSize: wordSize,
                    center: center,
                    occupiedRects: occupiedRects,
                    maxSize: size
                )
            case .random:
                position = findRandomPosition(
                    wordSize: wordSize,
                    occupiedRects: occupiedRects,
                    maxSize: size
                )
            case .circular:
                position = findCircularPosition(
                    index: index,
                    total: sortedWords.count,
                    center: center,
                    radius: min(size.width, size.height) * 0.35
                )
            case .grid:
                position = findGridPosition(
                    index: index,
                    wordSize: wordSize,
                    maxSize: size
                )
            }
            
            newPositions[word.id] = WordPosition(x: position.x, y: position.y, rotation: rotation)
            
            let rect = CGRect(
                x: position.x - wordSize.width / 2 - wordPadding,
                y: position.y - wordSize.height / 2 - wordPadding,
                width: wordSize.width + wordPadding * 2,
                height: wordSize.height + wordPadding * 2
            )
            occupiedRects.append(rect)
        }
        
        wordPositions = newPositions
    }
    
    private func estimateWordSize(_ text: String, fontSize: CGFloat, rotation: Double) -> CGSize {
        let baseWidth = CGFloat(text.count) * fontSize * 0.6
        let baseHeight = fontSize * 1.2
        
        if abs(rotation) == 90 {
            return CGSize(width: baseHeight, height: baseWidth)
        }
        return CGSize(width: baseWidth, height: baseHeight)
    }
    
    private func findSpiralPosition(wordSize: CGSize, center: CGPoint, occupiedRects: [CGRect], maxSize: CGSize) -> CGPoint {
        var angle: Double = 0
        var radius: Double = 0
        let angleStep: Double = 0.5
        let radiusStep: Double = 2
        
        for _ in 0..<1000 {
            let x = center.x + CGFloat(radius * cos(angle))
            let y = center.y + CGFloat(radius * sin(angle))
            
            let rect = CGRect(
                x: x - wordSize.width / 2,
                y: y - wordSize.height / 2,
                width: wordSize.width,
                height: wordSize.height
            )
            
            let inBounds = rect.minX >= 0 && rect.maxX <= maxSize.width &&
                          rect.minY >= 0 && rect.maxY <= maxSize.height
            
            let noOverlap = !occupiedRects.contains { $0.intersects(rect) }
            
            if inBounds && noOverlap {
                return CGPoint(x: x, y: y)
            }
            
            angle += angleStep
            radius += radiusStep / (2 * .pi)
        }
        
        return center
    }
    
    private func findRandomPosition(wordSize: CGSize, occupiedRects: [CGRect], maxSize: CGSize) -> CGPoint {
        for _ in 0..<100 {
            let x = CGFloat.random(in: wordSize.width/2...(maxSize.width - wordSize.width/2))
            let y = CGFloat.random(in: wordSize.height/2...(maxSize.height - wordSize.height/2))
            
            let rect = CGRect(
                x: x - wordSize.width / 2,
                y: y - wordSize.height / 2,
                width: wordSize.width,
                height: wordSize.height
            )
            
            if !occupiedRects.contains(where: { $0.intersects(rect) }) {
                return CGPoint(x: x, y: y)
            }
        }
        
        return CGPoint(x: maxSize.width / 2, y: maxSize.height / 2)
    }
    
    private func findCircularPosition(index: Int, total: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (Double(index) / Double(total)) * 2 * .pi - .pi / 2
        let r = radius * (0.5 + 0.5 * Double(total - index) / Double(total))
        
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * CGFloat(r),
            y: center.y + CGFloat(sin(angle)) * CGFloat(r)
        )
    }
    
    private func findGridPosition(index: Int, wordSize: CGSize, maxSize: CGSize) -> CGPoint {
        let columns = Int(maxSize.width / 100)
        let row = index / columns
        let col = index % columns
        
        let cellWidth = maxSize.width / CGFloat(columns)
        let cellHeight: CGFloat = 50
        
        return CGPoint(
            x: cellWidth * (CGFloat(col) + 0.5),
            y: cellHeight * (CGFloat(row) + 0.5) + 20
        )
    }
}

// MARK: - Supporting Types

/// Word position data
private struct WordPosition {
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
}

/// Word cloud layout algorithm
public enum WordCloudLayout {
    /// Spiral layout from center
    case spiral
    
    /// Random placement
    case random
    
    /// Circular arrangement
    case circular
    
    /// Grid layout
    case grid
}

// MARK: - Preview Provider

#if DEBUG
struct WordCloudChart_Previews: PreviewProvider {
    static var previews: some View {
        let words = [
            WordCloudItem(text: "SwiftUI", weight: 100),
            WordCloudItem(text: "iOS", weight: 90),
            WordCloudItem(text: "Swift", weight: 85),
            WordCloudItem(text: "Apple", weight: 80),
            WordCloudItem(text: "Xcode", weight: 70),
            WordCloudItem(text: "UIKit", weight: 65),
            WordCloudItem(text: "macOS", weight: 60),
            WordCloudItem(text: "watchOS", weight: 50),
            WordCloudItem(text: "tvOS", weight: 45),
            WordCloudItem(text: "Combine", weight: 55),
            WordCloudItem(text: "Async", weight: 48),
            WordCloudItem(text: "Charts", weight: 75),
            WordCloudItem(text: "Animation", weight: 62),
            WordCloudItem(text: "Views", weight: 58)
        ]
        
        WordCloudChart(words: words)
            .frame(height: 400)
            .padding()
    }
}
#endif
