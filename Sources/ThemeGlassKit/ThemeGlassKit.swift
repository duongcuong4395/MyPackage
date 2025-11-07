//
//  ThemeGlassKit.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI
import Combine

// MARK: - Performance Monitor
@available(iOS 14.0, *)
@MainActor
public class PerformanceMonitor: ObservableObject {
    @Published var shouldReduceMotion = false
    @Published var deviceTier: DeviceTier = .high
    
    enum DeviceTier {
        case high, medium, low
    }
    
    public init() {
        shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        deviceTier = detectDeviceTier()
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
            }
        }
    }
    
    private func detectDeviceTier() -> DeviceTier {
        let processInfo = ProcessInfo.processInfo
        let cores = processInfo.activeProcessorCount
        if cores >= 6 { return .high }
        if cores >= 4 { return .medium }
        return .low
    }
}

// MARK: - Optimized UI Glass Material
@available(iOS 14.0, *)
public struct UIGlassMaterial: ViewModifier {
    let cornerRadius: Double
    let intensity: Double
    let tintColor: Color
    let isInteractive: Bool
    let hasShimmer: Bool
    let hasGlow: Bool
    
    @State private var glowIntensity: Double = 0.0
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var hoverScale: CGFloat = 1.0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var perfMonitor = PerformanceMonitor()
    
    public init(
        cornerRadius: Double = 16,
        intensity: Double = 0.8,
        tintColor: Color = .white,
        isInteractive: Bool = true,
        hasShimmer: Bool = false,
        hasGlow: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.tintColor = tintColor
        self.isInteractive = isInteractive
        self.hasShimmer = hasShimmer
        self.hasGlow = hasGlow
    }
    
    public func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .scaleEffect(hoverScale)
            .animation(animationForScale, value: hoverScale)
            .onAppear(perform: startAnimations)
            .accessibilityElement(children: .contain)
    }
    
    // MARK: - Optimized Background
    private var glassBackground: some View {
        ZStack {
            // Base glass layer with dark mode support
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(baseGradient)
            
            // Conditional shimmer (only if enabled and not reduce motion)
            if hasShimmer && !reduceMotion && perfMonitor.deviceTier != .low {
                shimmerOverlay
            }
            
            // Border highlight
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderGradient, lineWidth: 1)
        }
    }
    
    private var baseGradient: LinearGradient {
        let baseOpacity = colorScheme == .dark ? 0.25 : 0.15
        let secondaryOpacity = colorScheme == .dark ? 0.15 : 0.05
        
        return LinearGradient(
            colors: [
                tintColor.opacity(baseOpacity + (hasGlow ? glowIntensity * 0.1 : 0)),
                tintColor.opacity(secondaryOpacity + (hasGlow ? glowIntensity * 0.05 : 0))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var shimmerOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                        Color.clear
                    ],
                    startPoint: UnitPoint(x: shimmerOffset, y: 0),
                    endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 1)
                )
            )
            .mask(RoundedRectangle(cornerRadius: cornerRadius))
            .animation(shimmerAnimation, value: shimmerOffset)
    }
    
    private var borderGradient: LinearGradient {
        let opacity = colorScheme == .dark ? 0.4 : 0.6
        return LinearGradient(
            colors: [
                Color.white.opacity(opacity),
                Color.white.opacity(0.1),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Optimized Animations
    private var animationForScale: Animation? {
        reduceMotion ? .none : .easeInOut(duration: 0.2)
    }
    
    private var shimmerAnimation: Animation? {
        guard !reduceMotion else { return .none }
        return .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    }
    
    private var glowAnimation: Animation? {
        guard !reduceMotion else { return .none }
        return .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }
    
    private func startAnimations() {
        guard !reduceMotion else { return }
        
        if hasShimmer && perfMonitor.deviceTier != .low {
            withAnimation(shimmerAnimation) {
                shimmerOffset = 1.0
            }
        }
        
        if hasGlow {
            withAnimation(glowAnimation) {
                glowIntensity = 1.0
            }
        }
    }
}









// MARK: - Advanced Effects (Optimized)
@available(iOS 13.0, *)
public struct UIGlassBlur: ViewModifier {
    let radius: CGFloat
    let opaque: Bool
    
    public init(radius: CGFloat = 10, opaque: Bool = false) {
        self.radius = radius
        self.opaque = opaque
    }
    
    public func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            content
                .background(
                    VisualEffectBlur(blurStyle: .systemThinMaterial)
                        .cornerRadius(16)
                )
        }
    }
}

