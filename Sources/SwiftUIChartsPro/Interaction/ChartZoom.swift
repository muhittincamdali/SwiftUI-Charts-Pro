import SwiftUI

// MARK: - Chart Zoom Manager

/// Manages zoom and pan state for interactive charts.
///
/// Use `ChartZoomManager` to enable pinch-to-zoom and pan gestures
/// on chart views.
///
/// ```swift
/// @StateObject var zoom = ChartZoomManager()
///
/// MyChart(data: data)
///     .chartZoom(manager: zoom)
/// ```
@MainActor
public class ChartZoomManager: ObservableObject {
    /// Current zoom scale
    @Published public var scale: CGFloat = 1.0
    
    /// Current pan offset
    @Published public var offset: CGSize = .zero
    
    /// Minimum zoom scale
    public var minScale: CGFloat = 1.0
    
    /// Maximum zoom scale
    public var maxScale: CGFloat = 5.0
    
    /// Whether zoom is enabled
    public var zoomEnabled: Bool = true
    
    /// Whether pan is enabled
    public var panEnabled: Bool = true
    
    /// Anchor point for zoom
    @Published public var zoomAnchor: UnitPoint = .center
    
    /// Callback when zoom changes
    public var onZoomChange: ((CGFloat, CGSize) -> Void)?
    
    // Gesture state
    private var lastScale: CGFloat = 1.0
    private var lastOffset: CGSize = .zero
    
    public init(
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 5.0,
        zoomEnabled: Bool = true,
        panEnabled: Bool = true
    ) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.zoomEnabled = zoomEnabled
        self.panEnabled = panEnabled
    }
    
    /// Resets zoom and pan to default values.
    public func reset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = 1.0
            offset = .zero
            zoomAnchor = .center
        }
        onZoomChange?(scale, offset)
    }
    
    /// Zooms to a specific scale.
    public func zoomTo(_ newScale: CGFloat, animated: Bool = true) {
        let clampedScale = clamp(newScale, min: minScale, max: maxScale)
        
        if animated {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = clampedScale
            }
        } else {
            scale = clampedScale
        }
        onZoomChange?(scale, offset)
    }
    
    /// Zooms in by a factor.
    public func zoomIn(factor: CGFloat = 1.5) {
        zoomTo(scale * factor)
    }
    
    /// Zooms out by a factor.
    public func zoomOut(factor: CGFloat = 1.5) {
        zoomTo(scale / factor)
    }
    
    /// Pans to a specific offset.
    public func panTo(_ newOffset: CGSize, animated: Bool = true) {
        if animated {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                offset = newOffset
            }
        } else {
            offset = newOffset
        }
        onZoomChange?(scale, offset)
    }
    
    /// Handles magnification gesture.
    public func handleMagnification(_ value: CGFloat) {
        guard zoomEnabled else { return }
        let newScale = lastScale * value
        scale = clamp(newScale, min: minScale, max: maxScale)
    }
    
    /// Called when magnification gesture ends.
    public func endMagnification() {
        lastScale = scale
        onZoomChange?(scale, offset)
    }
    
    /// Handles drag gesture.
    public func handleDrag(_ translation: CGSize) {
        guard panEnabled else { return }
        offset = CGSize(
            width: lastOffset.width + translation.width,
            height: lastOffset.height + translation.height
        )
    }
    
    /// Called when drag gesture ends.
    public func endDrag() {
        lastOffset = offset
        onZoomChange?(scale, offset)
    }
    
    /// Zooms to fit a specific rect within the view.
    public func zoomToFit(rect: CGRect, in viewSize: CGSize, padding: CGFloat = 20) {
        let scaleX = (viewSize.width - padding * 2) / rect.width
        let scaleY = (viewSize.height - padding * 2) / rect.height
        let newScale = min(scaleX, scaleY, maxScale)
        
        let centerX = rect.midX - viewSize.width / 2
        let centerY = rect.midY - viewSize.height / 2
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            scale = newScale
            offset = CGSize(width: -centerX * newScale, height: -centerY * newScale)
        }
        
        lastScale = scale
        lastOffset = offset
        onZoomChange?(scale, offset)
    }
    
    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Chart Zoom Modifier

