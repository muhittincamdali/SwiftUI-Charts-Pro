import SwiftUI

// MARK: - Chord Diagram

/// A circular visualization showing relationships between entities.
///
/// Chord diagrams display flows or connections between groups arranged
/// around a circle, with ribbon widths proportional to flow magnitude.
///
/// ```swift
/// let matrix = [
///     [0, 100, 50, 30],
///     [100, 0, 80, 20],
///     [50, 80, 0, 60],
///     [30, 20, 60, 0]
/// ]
///
/// ChordDiagram(matrix: matrix, labels: ["A", "B", "C", "D"])
/// ```
public struct ChordDiagram: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The flow matrix (source -> target)
    public let matrix: [[Double]]
    
    /// Labels for each group
    public let labels: [String]
    
    /// Padding between arcs in degrees
    public let arcPadding: Double
    
    /// Inner radius ratio
    public let innerRadiusRatio: CGFloat
    
    /// Whether to show labels
    public let showLabels: Bool
    
    /// Whether to show values on hover
    public let showValues: Bool
    
    /// Ribbon opacity
    public let ribbonOpacity: Double
    
    /// Value format string
    public let valueFormat: String
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedGroup: Int?
    @State private var selectedChord: ChordIdentifier?
    @State private var hoveredGroup: Int?
    
    /// Creates a chord diagram.
    public init(
        matrix: [[Double]],
        labels: [String],
        arcPadding: Double = 2,
        innerRadiusRatio: CGFloat = 0.9,
        showLabels: Bool = true,
        showValues: Bool = true,
        ribbonOpacity: Double = 0.6,
        valueFormat: String = "%.0f"
    ) {
        self.matrix = matrix
        self.labels = labels
        self.arcPadding = arcPadding
        self.innerRadiusRatio = innerRadiusRatio
        self.showLabels = showLabels
        self.showValues = showValues
        self.ribbonOpacity = ribbonOpacity
        self.valueFormat = valueFormat
    }
    
    private var groupCount: Int { matrix.count }
    
    private var groupTotals: [Double] {
        matrix.enumerated().map { i, row in
            row.reduce(0, +) + matrix.reduce(0) { $0 + $1[i] }
        }
    }
    
    private var totalValue: Double {
        matrix.flatMap { $0 }.reduce(0, +)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
            let innerRadius = radius * innerRadiusRatio
            
            ZStack {
                // Chords (ribbons)
                ForEach(chords, id: \.id) { chord in
                    chordRibbon(
                        chord: chord,
                        center: center,
                        innerRadius: innerRadius
                    )
                }
                
                // Group arcs
                ForEach(0..<groupCount, id: \.self) { index in
                    groupArc(
                        index: index,
                        center: center,
                        outerRadius: radius,
                        innerRadius: innerRadius
                    )
                }
                
                // Labels
                if showLabels {
                    ForEach(0..<groupCount, id: \.self) { index in
                        groupLabel(
                            index: index,
                            center: center,
                            radius: radius + 15
                        )
                    }
                }
                
                // Tooltip
                if let chord = selectedChord {
                    chordTooltip(chord: chord, center: center)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chord diagram with \(groupCount) groups")
    }
    
    // MARK: - Group Arc
    
    @ViewBuilder
    private func groupArc(index: Int, center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat) -> some View {
        let arc = groupArcs[index]
        let color = theme.color(at: index)
        let isSelected = selectedGroup == index
        let isHovered = hoveredGroup == index
        let isHighlighted = selectedGroup == nil || isSelected
        
        Path { path in
            path.addArc(
                center: center,
                radius: outerRadius,
                startAngle: .degrees(arc.startAngle),
                endAngle: .degrees(arc.endAngle),
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: .degrees(arc.endAngle),
                endAngle: .degrees(arc.startAngle),
                clockwise: true
            )
            path.closeSubpath()
        }
        .fill(color)
        .opacity((isHighlighted ? 1.0 : 0.3) * animationProgress)
        .overlay(
            Path { path in
                path.addArc(
                    center: center,
                    radius: outerRadius,
                    startAngle: .degrees(arc.startAngle),
                    endAngle: .degrees(arc.endAngle),
                    clockwise: false
                )
            }
            .stroke(isSelected ? theme.accentColor : Color.white.opacity(0.5), lineWidth: isSelected ? 3 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedGroup = selectedGroup == index ? nil : index
                selectedChord = nil
            }
        }
        .onHover { hovering in
            hoveredGroup = hovering ? index : nil
        }
    }
    
    // MARK: - Chord Ribbon
    
    @ViewBuilder
    private func chordRibbon(chord: ChordData, center: CGPoint, innerRadius: CGFloat) -> some View {
        let sourceColor = theme.color(at: chord.source)
        let isSourceSelected = selectedGroup == chord.source
        let isTargetSelected = selectedGroup == chord.target
        let isChordSelected = selectedChord?.id == chord.id
        let isHighlighted = selectedGroup == nil || isSourceSelected || isTargetSelected
        
        ribbonPath(chord: chord, center: center, radius: innerRadius)
            .fill(
                LinearGradient(
                    colors: [sourceColor, theme.color(at: chord.target)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity((isHighlighted ? ribbonOpacity : 0.1) * animationProgress)
            .overlay(
                ribbonPath(chord: chord, center: center, radius: innerRadius)
                    .stroke(isChordSelected ? theme.accentColor : .clear, lineWidth: 2)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedChord = selectedChord?.id == chord.id ? nil : ChordIdentifier(id: chord.id, source: chord.source, target: chord.target, value: chord.value)
                    selectedGroup = nil
                }
            }
    }
    
    private func ribbonPath(chord: ChordData, center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            let sourceStartAngle = chord.sourceStartAngle * .pi / 180
            let sourceEndAngle = chord.sourceEndAngle * .pi / 180
            let targetStartAngle = chord.targetStartAngle * .pi / 180
            let targetEndAngle = chord.targetEndAngle * .pi / 180
            
            let sourceStart = CGPoint(
                x: center.x + radius * CGFloat(cos(sourceStartAngle)),
                y: center.y + radius * CGFloat(sin(sourceStartAngle))
            )
            let sourceEnd = CGPoint(
                x: center.x + radius * CGFloat(cos(sourceEndAngle)),
                y: center.y + radius * CGFloat(sin(sourceEndAngle))
            )
            let targetStart = CGPoint(
                x: center.x + radius * CGFloat(cos(targetStartAngle)),
                y: center.y + radius * CGFloat(sin(targetStartAngle))
            )
            let targetEnd = CGPoint(
                x: center.x + radius * CGFloat(cos(targetEndAngle)),
                y: center.y + radius * CGFloat(sin(targetEndAngle))
            )
            
            // Draw ribbon
            path.move(to: sourceStart)
            
            // Source arc
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .radians(sourceStartAngle),
                endAngle: .radians(sourceEndAngle),
                clockwise: false
            )
            
            // Bezier to target
            path.addQuadCurve(to: targetStart, control: center)
            
            // Target arc
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .radians(targetStartAngle),
                endAngle: .radians(targetEndAngle),
                clockwise: false
            )
            
            // Bezier back to source
            path.addQuadCurve(to: sourceStart, control: center)
            
            path.closeSubpath()
        }
    }
    
    // MARK: - Group Label
    
    @ViewBuilder
    private func groupLabel(index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let arc = groupArcs[index]
        let midAngle = (arc.startAngle + arc.endAngle) / 2
        let radians = midAngle * .pi / 180
        
        let x = center.x + radius * CGFloat(cos(radians))
        let y = center.y + radius * CGFloat(sin(radians))
        
        let rotation = midAngle > 90 && midAngle < 270 ? midAngle + 180 : midAngle
        
        Text(index < labels.count ? labels[index] : "")
            .font(.caption)
            .foregroundColor(theme.foregroundColor)
            .rotationEffect(.degrees(rotation))
            .position(x: x, y: y)
    }
    
    // MARK: - Tooltip
    
    @ViewBuilder
    private func chordTooltip(chord: ChordIdentifier, center: CGPoint) -> some View {
        let sourceLabel = chord.source < labels.count ? labels[chord.source] : "Source"
        let targetLabel = chord.target < labels.count ? labels[chord.target] : "Target"
        
        VStack(alignment: .leading, spacing: 4) {
            Text("\(sourceLabel) → \(targetLabel)")
                .font(.caption.bold())
            
            Text("Value: \(String(format: valueFormat, chord.value))")
                .font(.caption2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
        )
        .foregroundColor(theme.foregroundColor)
        .position(center)
    }
    
    // MARK: - Layout Calculation
    
    private var groupArcs: [GroupArc] {
        var arcs: [GroupArc] = []
        let paddingTotal = arcPadding * Double(groupCount)
        let availableAngle = 360.0 - paddingTotal
        
        var currentAngle = 0.0
        
        for i in 0..<groupCount {
            let proportion = groupTotals[i] / (groupTotals.reduce(0, +) > 0 ? groupTotals.reduce(0, +) : 1)
            let arcAngle = availableAngle * proportion
            
            arcs.append(GroupArc(
                startAngle: currentAngle,
                endAngle: currentAngle + arcAngle
            ))
            
            currentAngle += arcAngle + arcPadding
        }
        
        return arcs
    }
    
    private var chords: [ChordData] {
        var result: [ChordData] = []
        var groupOffsets = Array(repeating: 0.0, count: groupCount)
        
        for i in 0..<groupCount {
            for j in 0..<groupCount {
                guard i != j, matrix[i][j] > 0 else { continue }
                
                let sourceArc = groupArcs[i]
                let targetArc = groupArcs[j]
                
                let sourceTotal = groupTotals[i]
                let targetTotal = groupTotals[j]
                
                let sourceArcLength = sourceArc.endAngle - sourceArc.startAngle
                let targetArcLength = targetArc.endAngle - targetArc.startAngle
                
                let value = matrix[i][j]
                
                let sourceChordLength = sourceTotal > 0 ? (value / sourceTotal) * sourceArcLength : 0
                let targetChordLength = targetTotal > 0 ? (value / targetTotal) * targetArcLength : 0
                
                let sourceStartAngle = sourceArc.startAngle + groupOffsets[i]
                let sourceEndAngle = sourceStartAngle + sourceChordLength
                
                let targetStartAngle = targetArc.startAngle + groupOffsets[j]
                let targetEndAngle = targetStartAngle + targetChordLength
                
                groupOffsets[i] += sourceChordLength
                groupOffsets[j] += targetChordLength
                
                result.append(ChordData(
                    source: i,
                    target: j,
                    value: value,
                    sourceStartAngle: sourceStartAngle,
                    sourceEndAngle: sourceEndAngle,
                    targetStartAngle: targetStartAngle,
                    targetEndAngle: targetEndAngle
                ))
            }
        }
        
        return result
    }
}

// MARK: - Supporting Types

private struct GroupArc {
    let startAngle: Double
    let endAngle: Double
}

private struct ChordData: Identifiable {
    let id = UUID()
    let source: Int
    let target: Int
    let value: Double
    let sourceStartAngle: Double
    let sourceEndAngle: Double
    let targetStartAngle: Double
    let targetEndAngle: Double
}

private struct ChordIdentifier {
    let id: UUID
    let source: Int
    let target: Int
    let value: Double
}

// MARK: - Preview Provider

#if DEBUG
struct ChordDiagram_Previews: PreviewProvider {
    static var previews: some View {
        let matrix: [[Double]] = [
            [0, 100, 50, 30],
            [80, 0, 60, 40],
            [40, 70, 0, 50],
            [20, 30, 45, 0]
        ]
        
        ChordDiagram(
            matrix: matrix,
            labels: ["Sales", "Marketing", "Engineering", "Support"]
        )
        .frame(height: 400)
        .padding()
    }
}
#endif
