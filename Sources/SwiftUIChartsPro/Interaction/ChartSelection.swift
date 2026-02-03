import SwiftUI

// MARK: - Chart Selection Manager

/// A manager for handling chart selection state and interactions.
///
/// Use `ChartSelectionManager` to track selected elements and respond
/// to selection changes across chart components.
///
/// ```swift
/// @StateObject var selection = ChartSelectionManager<String>()
///
/// MyChart(data: data)
///     .onChartSelect { id in
///         selection.select(id)
///     }
/// ```
@MainActor
public class ChartSelectionManager<ID: Hashable>: ObservableObject {
    /// Currently selected items
    @Published public var selectedItems: Set<ID> = []
    
    /// The most recently selected item
    @Published public var lastSelected: ID?
    
    /// Whether multi-selection is enabled
    public var allowsMultipleSelection: Bool
    
    /// Maximum number of selections allowed (nil = unlimited)
    public var maxSelections: Int?
    
    /// Selection change callback
    public var onSelectionChange: ((Set<ID>) -> Void)?
    
    /// Creates a selection manager.
    public init(
        allowsMultipleSelection: Bool = false,
        maxSelections: Int? = nil
    ) {
        self.allowsMultipleSelection = allowsMultipleSelection
        self.maxSelections = maxSelections
    }
    
    /// Selects an item.
    public func select(_ id: ID) {
        if allowsMultipleSelection {
            if selectedItems.contains(id) {
                selectedItems.remove(id)
            } else {
                if let max = maxSelections, selectedItems.count >= max {
                    // Remove oldest selection
                    if let first = selectedItems.first {
                        selectedItems.remove(first)
                    }
                }
                selectedItems.insert(id)
            }
        } else {
            if selectedItems.contains(id) {
                selectedItems.removeAll()
                lastSelected = nil
            } else {
                selectedItems = [id]
                lastSelected = id
            }
        }
        
        onSelectionChange?(selectedItems)
    }
    
    /// Deselects an item.
    public func deselect(_ id: ID) {
        selectedItems.remove(id)
        if lastSelected == id {
            lastSelected = selectedItems.first
        }
        onSelectionChange?(selectedItems)
    }
    
    /// Clears all selections.
    public func clearSelection() {
        selectedItems.removeAll()
        lastSelected = nil
        onSelectionChange?(selectedItems)
    }
    
    /// Checks if an item is selected.
    public func isSelected(_ id: ID) -> Bool {
        selectedItems.contains(id)
    }
    
    /// Toggles selection state of an item.
    public func toggle(_ id: ID) {
        if isSelected(id) {
            deselect(id)
        } else {
            select(id)
        }
    }
    
    /// Selects multiple items at once.
    public func selectAll(_ ids: [ID]) {
        if allowsMultipleSelection {
            for id in ids {
                if let max = maxSelections, selectedItems.count >= max {
                    break
                }
                selectedItems.insert(id)
            }
            lastSelected = ids.last
        } else if let first = ids.first {
            selectedItems = [first]
            lastSelected = first
        }
        onSelectionChange?(selectedItems)
    }
}

// MARK: - Selection Highlight Modifier

/// A view modifier that applies selection highlighting to chart elements.
public struct SelectionHighlightModifier: ViewModifier {
    @Environment(\.chartTheme) private var theme
    
    let isSelected: Bool
    let highlightColor: Color?
    let style: SelectionStyle
    
