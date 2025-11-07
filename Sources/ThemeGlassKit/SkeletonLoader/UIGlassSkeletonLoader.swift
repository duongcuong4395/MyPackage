//
//  UIGlassSkeletonLoader.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Skeleton Loading with Glass Effect
@available(iOS 14.0, *)
public struct UIGlassSkeletonLoader: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(height: CGFloat = 60, cornerRadius: CGFloat = 12) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3),
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: shimmerPhase - 0.3, y: 0.5),
                            endPoint: UnitPoint(x: shimmerPhase, y: 0.5)
                        )
                    )
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1.3
                }
            }
            .accessibilityLabel("Loading")
    }
}
