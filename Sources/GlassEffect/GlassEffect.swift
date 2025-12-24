//
//  GlassEffect.swift
//  MyLibrary
//
//  Created by Macbook on 13/11/25.
//

import SwiftUI

@available(iOS 15.0, *)
public struct GlassParameters {
    var cornerRadius: Double = 16
    var intensity: Double = 2.3
    var tintColor: Color = .blue
    var isInteractive: Bool = true
    var hasShimmer: Bool = true
    var hasGlow: Bool = true
}

@available(iOS 15.0, *)
public struct GlassGradientSettings {
    var gradientType: GradientType = .linear
    var gradientStartX: Double = 0.0
    var gradientStartY: Double = 0.0
    var gradientEndX: Double = 1.0
    var gradientEndY: Double = 1.0
    var gradientCenterX: Double = 0.5
    var gradientCenterY: Double = 0.5
    var gradientStartRadius: Double = 10
    var gradientEndRadius: Double = 150
    var gradientStartAngle: Double = 0
    var gradientEndAngle: Double = 360
}

@available(iOS 15.0, *)
public struct GlassBorderSettings {
    var borderType: BorderType = .gradient
    var borderColor: Color = .white
    var borderOpacity: Double = 0.5
    var borderWidth: Double = 1.0
}

@available(iOS 15.0, *)
public struct GlassAnimationSettings {
    var enableAnimations: Bool = true
    var shimmerSpeed: Double = 2.0
    var shimmerDelay: Double = 0.0
    var glowSpeed: Double = 1.5
    var glowDelay: Double = 0.0
    var hoverSpeed: Double = 0.2
}

@available(iOS 15.0, *)
public struct GlassSettingModel {
    // Glass parameters
    var glassParameters: GlassParameters
    
    // Gradient settings
    var glassGradientSettings: GlassGradientSettings
    
    // Border settings
    var glassBorderSettings: GlassBorderSettings
    
    // Animation
    var glassAnimationSettings: GlassAnimationSettings
    
    var blurRadius: Double = 0
}

// MARK: - Simplified & Flexible UI Glass Material
@available(iOS 15.0, *)
public struct GlassEffect: ViewModifier {
    let cornerRadius: Double
    let intensity: Double
    let tintColor: Color
    let isInteractive: Bool
    let hasShimmer: Bool
    let hasGlow: Bool
    
    // Gradient configuration
    let gradientType: GradientType
    let gradientStart: UnitPoint
    let gradientEnd: UnitPoint
    let gradientCenterX: Double
    let gradientCenterY: Double
    let gradientStartRadius: CGFloat
    let gradientEndRadius: CGFloat
    let gradientStartAngle: Double
    let gradientEndAngle: Double
    
    // Border configuration
    let borderType: BorderType
    let borderColor: Color
    let borderOpacity: Double
    let borderWidth: Double
    
    let blurRadius: CGFloat
    
    // Animation Controls
    let enableAnimations: Bool
    let shimmerSpeed: Double
    let shimmerDelay: Double
    let glowSpeed: Double
    let glowDelay: Double
    let hoverAnimationSpeed: Double
    
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
        hasGlow: Bool = false,
        
        gradientType: GradientType = .linear,
        gradientStart: UnitPoint = .topLeading,
        gradientEnd: UnitPoint = .bottomTrailing,
        gradientCenterX: Double = 0.5,
        gradientCenterY: Double = 0.5,
        gradientStartRadius: CGFloat = 10,
        gradientEndRadius: CGFloat = 150,
        gradientStartAngle: Double = 0,
        gradientEndAngle: Double = 360,
        
        borderType: BorderType = .gradient,
        borderColor: Color = .white,
        borderOpacity: Double = 0.5,
        borderWidth: Double = 1.0,
        
        blurRadius: CGFloat = 0,
        
