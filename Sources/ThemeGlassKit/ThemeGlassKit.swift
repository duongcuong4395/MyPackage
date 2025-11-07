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
extension UIGlassMaterial {
    public static let card = UIGlassMaterial(
        intensity: 0.9,
        tintColor: .white,
        isInteractive: false,
        hasShimmer: false,
        hasGlow: false
    )
    
    public static let button = UIGlassMaterial(
        intensity: 0.8,
        tintColor: .blue,
        isInteractive: true,
        hasShimmer: true,
        hasGlow: true
    )
    
    public static let navigation = UIGlassMaterial(
        intensity: 1.0,
        tintColor: .white,
        isInteractive: false,
        hasShimmer: false,
        hasGlow: false
    )
    
    public static let subtle = UIGlassMaterial(
        intensity: 0.6,
        tintColor: .gray,
        isInteractive: false,
        hasShimmer: false,
        hasGlow: false
    )
    
    public static let shimmer = UIGlassMaterial(
        intensity: 0.8,
        tintColor: .white,
        isInteractive: true,
        hasShimmer: true,
        hasGlow: false
    )
    
    public static let glow = UIGlassMaterial(
        intensity: 0.8,
        tintColor: .blue,
        isInteractive: true,
        hasShimmer: false,
        hasGlow: true
    )
}

// MARK: - Comprehensive Demo App
@available(iOS 17.0, *)
struct UIGlassDemoApp: View {
    @State private var selectedTab = 0
    @State private var sliderValue: Double = 0.5
    @State private var toggleValue = false
    @State private var textFieldValue = ""
    @State private var showLoadingDemo = false
    @State private var progressValue: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.pink.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Conditional particle background
            ParticleGlass()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                UIGlassNavigationBar(title: "Theme UI Glass Demo") {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            introSection
                            buttonsSection
                            cardsSection
                            formControlsSection
                            loadingSection
                            effectsSection
                            presetStylesSection
                            performanceSection
                            accessibilitySection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }
                }
            }
            
            // Tab Bar
            VStack {
                Spacer()
                UIGlassTabBar(
                    selection: $selectedTab,
                    items: [
                        TabItem2(title: "Home", icon: "house.fill"),
                        TabItem2(title: "Components", icon: "square.grid.2x2"),
                        TabItem2(title: "Effects", icon: "wand.and.stars"),
                        TabItem2(title: "Settings", icon: "gear")
                    ]
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Demo Sections
    
    private var introSection: some View {
        UIGlassCard(elevation: 2.0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.title)
                    
                    VStack(alignment: .leading) {
                        Text("Welcome to UI Glass")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Modern glassmorphism design system")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text("This demo showcases all optimized components with:")
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Performance optimizations", systemImage: "bolt.fill")
                    Label("Accessibility support", systemImage: "accessibility")
                    Label("Dark mode ready", systemImage: "moon.fill")
                    Label("Reduce motion support", systemImage: "hand.raised.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interactive Buttons")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack(spacing: 15) {
                    UIGlassButton(action: {
                        print("Primary tapped")
                    }) {
                        Text("Primary")
                            .fontWeight(.semibold)
                    }
                    
                    UIGlassButton(action: {
                        print("Secondary tapped")
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Secondary")
                        }
                    }
                }
                
                UIGlassButton(action: {
                    print("Full width tapped")
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Full Width Button")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Glass Cards")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            UIGlassCard(elevation: 1.5) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Standard Card")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("With elevation and shadow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    Text("This card demonstrates the ui glass material with subtle animations and responsive interactions.")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .lensingEffect()
            
            UIGlassCard(elevation: 2.0) {
                VStack(spacing: 15) {
                    Text("Morphing Glass Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Animated shape morphing (high-end devices only)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .morphingGlass()
        }
    }
    
    private var formControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Form Controls")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            UIGlassCard {
                VStack(spacing: 20) {
                    UIGlassTextField(
                        text: $textFieldValue,
                        placeholder: "Enter your text"
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Slider Value:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(sliderValue * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        UIGlassSlider(
                            value: $sliderValue,
                            in: 0...1
                        )
                    }
                    
                    UIGlassToggle(
                        isOn: $toggleValue,
                        label: "Enable Glass Effects"
                    )
                    
                    UIGlassToggle(
                        isOn: $showLoadingDemo,
                        label: "Show Loading Demo"
                    )
                }
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Loading States")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if showLoadingDemo {
                VStack(spacing: 12) {
                    UIGlassSkeletonLoader(height: 60)
                    UIGlassSkeletonLoader(height: 80)
                    UIGlassSkeletonLoader(height: 100)
                }
            }
            
            UIGlassCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Progress Indicator")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(progressValue * 100))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    UIGlassProgressView(progress: progressValue)
                    
                    HStack(spacing: 12) {
                        Button("Reset") {
                            withAnimation {
                                progressValue = 0
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Simulate") {
                            //simulateProgress()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Special Effects")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                VStack {
                    Text("Blur")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Effect")
                        .padding()
                        .uiGlassBlur()
                        .cornerRadius(12)
                }
                
                Spacer()
                
                VStack {
                    Text("Standard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Glass")
                        .padding()
                        .uiGlass(tintColor: .green)
                }
            }
            
            Text("Tap for lens effect")
                .padding(20)
                .frame(maxWidth: .infinity)
                .uiGlass(tintColor: .orange)
                .lensingEffect()
        }
    }
    
    private var presetStylesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preset Styles")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Text("Card")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .modifier(UIGlassMaterial.card)
                    
                    Text("Button")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .modifier(UIGlassMaterial.button)
                    
                    Text("Subtle")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .modifier(UIGlassMaterial.subtle)
                }
                
                HStack(spacing: 10) {
                    Text("Shimmer")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .modifier(UIGlassMaterial.shimmer)
                    
                    Text("Glow")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .modifier(UIGlassMaterial.glow)
                    
                    Text("Nav")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .modifier(UIGlassMaterial.navigation)
                }
            }
            .padding()
            .uiGlass(intensity: 0.7, tintColor: .purple)
        }
    }
    
    private var performanceSection: some View {
        UIGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.green)
                    Text("Performance Optimizations")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "Device tier detection")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Throttled scroll updates")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Timer cleanup")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Cached animations")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Haptic feedback pooling")
                }
                .font(.caption)
            }
        }
    }
    
    private var accessibilitySection: some View {
        UIGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "accessibility")
                        .foregroundColor(.blue)
                    Text("Accessibility Features")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "VoiceOver support")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Reduce motion detection")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Dynamic Type ready")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Semantic labels")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Dark mode adaptive")
                }
                .font(.caption)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /*
    private func simulateProgress() {
        progressValue = 0
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation {
                progressValue += 0.02
            }
            
            if progressValue >= 1.0 {
                timer.invalidate()
            }
        }
    }
    */
}

// MARK: - Helper Views
@available(iOS 14.0, *)
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
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
