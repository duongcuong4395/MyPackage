//
//  UIGlassButton.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Optimized UI Glass Button
@available(iOS 14.0, *)
public struct UIGlassButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    @State private var isPressed = false
    @State private var rippleOffset: CGFloat = 0
    @State private var showRipple = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Reusable haptic generator
    private let hapticGenerator: UIImpactFeedbackGenerator
    
    public init(
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.hapticStyle = hapticStyle
        self.action = action
        self.content = content()
        self.hapticGenerator = UIImpactFeedbackGenerator(style: hapticStyle)
    }
    
    public var body: some View {
        Button(action: handleTap) {
            content
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(rippleBackground)
                .modifier(
                    UIGlassMaterial(
                        intensity: isPressed ? 1.2 : 0.8,
                        tintColor: .blue,
                        hasShimmer: true,
                        hasGlow: true
                    )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: handlePress, perform: {})
        .onAppear {
            hapticGenerator.prepare()
        }
        .accessibilityAddTraits(.isButton)
    }
    
    private var rippleBackground: some View {
        Group {
            if showRipple && !reduceMotion {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .scaleEffect(rippleOffset)
                    .opacity(1.0 - rippleOffset * 0.5)
            }
        }
    }
    
    private func handleTap() {
        hapticGenerator.impactOccurred()
        action()
    }
    
    private func handlePress(pressing: Bool) {
        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.1)) {
            isPressed = pressing
        }
        
        if pressing {
            createRipple()
        }
    }
    
    private func createRipple() {
        guard !reduceMotion else { return }
        
        showRipple = true
        rippleOffset = 0
        
        withAnimation(.easeOut(duration: 0.6)) {
            rippleOffset = 2.0
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [showRipple] in
            guard showRipple != nil else { return }
            self.showRipple = false
        }
        
    }
}
