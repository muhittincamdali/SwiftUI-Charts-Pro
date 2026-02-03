import SwiftUI

// MARK: - Chart Animation

/// Predefined animation configurations for charts.
///
/// Use these animations for consistent, professional chart transitions.
///
/// ```swift
/// RadarChart(data: data)
///     .chartAnimation(.spring)
/// ```
public enum ChartAnimation {
    /// Quick and snappy animation
    case quick
    
    /// Standard smooth animation
    case smooth
    
    /// Bouncy spring animation
    case spring
    
    /// Slow reveal animation
    case reveal
    
    /// No animation
    case none
    
    /// Custom animation
    case custom(Animation)
    
    /// Converts to SwiftUI Animation
    public var animation: Animation? {
        switch self {
        case .quick:
            return .easeOut(duration: 0.2)
        case .smooth:
            return .easeInOut(duration: 0.4)
        case .spring:
            return .spring(response: 0.5, dampingFraction: 0.7)
        case .reveal:
            return .easeOut(duration: 0.8)
        case .none:
            return nil
        case .custom(let animation):
            return animation
        }
    }
}

// MARK: - Animated Value

/// A property wrapper that animates value changes.
@propertyWrapper
public struct AnimatedValue<Value: VectorArithmetic>: DynamicProperty {
    @State private var current: Value
    @State private var target: Value
    
    private let animation: Animation
    
    public init(wrappedValue: Value, animation: Animation = .easeInOut(duration: 0.3)) {
        self._current = State(initialValue: wrappedValue)
        self._target = State(initialValue: wrappedValue)
        self.animation = animation
    }
    
    public var wrappedValue: Value {
        get { current }
        nonmutating set {
            target = newValue
            withAnimation(animation) {
                current = newValue
            }
        }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { current },
            set: { newValue in
                target = newValue
                withAnimation(animation) {
                    current = newValue
                }
            }
        )
    }
}

// MARK: - Chart Animation Modifier

/// A view modifier for applying chart animations.
public struct ChartAnimationModifier: ViewModifier {
    let animation: ChartAnimation
    let trigger: Bool
    
    public init(animation: ChartAnimation, trigger: Bool) {
        self.animation = animation
        self.trigger = trigger
    }
    
    public func body(content: Content) -> some View {
        content
            .animation(animation.animation, value: trigger)
    }
}

public extension View {
    /// Applies a chart animation to this view.
    func chartAnimation(_ animation: ChartAnimation, trigger: Bool = true) -> some View {
        modifier(ChartAnimationModifier(animation: animation, trigger: trigger))
    }
}

// MARK: - Staggered Animation

/// Coordinates staggered animations across multiple chart elements.
public struct StaggeredAnimation {
    /// Delay between each element
    public let staggerDelay: Double
    
    /// Base animation
    public let baseAnimation: Animation
    
    /// Total number of elements
    public let elementCount: Int
    
    /// Creates a staggered animation configuration.
    public init(
        elementCount: Int,
        staggerDelay: Double = 0.05,
        baseAnimation: Animation = .easeOut(duration: 0.4)
    ) {
        self.elementCount = elementCount
        self.staggerDelay = staggerDelay
        self.baseAnimation = baseAnimation
    }
    
    /// Gets the animation for a specific element index.
    public func animation(for index: Int) -> Animation {
        baseAnimation.delay(Double(index) * staggerDelay)
    }
    
    /// Total animation duration including all staggers.
    public var totalDuration: Double {
        Double(elementCount - 1) * staggerDelay + 0.4 // base duration
    }
}

// MARK: - Animated Chart Modifier

/// A modifier that animates chart appearance with staggered animations.
public struct StaggeredAnimationModifier: ViewModifier {
    let index: Int
    let stagger: StaggeredAnimation
    @State private var isVisible: Bool = false
    
