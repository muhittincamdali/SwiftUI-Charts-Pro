import SwiftUI

// MARK: - Treemap Chart

/// A hierarchical chart that displays data as nested rectangles.
///
/// Treemaps are effective for showing proportional relationships in
/// hierarchical data, where the size of each rectangle represents a value.
///
/// ```swift
/// let root = HierarchyNode(
///     name: "Total",
///     children: [
///         HierarchyNode(name: "Category A", value: 100),
///         HierarchyNode(name: "Category B", value: 200)
///     ]
/// )
///
/// TreemapChart(root: root)
/// ```
public struct TreemapChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The root node of the hierarchy
    public let root: HierarchyNode
    
    /// Corner radius for rectangles
    public let cornerRadius: CGFloat
    
    /// Spacing between rectangles
    public let spacing: CGFloat
    
    /// Whether to show labels
    public let showLabels: Bool
    
    /// Whether to show values
    public let showValues: Bool
    
    /// Minimum size threshold for showing labels
    public let labelThreshold: CGFloat
    
    /// Format string for values
    public let valueFormat: String
    
    /// The depth level to display
    public let maxDepth: Int
    
    @State private var selectedNode: HierarchyNode?
    @State private var animationProgress: CGFloat = 0
    @State private var currentRoot: HierarchyNode?
    
    /// Creates a treemap chart.
    ///
    /// - Parameters:
    ///   - root: The root hierarchy node
    ///   - cornerRadius: Rectangle corner radius
    ///   - spacing: Spacing between rectangles
    ///   - showLabels: Whether to show labels
    ///   - showValues: Whether to show values
    ///   - labelThreshold: Minimum size for labels
    ///   - valueFormat: Value number format
    ///   - maxDepth: Maximum depth to display
    public init(
        root: HierarchyNode,
        cornerRadius: CGFloat = 4,
        spacing: CGFloat = 2,
        showLabels: Bool = true,
        showValues: Bool = true,
        labelThreshold: CGFloat = 40,
        valueFormat: String = "%.0f",
        maxDepth: Int = 2
    ) {
        self.root = root
        self.cornerRadius = cornerRadius
        self.spacing = spacing
        self.showLabels = showLabels
        self.showValues = showValues
        self.labelThreshold = labelThreshold
        self.valueFormat = valueFormat
        self.maxDepth = maxDepth
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let displayRoot = currentRoot ?? root
            let rects = calculateTreemapLayout(
                node: displayRoot,
                rect: CGRect(origin: .zero, size: geometry.size),
                depth: 0
            )
            
            ZStack(alignment: .topLeading) {
                ForEach(Array(rects.enumerated()), id: \.offset) { index, item in
                    treemapRect(item: item, index: index)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Treemap chart showing hierarchical data")
    }
    
    // MARK: - Rectangle View
    
    @ViewBuilder
    private func treemapRect(item: TreemapItem, index: Int) -> some View {
        let isSelected = selectedNode?.id == item.node.id
        let color = item.node.color ?? theme.color(at: index)
        let adjustedColor = adjustColorByDepth(color, depth: item.depth)
        
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(adjustedColor)
                .opacity(animationProgress)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(isSelected ? theme.accentColor : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 0.5)
            
            if item.rect.width > labelThreshold && item.rect.height > labelThreshold {
                VStack(spacing: 2) {
                    if showLabels {
                        Text(item.node.name)
                            .font(labelFont(for: item.rect))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    
                    if showValues {
                        Text(String(format: valueFormat, item.node.totalValue))
                            .font(.system(size: min(item.rect.width, item.rect.height) * 0.12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(4)
            }
        }
        .frame(width: item.rect.width - spacing, height: item.rect.height - spacing)
        .position(x: item.rect.midX, y: item.rect.midY)
        .onTapGesture {
            handleTap(on: item.node)
        }
        .accessibilityElement()
        .accessibilityLabel("\(item.node.name), value: \(String(format: valueFormat, item.node.totalValue))")
    }
    
    private func handleTap(on node: HierarchyNode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if selectedNode?.id == node.id {
                selectedNode = nil
                if !node.children.isEmpty {
                    currentRoot = node
                }
            } else {
                selectedNode = node
            }
        }
    }
    
    private func labelFont(for rect: CGRect) -> Font {
        let minDimension = min(rect.width, rect.height)
        let fontSize = max(8, min(14, minDimension * 0.15))
        return .system(size: fontSize)
    }
    
    private func adjustColorByDepth(_ color: Color, depth: Int) -> Color {
        let adjustment = 1.0 - Double(depth) * 0.15
        return color.opacity(max(0.4, adjustment))
    }
    
    // MARK: - Layout Calculation
    
    private func calculateTreemapLayout(node: HierarchyNode, rect: CGRect, depth: Int) -> [TreemapItem] {
        guard depth < maxDepth else {
            return [TreemapItem(node: node, rect: rect, depth: depth)]
        }
        
        if node.children.isEmpty {
            return [TreemapItem(node: node, rect: rect, depth: depth)]
        }
        
        var results: [TreemapItem] = []
        let childRects = squarify(children: node.children, rect: rect)
        
        for (child, childRect) in zip(node.children, childRects) {
            if depth + 1 < maxDepth && !child.children.isEmpty {
                let innerRect = childRect.insetBy(dx: spacing, dy: spacing)
                results.append(contentsOf: calculateTreemapLayout(node: child, rect: innerRect, depth: depth + 1))
            } else {
                results.append(TreemapItem(node: child, rect: childRect, depth: depth + 1))
            }
        }
        
        return results
    }
    
    /// Squarify algorithm for optimal rectangle layout
    private func squarify(children: [HierarchyNode], rect: CGRect) -> [CGRect] {
        let total = children.reduce(0) { $0 + $1.totalValue }
        guard total > 0 else { return children.map { _ in .zero } }
        
        let normalizedSizes = children.map { $0.totalValue / total * rect.width * rect.height }
        
        var rects: [CGRect] = []
        var remainingRect = rect
        var currentRow: [Double] = []
        var currentRowIndices: [Int] = []
        var processedIndex = 0
        
        for (index, size) in normalizedSizes.enumerated() {
            let testRow = currentRow + [size]
            
            if currentRow.isEmpty || worstRatio(row: testRow, width: shortestSide(remainingRect)) <= worstRatio(row: currentRow, width: shortestSide(remainingRect)) {
                currentRow.append(size)
                currentRowIndices.append(index)
            } else {
                // Layout current row and start new one
                let rowRects = layoutRow(sizes: currentRow, in: remainingRect)
                rects.append(contentsOf: rowRects)
                remainingRect = remainingRectAfterRow(rowRects, in: remainingRect)
                processedIndex = index
                currentRow = [size]
                currentRowIndices = [index]
            }
        }
        
        // Layout remaining row
        if !currentRow.isEmpty {
            rects.append(contentsOf: layoutRow(sizes: currentRow, in: remainingRect))
        }
        
        return rects
    }
    
    private func shortestSide(_ rect: CGRect) -> CGFloat {
        min(rect.width, rect.height)
    }
    
    private func worstRatio(row: [Double], width: CGFloat) -> CGFloat {
        guard !row.isEmpty, width > 0 else { return CGFloat.infinity }
        
        let sum = row.reduce(0, +)
        let rowHeight = sum / Double(width)
        
        guard rowHeight > 0 else { return CGFloat.infinity }
        
        var worst: CGFloat = 0
        for size in row {
            let rectWidth = CGFloat(size / rowHeight)
            let ratio = max(rectWidth / CGFloat(rowHeight), CGFloat(rowHeight) / rectWidth)
            worst = max(worst, ratio)
        }
        
        return worst
    }
    
    private func layoutRow(sizes: [Double], in rect: CGRect) -> [CGRect] {
        let sum = sizes.reduce(0, +)
        guard sum > 0 else { return sizes.map { _ in .zero } }
        
        let isHorizontal = rect.width >= rect.height
        let dimension = isHorizontal ? rect.height : rect.width
        let rowSize = CGFloat(sum) / dimension
        
        var rects: [CGRect] = []
        var offset: CGFloat = 0
        
        for size in sizes {
            let length = CGFloat(size) / rowSize
            
            if isHorizontal {
                rects.append(CGRect(x: rect.minX, y: rect.minY + offset, width: rowSize, height: length))
            } else {
                rects.append(CGRect(x: rect.minX + offset, y: rect.minY, width: length, height: rowSize))
            }
            
            offset += length
        }
        
        return rects
    }
    
    private func remainingRectAfterRow(_ rowRects: [CGRect], in rect: CGRect) -> CGRect {
        guard let firstRect = rowRects.first else { return rect }
        
        let isHorizontal = rect.width >= rect.height
        
        if isHorizontal {
            return CGRect(
                x: rect.minX + firstRect.width,
                y: rect.minY,
                width: rect.width - firstRect.width,
                height: rect.height
            )
        } else {
            return CGRect(
                x: rect.minX,
                y: rect.minY + firstRect.height,
                width: rect.width,
                height: rect.height - firstRect.height
            )
        }
    }
}

// MARK: - Supporting Types

/// Item in the treemap layout
private struct TreemapItem {
    let node: HierarchyNode
    let rect: CGRect
    let depth: Int
}

// MARK: - Preview Provider

#if DEBUG
struct TreemapChart_Previews: PreviewProvider {
    static var previews: some View {
        let root = HierarchyNode(
            name: "Total Sales",
            children: [
                HierarchyNode(
                    name: "Electronics",
                    children: [
                        HierarchyNode(name: "Phones", value: 300),
                        HierarchyNode(name: "Laptops", value: 200),
                        HierarchyNode(name: "Tablets", value: 100)
                    ],
                    color: .blue
                ),
                HierarchyNode(
                    name: "Clothing",
                    children: [
                        HierarchyNode(name: "Shirts", value: 150),
                        HierarchyNode(name: "Pants", value: 100)
                    ],
                    color: .green
                ),
                HierarchyNode(name: "Books", value: 80, color: .orange),
                HierarchyNode(name: "Food", value: 120, color: .red)
            ]
        )
        
        TreemapChart(root: root)
            .frame(height: 300)
            .padding()
    }
}
#endif
