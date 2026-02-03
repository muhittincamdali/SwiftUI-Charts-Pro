import SwiftUI

// MARK: - Sankey Chart

/// A flow diagram showing quantities proportionally between nodes.
///
/// Sankey diagrams are excellent for visualizing flows between stages,
/// such as user funnels, energy transfers, or budget allocations.
///
/// ```swift
/// let connections = [
///     FlowConnection(source: "Budget", target: "Marketing", value: 300),
///     FlowConnection(source: "Budget", target: "Development", value: 500),
///     FlowConnection(source: "Marketing", target: "Online", value: 200),
///     FlowConnection(source: "Marketing", target: "Print", value: 100)
/// ]
///
/// SankeyChart(connections: connections)
/// ```
public struct SankeyChart: View {
    @Environment(\.chartTheme) private var theme
    @Environment(\.chartConfiguration) private var configuration
    
    /// The flow connections between nodes
    public let connections: [FlowConnection]
    
    /// Node width
    public let nodeWidth: CGFloat
    
    /// Padding between nodes vertically
    public let nodePadding: CGFloat
    
    /// Horizontal spacing between columns
    public let columnSpacing: CGFloat
    
    /// Corner radius for nodes
    public let cornerRadius: CGFloat
    
    /// Whether to show labels
    public let showLabels: Bool
    
    /// Whether to show values
    public let showValues: Bool
    
    /// Curve tension for flow paths (0-1)
    public let curveTension: CGFloat
    
    /// Format string for values
    public let valueFormat: String
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedNode: String?
    @State private var selectedConnection: FlowConnection?
    @State private var hoveredConnection: UUID?
    