/// A view modifier that adds zoom and pan gestures to a chart.
public struct ChartZoomModifier: ViewModifier {
    @ObservedObject var manager: ChartZoomManager
    let enableDoubleTapZoom: Bool
    
    public init(manager: ChartZoomManager, enableDoubleTapZoom: Bool = true) {
        self.manager = manager
        self.enableDoubleTapZoom = enableDoubleTapZoom
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(manager.scale, anchor: manager.zoomAnchor)
            .offset(manager.offset)
            .gesture(magnificationGesture)
            .gesture(dragGesture)
            .simultaneousGesture(doubleTapGesture)
    }
    
    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                manager.handleMagnification(value.magnification)
            }
            .onEnded { _ in
                manager.endMagnification()
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                manager.handleDrag(value.translation)
            }
            .onEnded { _ in
                manager.endDrag()
            }
    }
    
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if enableDoubleTapZoom {
                    if manager.scale > 1.0 {
                        manager.reset()
                    } else {
                        manager.zoomTo(2.0)
                    }
                }
            }
    }
}

public extension View {
    /// Adds zoom and pan capabilities to this view.
    func chartZoom(
        manager: ChartZoomManager,
        enableDoubleTapZoom: Bool = true
    ) -> some View {
        modifier(ChartZoomModifier(manager: manager, enableDoubleTapZoom: enableDoubleTapZoom))
    }
}

// MARK: - Zoom Controls View

/// A control panel for zoom operations.
public struct ZoomControlsView: View {
    @ObservedObject var manager: ChartZoomManager
    
    let showResetButton: Bool
    let buttonStyle: ZoomButtonStyle
    
    public init(
        manager: ChartZoomManager,
        showResetButton: Bool = true,
        buttonStyle: ZoomButtonStyle = .circular
    ) {
        self.manager = manager
        self.showResetButton = showResetButton
        self.buttonStyle = buttonStyle
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            zoomButton(systemName: "minus.magnifyingglass") {
                manager.zoomOut()
            }
            
            if showResetButton {
                zoomButton(systemName: "arrow.counterclockwise") {
                    manager.reset()
                }
            }
            
            zoomButton(systemName: "plus.magnifyingglass") {
                manager.zoomIn()
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: buttonStyle == .circular ? 20 : 8)
                .fill(.ultraThinMaterial)
        )
    }
    
    @ViewBuilder
    private func zoomButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(
                    buttonBackground
                )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch buttonStyle {
        case .circular:
            Circle()
                .fill(Color.primary.opacity(0.1))
        case .rounded:
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.1))
        case .minimal:
            EmptyView()
        }
    }
}

/// Zoom control button styles
public enum ZoomButtonStyle {
    case circular
    case rounded
    case minimal
}

// MARK: - Zoom Level Indicator

/// Displays the current zoom level.
public struct ZoomLevelIndicator: View {
    @ObservedObject var manager: ChartZoomManager
    
    public init(manager: ChartZoomManager) {
        self.manager = manager
    }
    
    public var body: some View {
        Text("\(Int(manager.scale * 100))%")
            .font(.caption.monospacedDigit())
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .opacity(manager.scale != 1.0 ? 1 : 0.5)
    }
}

// MARK: - Minimap View

/// A minimap showing the current viewport position within the full chart.
public struct ChartMinimapView<Content: View>: View {
    @ObservedObject var manager: ChartZoomManager
    let content: () -> Content
    
    public init(
        manager: ChartZoomManager,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.manager = manager
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            // Miniature chart
            content()
                .opacity(0.5)
            
            // Viewport indicator
            GeometryReader { geometry in
                let viewportWidth = geometry.size.width / manager.scale
                let viewportHeight = geometry.size.height / manager.scale
                let offsetX = -manager.offset.width / manager.scale / 2 + (geometry.size.width - viewportWidth) / 2
                let offsetY = -manager.offset.height / manager.scale / 2 + (geometry.size.height - viewportHeight) / 2
                
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: viewportWidth, height: viewportHeight)
                    .offset(x: offsetX, y: offsetY)
            }
        }
        .frame(width: 120, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ChartZoom_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ZoomControlsView(manager: ChartZoomManager())
            
            ZoomLevelIndicator(manager: ChartZoomManager())
            
            Spacer()
        }
        .padding()
    }
}
#endif