@available(iOS 13.0, *)
struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

@available(iOS 17.0, *)
public struct LensingEffect: ViewModifier {
    @State private var lensPosition: CGPoint = .zero
    @State private var showLens = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !reduceMotion {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .position(lensPosition)
                            .opacity(showLens ? 1 : 0)
                            .animation(.easeOut(duration: 0.3), value: showLens)
                    }
                }
            )
            .onTapGesture { location in
                guard !reduceMotion else { return }
                lensPosition = location
                showLens = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [showLens] in
                    guard showLens else { return }
                    self.showLens = false
                }
            }
    }
}

// MARK: - Optimized Morphing Shape (Cached Path)
@available(iOS 14.0, *)
public struct MorphingGlass<Content: View>: View {
    let content: Content
    @State private var morphPhase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var perfMonitor = PerformanceMonitor()
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        Group {
            if !reduceMotion && perfMonitor.deviceTier == .high {
                content
                    .clipShape(MorphingShape(phase: morphPhase))
                    .modifier(UIGlassMaterial())
                    .onAppear {
                        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                            morphPhase = 1
                        }
                    }
            } else {
                content
                    .modifier(UIGlassMaterial())
            }
        }
    }
}

@available(iOS 14.0, *)
struct MorphingShape: Shape {
    let phase: Double
    
    var animatableData: Double {
        get { phase }
        set { }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let waveHeight = 10.0
        let step: CGFloat = 5 // Reduced resolution for performance
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        for x in stride(from: 0, through: width, by: step) {
            let relativeX = x / width
            let sine = sin((relativeX + phase) * 2 * .pi * 2) * waveHeight
            let y = height * 0.5 + sine
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Extensions
@available(iOS 17.0, *)
extension View {
    public func uiGlass(
        cornerRadius: Double = 16,
        intensity: Double = 0.8,
        tintColor: Color = .white,
        isInteractive: Bool = true,
        hasShimmer: Bool = false,
        hasGlow: Bool = false
    ) -> some View {
        self.modifier(
            UIGlassMaterial(
                cornerRadius: cornerRadius,
                intensity: intensity,
                tintColor: tintColor,
                isInteractive: isInteractive,
                hasShimmer: hasShimmer,
                hasGlow: hasGlow
            )
        )
    }
    
    public func uiGlassBlur(radius: CGFloat = 10, opaque: Bool = false) -> some View {
        self.modifier(UIGlassBlur(radius: radius, opaque: opaque))
    }
    
    public func lensingEffect() -> some View {
        self.modifier(LensingEffect())
    }
    
    public func morphingGlass() -> some View {
        MorphingGlass {
            self
        }
    }
}

// MARK: - Preset Styles
@available(iOS 14.0, *)
public extension UIGlassMaterial {
    static let card = UIGlassMaterial(
        intensity: 0.9,
        tintColor: .white,
        isInteractive: false,
        hasShimmer: false,
        hasGlow: false
    )
    
    static let button = UIGlassMaterial(
        intensity: 0.8,
        tintColor: .blue,
        isInteractive: true,
        hasShimmer: true,
        hasGlow: true
    )
    
    static let navigation = UIGlassMaterial(
        intensity: 1.0,
        tintColor: .white,
        isInteractive: false,
        hasShimmer: false,
        hasGlow: false
    )
    
    static let subtle = UIGlassMaterial(
        intensity: 0.6,
        tintColor: .gray,
        isInteractive: false,
        hasShimmer: false,
        hasGlow: false
    )
    
    static let shimmer = UIGlassMaterial(
        intensity: 0.8,
        tintColor: .white,
        isInteractive: true,
        hasShimmer: true,
        hasGlow: false
    )
    
    static let glow = UIGlassMaterial(
        intensity: 0.8,
        tintColor: .blue,
        isInteractive: true,
        hasShimmer: false,
        hasGlow: true
    )
}



/*
// MARK: - Preview Provider
struct UIGlassDemoApp_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIGlassDemoApp()
                .preferredColorScheme(.light)
            
            UIGlassDemoApp()
                .preferredColorScheme(.dark)
        }
    }
}
*/