    /// Creates a Sankey chart.
    public init(
        connections: [FlowConnection],
        nodeWidth: CGFloat = 20,
        nodePadding: CGFloat = 10,
        columnSpacing: CGFloat = 100,
        cornerRadius: CGFloat = 4,
        showLabels: Bool = true,
        showValues: Bool = true,
        curveTension: CGFloat = 0.5,
        valueFormat: String = "%.0f"
    ) {
        self.connections = connections
        self.nodeWidth = nodeWidth
        self.nodePadding = nodePadding
        self.columnSpacing = columnSpacing
        self.cornerRadius = cornerRadius
        self.showLabels = showLabels
        self.showValues = showValues
        self.curveTension = curveTension
        self.valueFormat = valueFormat
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let layout = calculateLayout(size: geometry.size)
            
            ZStack(alignment: .topLeading) {
                // Draw flows first (behind nodes)
                ForEach(layout.flows) { flow in
                    flowPath(flow: flow, layout: layout)
                }
                
                // Draw nodes
                ForEach(layout.nodes) { node in
                    nodeView(node: node)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.animationDuration * 1.5)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sankey diagram showing \(connections.count) flows")
    }
    
    // MARK: - Node View
    
    @ViewBuilder
    private func nodeView(node: SankeyNode) -> some View {
        let isSelected = selectedNode == node.name
        let isHighlighted = selectedNode == nil || isSelected || isConnectedToSelected(node.name)
        let color = node.color ?? theme.color(at: nodeIndex(node.name))
        
        VStack(alignment: node.column == 0 ? .leading : .trailing, spacing: 2) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
                .opacity(isHighlighted ? animationProgress : 0.3 * animationProgress)
                .frame(width: nodeWidth, height: node.height)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(isSelected ? theme.accentColor : .clear, lineWidth: 2)
                )
                .position(x: node.x + nodeWidth / 2, y: node.y + node.height / 2)
            
            if showLabels {
                Text(node.name)
                    .font(.caption)
                    .foregroundColor(theme.foregroundColor)
                    .opacity(isHighlighted ? 1 : 0.5)
                    .position(x: labelX(for: node), y: node.y + node.height / 2)
            }
            
            if showValues {
                Text(String(format: valueFormat, node.value))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(isHighlighted ? 1 : 0.5)
                    .position(x: valueX(for: node), y: node.y + node.height / 2 + 14)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedNode = selectedNode == node.name ? nil : node.name
            }
        }
    }
    
    private func labelX(for node: SankeyNode) -> CGFloat {
        if node.column == 0 {
            return node.x - 30
        } else {
            return node.x + nodeWidth + 30
        }
    }
    
    private func valueX(for node: SankeyNode) -> CGFloat {
        labelX(for: node)
    }
    
    private func nodeIndex(_ name: String) -> Int {
        let allNodes = Set(connections.map { $0.source } + connections.map { $0.target })
        return allNodes.sorted().firstIndex(of: name) ?? 0
    }
    
    private func isConnectedToSelected(_ nodeName: String) -> Bool {
        guard let selected = selectedNode else { return true }
        return connections.contains { conn in
            (conn.source == selected && conn.target == nodeName) ||
            (conn.target == selected && conn.source == nodeName)
        }
    }
    
    // MARK: - Flow Path
    
    @ViewBuilder
    private func flowPath(flow: SankeyFlow, layout: SankeyLayout) -> some View {
        let sourceNode = layout.nodes.first { $0.name == flow.connection.source }
        let targetNode = layout.nodes.first { $0.name == flow.connection.target }
        
        guard let source = sourceNode, let target = targetNode else { return EmptyView().eraseToAnyView() }
        
        let isHighlighted = selectedNode == nil ||
            flow.connection.source == selectedNode ||
            flow.connection.target == selectedNode
        let isHovered = hoveredConnection == flow.connection.id
        
        let color = flow.connection.color ?? theme.color(at: nodeIndex(flow.connection.source))
        
        return Path { path in
            let startX = source.x + nodeWidth
            let endX = target.x
            let controlPointOffset = (endX - startX) * curveTension
            
            path.move(to: CGPoint(x: startX, y: flow.sourceY))
            path.addCurve(
                to: CGPoint(x: endX, y: flow.targetY),
                control1: CGPoint(x: startX + controlPointOffset, y: flow.sourceY),
                control2: CGPoint(x: endX - controlPointOffset, y: flow.targetY)
            )
            path.addLine(to: CGPoint(x: endX, y: flow.targetY + flow.thickness))
            path.addCurve(
                to: CGPoint(x: startX, y: flow.sourceY + flow.thickness),
                control1: CGPoint(x: endX - controlPointOffset, y: flow.targetY + flow.thickness),
                control2: CGPoint(x: startX + controlPointOffset, y: flow.sourceY + flow.thickness)
            )
            path.closeSubpath()
        }
        .fill(color.opacity((isHighlighted ? 0.5 : 0.15) * animationProgress))
        .overlay(
            Path { path in
                let startX = source.x + nodeWidth
                let endX = target.x
                let midY = (flow.sourceY + flow.targetY) / 2 + flow.thickness / 2
                let controlPointOffset = (endX - startX) * curveTension
                
                path.move(to: CGPoint(x: startX, y: flow.sourceY + flow.thickness / 2))
                path.addCurve(
                    to: CGPoint(x: endX, y: flow.targetY + flow.thickness / 2),
                    control1: CGPoint(x: startX + controlPointOffset, y: flow.sourceY + flow.thickness / 2),
                    control2: CGPoint(x: endX - controlPointOffset, y: flow.targetY + flow.thickness / 2)
                )
            }
            .stroke(color.opacity(isHovered ? 0.8 : 0), lineWidth: 2)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedConnection?.id == flow.connection.id {
                    selectedConnection = nil
                } else {
                    selectedConnection = flow.connection
                }
            }
        }
        .onHover { hovering in
            hoveredConnection = hovering ? flow.connection.id : nil
        }
        .eraseToAnyView()
    }
    
    // MARK: - Layout Calculation
    
    private func calculateLayout(size: CGSize) -> SankeyLayout {
        // Build node structure
        var nodesByName: [String: SankeyNodeBuilder] = [:]
        var columns: [[String]] = []
        
        // Identify all nodes
        for conn in connections {
            if nodesByName[conn.source] == nil {
                nodesByName[conn.source] = SankeyNodeBuilder(name: conn.source)
            }
            if nodesByName[conn.target] == nil {
                nodesByName[conn.target] = SankeyNodeBuilder(name: conn.target)
            }
            
            nodesByName[conn.source]?.outgoing.append(conn)
            nodesByName[conn.target]?.incoming.append(conn)
        }
        
        // Assign columns
        var assigned = Set<String>()
        var currentColumn = 0
        
        // Find source nodes (no incoming)
        var sourceNodes = nodesByName.filter { $0.value.incoming.isEmpty }.map { $0.key }
        
        while !sourceNodes.isEmpty {
            columns.append(sourceNodes)
            assigned.formUnion(sourceNodes)
            
            var nextColumn: [String] = []
            for nodeName in sourceNodes {
                if let node = nodesByName[nodeName] {
                    for conn in node.outgoing {
                        if !assigned.contains(conn.target) && !nextColumn.contains(conn.target) {
                            // Check if all incoming nodes are assigned
                            let targetNode = nodesByName[conn.target]!
                            let allIncomingAssigned = targetNode.incoming.allSatisfy { assigned.contains($0.source) }
                            if allIncomingAssigned {
                                nextColumn.append(conn.target)
                            }
                        }
                    }
                }
            }
            
            sourceNodes = nextColumn
            currentColumn += 1
        }
        
        // Calculate node values
        for (name, builder) in nodesByName {
            let incomingValue = builder.incoming.reduce(0) { $0 + $1.value }
            let outgoingValue = builder.outgoing.reduce(0) { $0 + $1.value }
            nodesByName[name]?.value = max(incomingValue, outgoingValue)
        }
        
        // Calculate total value for scaling
        let maxColumnValue = columns.map { column in
            column.reduce(0) { $0 + (nodesByName[$1]?.value ?? 0) }
        }.max() ?? 1
        
        let availableHeight = size.height - CGFloat(nodesByName.count) * nodePadding
        let valueScale = availableHeight / maxColumnValue
        
        // Position nodes
        var nodes: [SankeyNode] = []
        let columnWidth = (size.width - CGFloat(columns.count - 1) * columnSpacing - nodeWidth * CGFloat(columns.count)) / CGFloat(max(1, columns.count - 1))
        
        for (colIndex, column) in columns.enumerated() {
            let columnValue = column.reduce(0) { $0 + (nodesByName[$1]?.value ?? 0) }
            let columnHeight = columnValue * valueScale
            let columnPadding = (size.height - columnHeight - CGFloat(column.count - 1) * nodePadding) / 2
            
            var y = columnPadding
            
            for nodeName in column {
                guard let builder = nodesByName[nodeName] else { continue }
                let nodeHeight = builder.value * valueScale
                
                let node = SankeyNode(
                    name: nodeName,
                    value: builder.value,
                    column: colIndex,
                    x: CGFloat(colIndex) * (columnSpacing + nodeWidth),
                    y: y,
                    height: nodeHeight,
                    color: nil
                )
                
                nodes.append(node)
                y += nodeHeight + nodePadding
            }
        }
        
        // Calculate flows
        var flows: [SankeyFlow] = []
        var nodeOutgoingOffsets: [String: CGFloat] = [:]
        var nodeIncomingOffsets: [String: CGFloat] = [:]
        
        for node in nodes {
            nodeOutgoingOffsets[node.name] = node.y
            nodeIncomingOffsets[node.name] = node.y
        }
        
        for conn in connections {
            guard let sourceNode = nodes.first(where: { $0.name == conn.source }),
                  let targetNode = nodes.first(where: { $0.name == conn.target }) else { continue }
            
            let thickness = conn.value * valueScale
            let sourceY = nodeOutgoingOffsets[conn.source] ?? sourceNode.y
            let targetY = nodeIncomingOffsets[conn.target] ?? targetNode.y
            
            flows.append(SankeyFlow(
                connection: conn,
                sourceY: sourceY,
                targetY: targetY,
                thickness: thickness
            ))
            
            nodeOutgoingOffsets[conn.source] = sourceY + thickness
            nodeIncomingOffsets[conn.target] = targetY + thickness
        }
        
        return SankeyLayout(nodes: nodes, flows: flows)
    }
}

