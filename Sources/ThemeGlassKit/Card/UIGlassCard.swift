//
//  UIGlassCard.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Optimized UI Glass Card
@available(iOS 14.0, *)
public struct UIGlassCard<Content: View>: View {
    let content: Content
    let elevation: Double
    
    @State private var glowRadius: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(elevation: Double = 1.0, @ViewBuilder content: () -> Content) {
        self.elevation = elevation
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(20)
            .modifier(
                UIGlassMaterial(
                    intensity: 0.9,
                    tintColor: .white,
                    hasGlow: true
                )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1 * elevation),
                radius: 10 * elevation,
                x: 0,
                y: 5 * elevation
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 0.5)
            )
            .accessibilityElement(children: .contain)
    }
}