    public init(index: Int, stagger: StaggeredAnimation) {
        self.index = index
        self.stagger = stagger
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(stagger.animation(for: index), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

public extension View {
    /// Applies a staggered animation to this view.
    func staggeredAnimation(index: Int, stagger: StaggeredAnimation) -> some View {
        modifier(StaggeredAnimationModifier(index: index, stagger: stagger))
    }
}

// MARK: - Path Animation

/// Animates a path from empty to complete.
public struct AnimatedPath: Shape {
    var progress: CGFloat
    let path: Path
    
    public var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    public init(progress: CGFloat, path: Path) {
        self.progress = progress
        self.path = path
    }
    
    public func path(in rect: CGRect) -> Path {
        path.trimmedPath(from: 0, to: progress)
    }
}

// MARK: - Counting Animation

/// Animates a number counting up or down.
public struct CountingAnimation: Animatable, View {
    var value: Double
    let format: String
    let font: Font
    let color: Color
    
    public var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    public init(
        value: Double,
        format: String = "%.0f",
        font: Font = .body,
        color: Color = .primary
    ) {
        self.value = value
        self.format = format
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        Text(String(format: format, value))
            .font(font)
            .foregroundColor(color)
            .monospacedDigit()
    }
}

// MARK: - Pulse Animation

/// A pulsing animation effect for highlighting elements.
public struct PulseAnimation: ViewModifier {
    @State private var isPulsing: Bool = false
    
    let isActive: Bool
    let scale: CGFloat
    let duration: Double
    
    public init(isActive: Bool = true, scale: CGFloat = 1.1, duration: Double = 0.8) {
        self.isActive = isActive
        self.scale = scale
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing && isActive ? scale : 1.0)
            .animation(
                isActive ?
                    .easeInOut(duration: duration).repeatForever(autoreverses: true) :
                    .default,
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

public extension View {
    /// Adds a pulse animation to this view.
    func pulseAnimation(isActive: Bool = true, scale: CGFloat = 1.1) -> some View {
        modifier(PulseAnimation(isActive: isActive, scale: scale))
    }
}

// MARK: - Wave Animation

/// Creates a wave animation effect across multiple elements.
public struct WaveAnimation: ViewModifier {
    let index: Int
    let totalCount: Int
    let amplitude: CGFloat
    let frequency: Double
    
    @State private var phase: Double = 0
    
    public init(index: Int, totalCount: Int, amplitude: CGFloat = 10, frequency: Double = 2) {
        self.index = index
        self.totalCount = totalCount
        self.amplitude = amplitude
        self.frequency = frequency
    }
    
    public func body(content: Content) -> some View {
        let offset = sin(phase + Double(index) / Double(totalCount) * .pi * 2) * Double(amplitude)
        
        content
            .offset(y: CGFloat(offset))
            .onAppear {
                withAnimation(
                    .linear(duration: 1 / frequency)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = .pi * 2
                }
            }
    }
}

public extension View {
    /// Adds a wave animation to this view.
    func waveAnimation(index: Int, totalCount: Int, amplitude: CGFloat = 10) -> some View {
        modifier(WaveAnimation(index: index, totalCount: totalCount, amplitude: amplitude))
    }
}

// MARK: - Shimmer Animation

/// A shimmer/loading animation effect.
public struct ShimmerAnimation: ViewModifier {
    @State private var phase: CGFloat = 0
    
    let isActive: Bool
    let duration: Double
    
    public init(isActive: Bool = true, duration: Double = 1.5) {
        self.isActive = isActive
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .opacity(isActive ? 1 : 0)
            )
            .clipShape(Rectangle())
            .onAppear {
                guard isActive else { return }
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

public extension View {
    /// Adds a shimmer animation to this view.
    func shimmerAnimation(isActive: Bool = true) -> some View {
        modifier(ShimmerAnimation(isActive: isActive))
    }
}

// MARK: - Data Transition Animator

/// Manages smooth transitions between chart data sets.
@MainActor
public class DataTransitionAnimator<T>: ObservableObject {
    @Published public var currentData: [T]
    @Published public var isAnimating: Bool = false
    
    private var targetData: [T]
    
    public init(initialData: [T]) {
        self.currentData = initialData
        self.targetData = initialData
    }
    
    /// Transitions to new data with animation.
    public func transition(to newData: [T], duration: Double = 0.5) {
        targetData = newData
        isAnimating = true
        
        withAnimation(.easeInOut(duration: duration)) {
            currentData = newData
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isAnimating = false
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ChartAnimation_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Counting animation
            CountingAnimation(value: 1234, format: "%.0f", font: .largeTitle.bold())
            
            // Pulse animation
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .pulseAnimation()
            
            // Shimmer
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 40)
                .shimmerAnimation()
        }
        .padding()
    }
}
#endif