// MARK: - Supporting Types

private struct SankeyNodeBuilder {
    let name: String
    var incoming: [FlowConnection] = []
    var outgoing: [FlowConnection] = []
    var value: Double = 0
}

struct SankeyNode: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let column: Int
    let x: CGFloat
    let y: CGFloat
    let height: CGFloat
    let color: Color?
}

struct SankeyFlow: Identifiable {
    let id = UUID()
    let connection: FlowConnection
    let sourceY: CGFloat
    let targetY: CGFloat
    let thickness: CGFloat
}

struct SankeyLayout {
    let nodes: [SankeyNode]
    let flows: [SankeyFlow]
}

// MARK: - View Extension

private extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct SankeyChart_Previews: PreviewProvider {
    static var previews: some View {
        let connections = [
            FlowConnection(source: "Budget", target: "Marketing", value: 300),
            FlowConnection(source: "Budget", target: "Development", value: 500),
            FlowConnection(source: "Budget", target: "Operations", value: 200),
            FlowConnection(source: "Marketing", target: "Online", value: 200),
            FlowConnection(source: "Marketing", target: "Print", value: 100),
            FlowConnection(source: "Development", target: "Product", value: 300),
            FlowConnection(source: "Development", target: "Research", value: 200)
        ]
        
        SankeyChart(connections: connections)
            .frame(height: 400)
            .padding()
    }
}
#endif
