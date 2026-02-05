import SwiftUI

// MARK: - Animation Presets

/// Pre-defined animation presets for chart transitions.
///
/// These animations are carefully tuned for data visualization,
/// providing smooth, professional-looking transitions.
///
/// ```swift
/// LineChart(data: data)
///     .chartAnimation(.spring)
/// ```
public enum ChartAnimationPreset: String, CaseIterable {
    /// No animation
    case none
    /// Quick, snappy animation
    case quick
    /// Smooth ease-in-out animation
    case smooth
    /// Bouncy spring animation
    case spring
    /// Elastic overshoot animation
    case elastic
    /// Gentle fade animation
    case fade
    /// Dramatic entrance animation
    case dramatic
    /// Staggered reveal animation
    case staggered
    /// Wave effect animation
    case wave
    
    /// The SwiftUI animation for this preset.
    public var animation: Animation? {
        switch self {
        case .none:
            return nil
        case .quick:
            return .easeOut(duration: 0.2)
        case .smooth:
            return .easeInOut(duration: 0.5)
        case .spring:
            return .spring(response: 0.4, dampingFraction: 0.75)
        case .elastic:
            return .spring(response: 0.5, dampingFraction: 0.5)
        case .fade:
            return .easeIn(duration: 0.6)
        case .dramatic:
            return .interpolatingSpring(stiffness: 50, damping: 8)
        case .staggered:
            return .easeOut(duration: 0.4)
        case .wave:
            return .easeInOut(duration: 0.6)
        }
    }
    
    /// Duration hint for this animation.
    public var duration: Double {
        switch self {
        case .none: return 0
        case .quick: return 0.2
        case .smooth: return 0.5
        case .spring: return 0.4
        case .elastic: return 0.6
        case .fade: return 0.6
        case .dramatic: return 0.8
        case .staggered: return 0.6
        case .wave: return 0.8
        }
    }
}

// MARK: - Animation Modifier

/// A view modifier that applies chart animations.
public struct ChartAnimationModifier: ViewModifier {
    let preset: ChartAnimationPreset
    @State private var isAnimated = false
    
    public init(preset: ChartAnimationPreset) {
        self.preset = preset
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isAnimated ? 1 : 0)
            .scaleEffect(isAnimated ? 1 : (preset == .dramatic ? 0.8 : 0.95))
            .onAppear {
                if let animation = preset.animation {
                    withAnimation(animation) {
                        isAnimated = true
                    }
                } else {
                    isAnimated = true
                }
            }
    }
}

public extension View {
    /// Applies a chart animation preset.
    func chartAnimation(_ preset: ChartAnimationPreset) -> some View {
        modifier(ChartAnimationModifier(preset: preset))
    }
}

// MARK: - Staggered Animation Container

/// A container that animates children with staggered delays.
public struct StaggeredAnimationContainer<Content: View>: View {
    let content: Content
    let itemCount: Int
    let baseDelay: Double
    let itemDelay: Double
    let animation: Animation
    
    @State private var animatedIndices: Set<Int> = []
    
    public init(
        itemCount: Int,
        baseDelay: Double = 0.1,
        itemDelay: Double = 0.05,
        animation: Animation = .spring(response: 0.4, dampingFraction: 0.75),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.itemCount = itemCount
        self.baseDelay = baseDelay
        self.itemDelay = itemDelay
        self.animation = animation
    }
    
    public var body: some View {
        content
            .onAppear {
                for index in 0..<itemCount {
                    let delay = baseDelay + Double(index) * itemDelay
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(animation) {
                            animatedIndices.insert(index)
                        }
                    }
                }
            }
            .environment(\.staggeredAnimationIndices, animatedIndices)
    }
}

// MARK: - Staggered Animation Environment

struct StaggeredAnimationIndicesKey: EnvironmentKey {
    static let defaultValue: Set<Int> = []
}

extension EnvironmentValues {
    var staggeredAnimationIndices: Set<Int> {
        get { self[StaggeredAnimationIndicesKey.self] }
        set { self[StaggeredAnimationIndicesKey.self] = newValue }
    }
}

// MARK: - Data Change Animation

/// Animates changes in chart data with morphing transitions.
public struct DataChangeAnimator<T: Equatable>: ViewModifier {
    let data: [T]
    let animation: Animation
    
    @State private var displayedData: [T]
    @State private var isTransitioning = false
    
