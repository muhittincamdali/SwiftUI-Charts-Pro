import SwiftUI

// MARK: - Interactive Chart Gestures

/// A view modifier that adds zoom and pan gestures to charts.
///
/// Enables users to explore large datasets by zooming in and panning
/// across the chart area with smooth animations.
///
/// ```swift
/// LineChart(data: largeDataset)
///     .chartInteractive(
///         minZoom: 1.0,
///         maxZoom: 10.0,
///         onRangeChange: { range in
///             print("Visible range: \(range)")
///         }
///     )
/// ```
public struct InteractiveChartModifier: ViewModifier {
    
    // MARK: - Properties
    
    /// Current zoom level
    @State private var currentZoom: CGFloat = 1.0
    
    /// Accumulated zoom from gesture
    @State private var gestureZoom: CGFloat = 1.0
    
    /// Current pan offset
    @State private var currentOffset: CGSize = .zero
    
    /// Accumulated offset from gesture
    @State private var gestureOffset: CGSize = .zero
    
    /// Minimum zoom level
    let minZoom: CGFloat
    
    /// Maximum zoom level
    let maxZoom: CGFloat
    
    /// Whether zoom is enabled
    let enableZoom: Bool
    
    /// Whether pan is enabled
    let enablePan: Bool
    
    /// Whether to show zoom controls
    let showZoomControls: Bool
    
    /// Callback when visible range changes
    let onRangeChange: ((ClosedRange<CGFloat>) -> Void)?
    
    /// Reset trigger
    @Binding var resetTrigger: Bool
    
    // MARK: - Initialization
    
    public init(
        minZoom: CGFloat = 1.0,
        maxZoom: CGFloat = 10.0,
        enableZoom: Bool = true,
        enablePan: Bool = true,
        showZoomControls: Bool = true,
        resetTrigger: Binding<Bool> = .constant(false),
        onRangeChange: ((ClosedRange<CGFloat>) -> Void)? = nil
    ) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.enableZoom = enableZoom
        self.enablePan = enablePan
        self.showZoomControls = showZoomControls
        self._resetTrigger = resetTrigger
        self.onRangeChange = onRangeChange
    }
    
    // MARK: - Body
    
    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                content
                    .scaleEffect(totalZoom, anchor: .center)
                    .offset(constrainedOffset(in: geometry.size))
                    .gesture(zoomGesture)
                    .gesture(panGesture)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: currentZoom)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: currentOffset)
                
                if showZoomControls && enableZoom {
                    zoomControlsView
                        .padding(8)
                }
            }
        }
        .onChange(of: resetTrigger) { _ in
            if resetTrigger {
                resetZoom()
                resetTrigger = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalZoom: CGFloat {
        min(max(currentZoom * gestureZoom, minZoom), maxZoom)
    }
    
    private func constrainedOffset(in size: CGSize) -> CGSize {
        let totalOffset = CGSize(
            width: currentOffset.width + gestureOffset.width,
            height: currentOffset.height + gestureOffset.height
        )
        
        // Calculate bounds based on zoom level
        let maxOffsetX = size.width * (totalZoom - 1) / 2
        let maxOffsetY = size.height * (totalZoom - 1) / 2
        
        return CGSize(
            width: min(max(totalOffset.width, -maxOffsetX), maxOffsetX),
            height: min(max(totalOffset.height, -maxOffsetY), maxOffsetY)
        )
    }
    
    // MARK: - Gestures
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard enableZoom else { return }
                gestureZoom = value
            }
            .onEnded { value in
                guard enableZoom else { return }
                currentZoom = min(max(currentZoom * value, minZoom), maxZoom)
                gestureZoom = 1.0
                notifyRangeChange()
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard enablePan && totalZoom > 1.0 else { return }
                gestureOffset = value.translation
            }
            .onEnded { value in
                guard enablePan && totalZoom > 1.0 else { return }
                currentOffset = CGSize(
                    width: currentOffset.width + value.translation.width,
                    height: currentOffset.height + value.translation.height
                )
                gestureOffset = .zero
                notifyRangeChange()
            }
    }
    
    // MARK: - Zoom Controls
    
    private var zoomControlsView: some View {
        VStack(spacing: 4) {
            Button(action: zoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(currentZoom >= maxZoom)
            
            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(currentZoom <= minZoom)
            
            Button(action: resetZoom) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(currentZoom == 1.0 && currentOffset == .zero)
            
            // Zoom level indicator
            Text(String(format: "%.0f%%", currentZoom * 100))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    // MARK: - Actions
    
    private func zoomIn() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentZoom = min(currentZoom * 1.5, maxZoom)
        }
        notifyRangeChange()
    }
    
    private func zoomOut() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentZoom = max(currentZoom / 1.5, minZoom)
            if currentZoom == 1.0 {
                currentOffset = .zero
            }
        }
        notifyRangeChange()
    }
    
    private func resetZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentZoom = 1.0
            currentOffset = .zero
        }
        notifyRangeChange()
    }
    
    private func notifyRangeChange() {
        let normalizedStart = max(0, (0.5 - 0.5 / currentZoom) + currentOffset.width / 1000)
        let normalizedEnd = min(1, (0.5 + 0.5 / currentZoom) + currentOffset.width / 1000)
        onRangeChange?(CGFloat(normalizedStart)...CGFloat(normalizedEnd))
    }
}

