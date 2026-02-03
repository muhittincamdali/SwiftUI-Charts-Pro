import SwiftUI

// MARK: - Sunburst Chart

/// A radial hierarchical chart showing nested proportions.
///
/// Sunburst charts display hierarchical data as concentric rings,
/// with the root at the center and successive levels radiating outward.
///
/// ```swift
/// let root = HierarchyNode(
///     name: "Total",
///     children: [
///         HierarchyNode(name: "Category A", value: 100),
///         HierarchyNode(name: "Category B", children: [
///             HierarchyNode(name: "B1", value: 50),
///             HierarchyNode(name: "B2", value: 30)
///         ])
///     ]
/// )
///
/// SunburstChart(root: root)
/// ```
public struct SunburstChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The root node of the hierarchy
    public let root: HierarchyNode
    
    /// Inner radius ratio
    public let innerRadiusRatio: CGFloat
    
    /// Padding between segments in degrees
    public let segmentPadding: Double
    
    /// Maximum depth to display
    public let maxDepth: Int
    
    /// Whether to show labels
    public let showLabels: Bool
    
    /// Whether to show values
    public let showValues: Bool
    
    /// Segment stroke width
    public let strokeWidth: CGFloat
    
    /// Value format string
    public let valueFormat: String
    
    /// Whether clicking zooms into segment
    public let enableZoom: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedNode: UUID?
    @State private var hoveredNode: UUID?
    @State private var zoomedNode: HierarchyNode?
    
    /// Creates a sunburst chart.
    public init(
        root: HierarchyNode,
        innerRadiusRatio: CGFloat = 0.2,
        segmentPadding: Double = 0.5,
        maxDepth: Int = 4,
        showLabels: Bool = true,
        showValues: Bool = true,
        strokeWidth: CGFloat = 1,
        valueFormat: String = "%.0f",
        enableZoom: Bool = true
    ) {
        self.root = root
        self.innerRadiusRatio = innerRadiusRatio
        self.segmentPadding = segmentPadding
        self.maxDepth = maxDepth
        self.showLabels = showLabels
        self.showValues = showValues
        self.strokeWidth = strokeWidth
        self.valueFormat = valueFormat
        self.enableZoom = enableZoom
    }
    
    private var displayRoot: HierarchyNode {
        zoomedNode ?? root
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            let innerRadius = radius * innerRadiusRatio
            let ringWidth = (radius - innerRadius) / CGFloat(maxDepth)
            
            ZStack {
                // Segments
                ForEach(segments) { segment in
                    segmentArc(
                        segment: segment,
                        center: center,
                        innerRadius: innerRadius,
                        ringWidth: ringWidth
                    )
                }
                
                // Center circle with root label
                centerLabel(center: center, radius: innerRadius)
                
                // Breadcrumb for zoomed view
                if zoomedNode != nil {
                    zoomBreadcrumb
                        .position(x: geometry.size.width / 2, y: 20)
                }
                
                // Tooltip
                if let nodeId = selectedNode, let segment = segments.first(where: { $0.node.id == nodeId }) {
                    tooltipView(for: segment, center: center)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sunburst chart showing hierarchical data")
    }
    
    // MARK: - Segment Arc
    
    @ViewBuilder
    private func segmentArc(segment: SunburstSegment, center: CGPoint, innerRadius: CGFloat, ringWidth: CGFloat) -> some View {
        let color = segment.node.color ?? theme.color(at: colorIndex(for: segment))
        let isSelected = selectedNode == segment.node.id
        let isHovered = hoveredNode == segment.node.id
        let isAncestorSelected = isAncestorOfSelected(segment)
        
        let outerRadius = innerRadius + CGFloat(segment.depth + 1) * ringWidth
        let segmentInnerRadius = innerRadius + CGFloat(segment.depth) * ringWidth
        
        let opacity = calculateOpacity(isSelected: isSelected, isHovered: isHovered, isAncestor: isAncestorSelected)
        
        ZStack {
            // Segment fill
            Path { path in
                path.addArc(
                    center: center,
                    radius: outerRadius,
                    startAngle: .degrees(segment.startAngle),
                    endAngle: .degrees(segment.endAngle - segmentPadding),
                    clockwise: false
                )
                path.addArc(
                    center: center,
                    radius: segmentInnerRadius,
                    startAngle: .degrees(segment.endAngle - segmentPadding),
                    endAngle: .degrees(segment.startAngle),
                    clockwise: true
                )
                path.closeSubpath()
            }
            .fill(color)
            .opacity(opacity * animationProgress)
            
            // Segment stroke
            Path { path in
                path.addArc(
                    center: center,
                    radius: outerRadius,
                    startAngle: .degrees(segment.startAngle),
                    endAngle: .degrees(segment.endAngle - segmentPadding),
                    clockwise: false
                )
                path.addArc(
                    center: center,
                    radius: segmentInnerRadius,
                    startAngle: .degrees(segment.endAngle - segmentPadding),
                    endAngle: .degrees(segment.startAngle),
                    clockwise: true
                )
                path.closeSubpath()
            }
            .stroke(isSelected ? theme.accentColor : Color.white.opacity(0.5), lineWidth: isSelected ? 3 : strokeWidth)
            
            // Label
            if showLabels && (segment.endAngle - segment.startAngle) > 10 && segment.depth < 2 {
                segmentLabel(segment: segment, center: center, innerRadius: segmentInnerRadius, outerRadius: outerRadius)
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture {
            handleTap(on: segment)
        }
        .onHover { hovering in
            hoveredNode = hovering ? segment.node.id : nil
        }
    }
    
    private func handleTap(on segment: SunburstSegment) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if selectedNode == segment.node.id {
                // Double tap - zoom
                if enableZoom && !segment.node.children.isEmpty {
                    zoomedNode = segment.node
                }
                selectedNode = nil
            } else {
                selectedNode = segment.node.id
            }
        }
    }
    
    private func calculateOpacity(isSelected: Bool, isHovered: Bool, isAncestor: Bool) -> Double {
        if isHovered || isSelected {
            return 1.0
        }
        if selectedNode != nil && !isAncestor {
            return 0.4
        }
        return 0.85
    }
    
    private func isAncestorOfSelected(_ segment: SunburstSegment) -> Bool {
        guard let selectedId = selectedNode else { return false }
        return containsNode(segment.node, targetId: selectedId)
    }
    
    private func containsNode(_ node: HierarchyNode, targetId: UUID) -> Bool {
        if node.id == targetId { return true }
        return node.children.contains { containsNode($0, targetId: targetId) }
    }
    
    // MARK: - Segment Label
    
    @ViewBuilder
    private func segmentLabel(segment: SunburstSegment, center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat) -> some View {
        let midAngle = (segment.startAngle + segment.endAngle) / 2
        let midRadius = (innerRadius + outerRadius) / 2
        let radians = midAngle * .pi / 180
        
        let x = center.x + midRadius * CGFloat(cos(radians))
        let y = center.y + midRadius * CGFloat(sin(radians))
        
        // Rotate label to follow arc
        let rotation = midAngle > 90 && midAngle < 270 ? midAngle + 180 : midAngle
        
        Text(segment.node.name)
            .font(.system(size: min(12, (outerRadius - innerRadius) * 0.5)))
            .foregroundColor(.white)
            .rotationEffect(.degrees(rotation))
            .position(x: x, y: y)
            .opacity(animationProgress)
    }
    
    // MARK: - Center Label
    
    @ViewBuilder
    private func centerLabel(center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .fill(theme.backgroundColor)
            .frame(width: radius * 2, height: radius * 2)
            .overlay(
                Circle()
                    .stroke(theme.gridColor, lineWidth: 1)
            )
            .position(center)
        
        VStack(spacing: 2) {
            Text(displayRoot.name)
                .font(.caption.bold())
                .foregroundColor(theme.foregroundColor)
            
            if showValues {
                Text(String(format: valueFormat, displayRoot.totalValue))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .position(center)
    }
    
    // MARK: - Zoom Breadcrumb
    
    private var zoomBreadcrumb: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                zoomedNode = nil
                selectedNode = nil
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.circle.fill")
                Text("Back to \(root.name)")
            }
            .font(.caption)
            .foregroundColor(theme.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tooltip
    
    @ViewBuilder
    private func tooltipView(for segment: SunburstSegment, center: CGPoint) -> some View {
        let total = displayRoot.totalValue
        let percentage = total > 0 ? (segment.node.totalValue / total) * 100 : 0
        
        VStack(alignment: .leading, spacing: 4) {
            Text(segment.node.name)
                .font(.caption.bold())
            
            Text("Value: \(String(format: valueFormat, segment.node.totalValue))")
                .font(.caption2)
            
            Text("Percentage: \(String(format: "%.1f", percentage))%")
                .font(.caption2)
            
            if !segment.node.children.isEmpty {
                Text("Children: \(segment.node.children.count)")
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
        .position(center)
    }
    
    // MARK: - Layout Calculation
    
    private var segments: [SunburstSegment] {
        var result: [SunburstSegment] = []
        calculateSegments(node: displayRoot, startAngle: 0, endAngle: 360, depth: 0, into: &result)
        return result
    }
    
    private func calculateSegments(node: HierarchyNode, startAngle: Double, endAngle: Double, depth: Int, into result: inout [SunburstSegment]) {
        guard depth < maxDepth else { return }
        
        let totalValue = node.totalValue
        guard totalValue > 0 else { return }
        
        var currentAngle = startAngle
        
        for child in node.children {
            let childValue = child.totalValue
            let proportion = childValue / totalValue
            let childEndAngle = currentAngle + (endAngle - startAngle) * proportion
            
            result.append(SunburstSegment(
                node: child,
                startAngle: currentAngle,
                endAngle: childEndAngle,
                depth: depth
            ))
            
            // Recurse for children
            if !child.children.isEmpty {
                calculateSegments(node: child, startAngle: currentAngle, endAngle: childEndAngle, depth: depth + 1, into: &result)
            }
            
            currentAngle = childEndAngle
        }
    }
    
    private func colorIndex(for segment: SunburstSegment) -> Int {
        // Use root-level color for all descendants
        if let rootIndex = displayRoot.children.firstIndex(where: { containsNode($0, targetId: segment.node.id) }) {
            return rootIndex
        }
        return 0
    }
}

// MARK: - Supporting Types

private struct SunburstSegment: Identifiable {
    let id = UUID()
    let node: HierarchyNode
    let startAngle: Double
    let endAngle: Double
    let depth: Int
}

// MARK: - Preview Provider

#if DEBUG
struct SunburstChart_Previews: PreviewProvider {
    static var previews: some View {
        let root = HierarchyNode(
            name: "Total Revenue",
            children: [
                HierarchyNode(
                    name: "Product A",
                    children: [
                        HierarchyNode(name: "Region 1", value: 100),
                        HierarchyNode(name: "Region 2", value: 80),
                        HierarchyNode(name: "Region 3", value: 60)
                    ],
                    color: .blue
                ),
                HierarchyNode(
                    name: "Product B",
                    children: [
                        HierarchyNode(name: "Region 1", value: 120),
                        HierarchyNode(name: "Region 2", value: 90)
                    ],
                    color: .green
                ),
                HierarchyNode(
                    name: "Product C",
                    value: 150,
                    color: .orange
                ),
                HierarchyNode(
                    name: "Services",
                    children: [
                        HierarchyNode(name: "Consulting", value: 70),
                        HierarchyNode(name: "Support", value: 50),
                        HierarchyNode(name: "Training", value: 30)
                    ],
                    color: .purple
                )
            ]
        )
        
        SunburstChart(root: root)
            .frame(height: 400)
            .padding()
    }
}
#endif