    public init(data: [T], animation: Animation = .easeInOut(duration: 0.3)) {
        self.data = data
        self.animation = animation
        self._displayedData = State(initialValue: data)
    }
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: data) { newData in
                withAnimation(animation) {
                    isTransitioning = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    displayedData = newData
                    withAnimation(animation) {
                        isTransitioning = false
                    }
                }
            }
            .opacity(isTransitioning ? 0.5 : 1.0)
            .scaleEffect(isTransitioning ? 0.98 : 1.0)
    }
}

// MARK: - Pulse Animation

/// A pulsing animation for highlighting data points.
public struct PulseAnimationModifier: ViewModifier {
    let isActive: Bool
    let color: Color
    
    @State private var isPulsing = false
    
    public init(isActive: Bool, color: Color = .blue) {
        self.isActive = isActive
        self.color = color
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(isPulsing ? 2.0 : 1.0)
                    .opacity(isPulsing ? 0 : 0.5)
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

public extension View {
    /// Adds a pulsing animation.
    func pulseAnimation(isActive: Bool, color: Color = .blue) -> some View {
        modifier(PulseAnimationModifier(isActive: isActive, color: color))
    }
}

// MARK: - Shimmer Effect

/// A shimmer loading effect for charts.
public struct ShimmerModifier: ViewModifier {
    let isLoading: Bool
    
    @State private var phase: CGFloat = 0
    
    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isLoading {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.5),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.5)
                        .offset(x: phase * geometry.size.width * 1.5 - geometry.size.width * 0.25)
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: phase
                        )
                        .onAppear {
                            phase = 1
                        }
                    }
                }
                .mask(content)
            )
    }
}

public extension View {
    /// Adds a shimmer loading effect.
    func shimmer(isLoading: Bool) -> some View {
        modifier(ShimmerModifier(isLoading: isLoading))
    }
}

// MARK: - Count Up Animation

/// Animates a number counting up from zero.
public struct CountUpText: View {
    let targetValue: Double
    let duration: Double
    let format: String
    
    @State private var currentValue: Double = 0
    
    public init(
        value: Double,
        duration: Double = 1.0,
        format: String = "%.0f"
    ) {
        self.targetValue = value
        self.duration = duration
        self.format = format
    }
    
    public var body: some View {
        Text(String(format: format, currentValue))
            .onAppear {
                animateValue()
            }
            .onChange(of: targetValue) { _ in
                animateValue()
            }
    }
    
    private func animateValue() {
        let startValue = currentValue
        let steps = 60
        let stepDuration = duration / Double(steps)
        let increment = (targetValue - startValue) / Double(steps)
        
        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                let progress = Double(step) / Double(steps)
                let eased = easeOutQuad(progress)
                currentValue = startValue + (targetValue - startValue) * eased
            }
        }
    }
    
    private func easeOutQuad(_ t: Double) -> Double {
        1 - (1 - t) * (1 - t)
    }
}

// MARK: - Path Drawing Animation

/// Animates a path being drawn.
public struct PathDrawingModifier: ViewModifier {
    let duration: Double
    @State private var drawProgress: CGFloat = 0
    
    public init(duration: Double = 1.0) {
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .modifier(AnimatablePathTrimModifier(drawProgress: drawProgress))
            .onAppear {
                withAnimation(.easeInOut(duration: duration)) {
                    drawProgress = 1
                }
            }
    }
}

struct AnimatablePathTrimModifier: AnimatableModifier {
    var drawProgress: CGFloat
    
    var animatableData: CGFloat {
        get { drawProgress }
        set { drawProgress = newValue }
    }
    
    func body(content: Content) -> some View {
        content
        // Note: This would need to be applied directly to Path views
    }
}

// MARK: - Transition Helpers

public extension AnyTransition {
    /// A chart-optimized slide transition.
    static var chartSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// A scale transition from the bottom.
    static var chartScale: AnyTransition {
        .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity)
    }
    
    /// A flip transition for data updates.
    static var chartFlip: AnyTransition {
        .modifier(
            active: FlipModifier(angle: 90),
            identity: FlipModifier(angle: 0)
        )
    }
}

struct FlipModifier: ViewModifier {
    let angle: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 1, y: 0, z: 0)
            )
            .opacity(angle == 0 ? 1 : 0)
    }
}