// MARK: - View Extension

public extension View {
    /// Adds interactive zoom and pan gestures to a chart.
    func chartInteractive(
        minZoom: CGFloat = 1.0,
        maxZoom: CGFloat = 10.0,
        enableZoom: Bool = true,
        enablePan: Bool = true,
        showZoomControls: Bool = true,
        resetTrigger: Binding<Bool> = .constant(false),
        onRangeChange: ((ClosedRange<CGFloat>) -> Void)? = nil
    ) -> some View {
        modifier(InteractiveChartModifier(
            minZoom: minZoom,
            maxZoom: maxZoom,
            enableZoom: enableZoom,
            enablePan: enablePan,
            showZoomControls: showZoomControls,
            resetTrigger: resetTrigger,
            onRangeChange: onRangeChange
        ))
    }
}

// MARK: - Selection Gestures

/// A view modifier for handling chart data point selection.
public struct ChartSelectionModifier: ViewModifier {
    
    @Binding var selectedIndex: Int?
    let dataCount: Int
    let onSelect: ((Int) -> Void)?
    
    public init(
        selectedIndex: Binding<Int?>,
        dataCount: Int,
        onSelect: ((Int) -> Void)? = nil
    ) {
        self._selectedIndex = selectedIndex
        self.dataCount = dataCount
        self.onSelect = onSelect
    }
    
    public func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleSelection(at: value.location)
                    }
                    .onEnded { _ in
                        // Keep selection or clear based on preference
                    }
            )
    }
    
    private func handleSelection(at location: CGPoint) {
        // This would need the actual chart bounds to work correctly
        // For now, it's a placeholder implementation
    }
}

public extension View {
    /// Adds data point selection handling to a chart.
    func chartSelection(
        selectedIndex: Binding<Int?>,
        dataCount: Int,
        onSelect: ((Int) -> Void)? = nil
    ) -> some View {
        modifier(ChartSelectionModifier(
            selectedIndex: selectedIndex,
            dataCount: dataCount,
            onSelect: onSelect
        ))
    }
}

// MARK: - Crosshair Overlay

/// A crosshair overlay for precise data point inspection.
public struct ChartCrosshair: View {
    let position: CGPoint
    let chartBounds: CGRect
    let xValue: String
    let yValue: String
    let color: Color
    
    public init(
        position: CGPoint,
        chartBounds: CGRect,
        xValue: String,
        yValue: String,
        color: Color = .secondary
    ) {
        self.position = position
        self.chartBounds = chartBounds
        self.xValue = xValue
        self.yValue = yValue
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            // Vertical line
            Path { path in
                path.move(to: CGPoint(x: position.x, y: chartBounds.minY))
                path.addLine(to: CGPoint(x: position.x, y: chartBounds.maxY))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            
            // Horizontal line
            Path { path in
                path.move(to: CGPoint(x: chartBounds.minX, y: position.y))
                path.addLine(to: CGPoint(x: chartBounds.maxX, y: position.y))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            
            // Center point
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .position(position)
            
            // X value label
            Text(xValue)
                .font(.caption2)
                .padding(4)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(4)
                .position(x: position.x, y: chartBounds.maxY + 12)
            
            // Y value label
            Text(yValue)
                .font(.caption2)
                .padding(4)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(4)
                .position(x: chartBounds.minX - 25, y: position.y)
        }
    }
}

// MARK: - Range Selection

/// A range selection overlay for selecting data ranges.
public struct ChartRangeSelection: View {
    @Binding var startX: CGFloat?
    @Binding var endX: CGFloat?
    let chartBounds: CGRect
    let color: Color
    let onRangeSelected: ((CGFloat, CGFloat) -> Void)?
    
    @State private var isDragging = false
    
    public init(
        startX: Binding<CGFloat?>,
        endX: Binding<CGFloat?>,
        chartBounds: CGRect,
        color: Color = .blue,
        onRangeSelected: ((CGFloat, CGFloat) -> Void)? = nil
    ) {
        self._startX = startX
        self._endX = endX
        self.chartBounds = chartBounds
        self.color = color
        self.onRangeSelected = onRangeSelected
    }
    
    public var body: some View {
        ZStack {
            if let start = startX, let end = endX {
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(width: abs(end - start))
                    .position(x: (start + end) / 2, y: chartBounds.midY)
                    .frame(height: chartBounds.height)
                
                // Start handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: chartBounds.height)
                    .position(x: start, y: chartBounds.midY)
                
                // End handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: chartBounds.height)
                    .position(x: end, y: chartBounds.midY)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        startX = value.location.x
                    }
                    endX = value.location.x
                }
                .onEnded { value in
                    isDragging = false
                    if let start = startX, let end = endX {
                        let sortedStart = min(start, end)
                        let sortedEnd = max(start, end)
                        onRangeSelected?(sortedStart, sortedEnd)
                    }
                }
        )
    }
}

// MARK: - Double Tap to Reset

/// A view modifier that resets zoom on double tap.
public struct DoubleTapToResetModifier: ViewModifier {
    @Binding var resetTrigger: Bool
    
    public func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) {
                resetTrigger = true
            }
    }
}

public extension View {
    /// Adds double-tap to reset functionality.
    func doubleTapToReset(_ trigger: Binding<Bool>) -> some View {
        modifier(DoubleTapToResetModifier(resetTrigger: trigger))
    }
}