    public init(
        isSelected: Bool,
        highlightColor: Color? = nil,
        style: SelectionStyle = .border
    ) {
        self.isSelected = isSelected
        self.highlightColor = highlightColor
        self.style = style
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(overlay)
            .scaleEffect(isSelected && style == .scale ? 1.05 : 1.0)
            .shadow(
                color: isSelected && style == .glow ? (highlightColor ?? theme.accentColor).opacity(0.5) : .clear,
                radius: 8
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    @ViewBuilder
    private var overlay: some View {
        if isSelected {
            switch style {
            case .border:
                RoundedRectangle(cornerRadius: 4)
                    .stroke(highlightColor ?? theme.accentColor, lineWidth: 2)
            case .fill:
                RoundedRectangle(cornerRadius: 4)
                    .fill((highlightColor ?? theme.accentColor).opacity(0.2))
            case .scale, .glow:
                EmptyView()
            case .checkmark:
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(highlightColor ?? theme.accentColor)
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
    }
}

/// Selection highlight styles
public enum SelectionStyle {
    /// Border around selected element
    case border
    
    /// Semi-transparent fill
    case fill
    
    /// Scale up selected element
    case scale
    
    /// Glow effect around element
    case glow
    
    /// Checkmark indicator
    case checkmark
}

public extension View {
    /// Applies selection highlighting to this view.
    func selectionHighlight(
        isSelected: Bool,
        color: Color? = nil,
        style: SelectionStyle = .border
    ) -> some View {
        modifier(SelectionHighlightModifier(isSelected: isSelected, highlightColor: color, style: style))
    }
}

// MARK: - Selectable Chart Element

/// A wrapper that makes any view selectable within a chart.
public struct SelectableChartElement<Content: View, ID: Hashable>: View {
    @Environment(\.chartTheme) private var theme
    
    let id: ID
    let isSelected: Bool
    let selectionStyle: SelectionStyle
    let onSelect: (ID) -> Void
    let content: () -> Content
    
    public init(
        id: ID,
        isSelected: Bool,
        selectionStyle: SelectionStyle = .border,
        onSelect: @escaping (ID) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.isSelected = isSelected
        self.selectionStyle = selectionStyle
        self.onSelect = onSelect
        self.content = content
    }
    
    public var body: some View {
        content()
            .selectionHighlight(isSelected: isSelected, style: selectionStyle)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(id)
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Range Selection

/// Manages range selection for charts (e.g., selecting a date range).
@MainActor
public class RangeSelectionManager<T: Comparable>: ObservableObject {
    /// The selected range
    @Published public var selectedRange: ClosedRange<T>?
    
    /// Whether range selection is in progress
    @Published public var isSelecting: Bool = false
    
    /// The start of the current selection
    private var selectionStart: T?
    
    /// Range change callback
    public var onRangeChange: ((ClosedRange<T>?) -> Void)?
    
    public init() {}
    
    /// Begins a range selection at the given value.
    public func beginSelection(at value: T) {
        selectionStart = value
        isSelecting = true
    }
    
    /// Updates the range selection to include the given value.
    public func updateSelection(to value: T) {
        guard let start = selectionStart else { return }
        
        let lower = min(start, value)
        let upper = max(start, value)
        selectedRange = lower...upper
    }
    
    /// Ends the current range selection.
    public func endSelection() {
        isSelecting = false
        selectionStart = nil
        onRangeChange?(selectedRange)
    }
    
    /// Clears the selected range.
    public func clearRange() {
        selectedRange = nil
        selectionStart = nil
        isSelecting = false
        onRangeChange?(nil)
    }
}

// MARK: - Lasso Selection

/// Manages lasso (freeform) selection for scatter plots and similar charts.
@MainActor
public class LassoSelectionManager: ObservableObject {
    /// The lasso path points
    @Published public var lassoPath: [CGPoint] = []
    
    /// Whether lasso selection is active
    @Published public var isActive: Bool = false
    
    /// Points within the lasso selection
    @Published public var selectedPoints: Set<UUID> = []
    
    public init() {}
    
    /// Begins lasso selection at a point.
    public func beginLasso(at point: CGPoint) {
        lassoPath = [point]
        isActive = true
        selectedPoints.removeAll()
    }
    
    /// Adds a point to the lasso path.
    public func addPoint(_ point: CGPoint) {
        guard isActive else { return }
        lassoPath.append(point)
    }
    
    /// Ends lasso selection and calculates selected points.
    public func endLasso(points: [(id: UUID, position: CGPoint)]) {
        guard lassoPath.count > 2 else {
            cancelLasso()
            return
        }
        
        // Close the path
        lassoPath.append(lassoPath[0])
        
        // Check which points are inside
        for point in points {
            if isPointInLasso(point.position) {
                selectedPoints.insert(point.id)
            }
        }
        
        isActive = false
    }
    
    /// Cancels lasso selection.
    public func cancelLasso() {
        lassoPath.removeAll()
        isActive = false
    }
    
    /// Clears the selection.
    public func clearSelection() {
        selectedPoints.removeAll()
        lassoPath.removeAll()
    }
    
    /// Checks if a point is inside the lasso polygon.
    private func isPointInLasso(_ point: CGPoint) -> Bool {
        guard lassoPath.count > 2 else { return false }
        
        var inside = false
        var j = lassoPath.count - 1
        
        for i in 0..<lassoPath.count {
            let xi = lassoPath[i].x
            let yi = lassoPath[i].y
            let xj = lassoPath[j].x
            let yj = lassoPath[j].y
            
            if ((yi > point.y) != (yj > point.y)) &&
               (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            
            j = i
        }
        
        return inside
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ChartSelection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Single selection demo
            HStack(spacing: 10) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .selectionHighlight(isSelected: i == 2, style: .border)
                }
            }
            
            // Scale selection
            HStack(spacing: 10) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green)
                        .frame(width: 50, height: 50)
                        .selectionHighlight(isSelected: i == 1, style: .scale)
                }
            }
            
            // Glow selection
            HStack(spacing: 10) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple)
                        .frame(width: 50, height: 50)
                        .selectionHighlight(isSelected: i == 3, style: .glow)
                }
            }
        }
        .padding()
    }
}
#endif