        enableAnimations: Bool = true,
        shimmerSpeed: Double = 2.0,
        shimmerDelay: Double = 0.0,
        glowSpeed: Double = 1.5,
        glowDelay: Double = 0.0,
        hoverAnimationSpeed: Double = 0.2
    ) {
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.tintColor = tintColor
        self.isInteractive = isInteractive
        self.hasShimmer = hasShimmer
        self.hasGlow = hasGlow
        
        self.gradientType = gradientType
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.gradientCenterX = gradientCenterX
        self.gradientCenterY = gradientCenterY
        self.gradientStartRadius = gradientStartRadius
        self.gradientEndRadius = gradientEndRadius
        self.gradientStartAngle = gradientStartAngle
        self.gradientEndAngle = gradientEndAngle
        
        self.borderType = borderType
        self.borderColor = borderColor
        self.borderOpacity = borderOpacity
        self.borderWidth = borderWidth
        
        self.blurRadius = blurRadius
        
        self.enableAnimations = enableAnimations
        self.shimmerSpeed = shimmerSpeed
        self.shimmerDelay = shimmerDelay
        self.glowSpeed = glowSpeed
        self.glowDelay = glowDelay
        self.hoverAnimationSpeed = hoverAnimationSpeed
    }
    
    public func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .scaleEffect(hoverScale)
            .animation(animationForScale, value: hoverScale)
            .onAppear(perform: startAnimations)
    }
    
    private var shouldAnimate: Bool {
        enableAnimations && !reduceMotion
    }
    
    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(createBaseGradient())
                .blur(radius: blurRadius)
            
            if hasShimmer && shouldAnimate {
                shimmerOverlay
            }
            
            if borderType != .none {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(createBorder(), lineWidth: borderWidth)
            }
        }
    }
    
    private func createBaseGradient() -> AnyShapeStyle {
        let baseOpacity = colorScheme == .dark ? 0.25 : 0.15
        let secondaryOpacity = colorScheme == .dark ? 0.15 : 0.05
        
        let adjustedBase = baseOpacity * intensity
        let adjustedSecondary = secondaryOpacity * intensity
        
        let color1 = tintColor.opacity(adjustedBase + (hasGlow ? glowIntensity * 0.1 : 0))
        let color2 = tintColor.opacity(adjustedSecondary + (hasGlow ? glowIntensity * 0.05 : 0))
        
        switch gradientType {
        case .linear:
            return AnyShapeStyle(LinearGradient(
                colors: [color1, color2],
                startPoint: gradientStart,
                endPoint: gradientEnd
            ))
        case .radial:
            return AnyShapeStyle(RadialGradient(
                colors: [color1, color2],
                center: UnitPoint(x: gradientCenterX, y: gradientCenterY),
                startRadius: gradientStartRadius,
                endRadius: gradientEndRadius
            ))
        case .angular:
            return AnyShapeStyle(AngularGradient(
                colors: [color1, color2, color1],
                center: UnitPoint(x: gradientCenterX, y: gradientCenterY),
                startAngle: .degrees(gradientStartAngle),
                endAngle: .degrees(gradientEndAngle)
            ))
        case .solid:
            return AnyShapeStyle(color1)
        }
    }
    
    private func createBorder() -> AnyShapeStyle {
        let adjustedOpacity = (colorScheme == .dark ? 0.4 : 0.6) * borderOpacity
        
        switch borderType {
        case .solid:
            return AnyShapeStyle(borderColor.opacity(adjustedOpacity))
        case .gradient:
            let color1 = borderColor.opacity(adjustedOpacity)
            let color2 = borderColor.opacity(0.1)
            let color3 = Color.clear
            
            switch gradientType {
            case .linear:
                return AnyShapeStyle(LinearGradient(
                    colors: [color1, color2, color3],
                    startPoint: gradientStart,
                    endPoint: gradientEnd
                ))
            case .radial:
                return AnyShapeStyle(RadialGradient(
                    colors: [color1, color2, color3],
                    center: UnitPoint(x: gradientCenterX, y: gradientCenterY),
                    startRadius: gradientStartRadius,
                    endRadius: gradientEndRadius
                ))
            case .angular:
                return AnyShapeStyle(AngularGradient(
                    colors: [color1, color2, color3, color1],
                    center: UnitPoint(x: gradientCenterX, y: gradientCenterY),
                    startAngle: .degrees(gradientStartAngle),
                    endAngle: .degrees(gradientEndAngle)
                ))
            case .solid:
                return AnyShapeStyle(color1)
            }
        case .none:
            return AnyShapeStyle(Color.clear)
        }
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
    }
    
    private var shimmerAnimation: Animation? {
        guard shouldAnimate else { return .none }
        return .easeInOut(duration: shimmerSpeed)
            .delay(shimmerDelay)
            .repeatForever(autoreverses: true)
    }
    
    private var glowAnimation: Animation? {
        guard shouldAnimate else { return .none }
        return .easeInOut(duration: glowSpeed)
            .delay(glowDelay)
            .repeatForever(autoreverses: true)
    }
    
    private var animationForScale: Animation? {
        guard shouldAnimate && isInteractive else { return .none }
        return .easeInOut(duration: hoverAnimationSpeed)
    }
    
    private func startAnimations() {
        guard shouldAnimate else { return }
        
        if hasShimmer {
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
    
    // animations with new parameters
    private func restartAnimations() {
        // Reset states
        shimmerOffset = -1.0
        glowIntensity = 0.0
        
        // Restart with new parameters
        guard shouldAnimate else { return }
        
        if hasShimmer {
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

// MARK: - Animation Presets
@available(iOS 15.0, *)
public extension GlassEffect {
    static func subtle(
        cornerRadius: Double = 16,
        tintColor: Color = .blue
    ) -> GlassEffect {
        GlassEffect(
            cornerRadius: cornerRadius,
            intensity: 0.5,
            tintColor: tintColor,
            hasShimmer: false,
            hasGlow: false,
            enableAnimations: false
        )
    }
    
    static func animated(
        cornerRadius: Double = 16,
        tintColor: Color = .blue
    ) -> GlassEffect {
        GlassEffect(
            cornerRadius: cornerRadius,
            intensity: 1.0,
            tintColor: tintColor,
            hasShimmer: true,
            hasGlow: true,
            shimmerSpeed: 2.0,
            glowSpeed: 1.5
        )
    }
    
    static func fast(
        cornerRadius: Double = 16,
        tintColor: Color = .blue
    ) -> GlassEffect {
        GlassEffect(
            cornerRadius: cornerRadius,
            intensity: 0.8,
            tintColor: tintColor,
            hasShimmer: true,
            hasGlow: true,
            shimmerSpeed: 1.0,
            glowSpeed: 0.8
        )
    }
    
    static func slow(
        cornerRadius: Double = 16,
        tintColor: Color = .blue
    ) -> GlassEffect {
        GlassEffect(
            cornerRadius: cornerRadius,
            intensity: 0.8,
            tintColor: tintColor,
            hasShimmer: true,
            hasGlow: true,
            shimmerSpeed: 4.0,
            glowSpeed: 3.0
        )
    }
}

@available(iOS 15.0, *)
// MARK: - Simple Enums
public enum GradientType: String, CaseIterable {
    case linear = "Linear"
    case radial = "Radial"
    case angular = "Angular"
    case solid = "Solid"
}

public enum BorderType: String, CaseIterable {
    case solid = "Solid"
    case gradient = "Gradient"
    case none = "None"
}

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
