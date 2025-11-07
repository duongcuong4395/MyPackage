//
//  UIGlassNavigationBar.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//
import SwiftUI

struct ScrollOffsetPreferenceKey: @preconcurrency PreferenceKey {
    @MainActor static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Optimized Navigation Bar
@available(iOS 14.0, *)
public struct UIGlassNavigationBar<Content: View>: View {
    let title: String
    let content: Content
    
    @State private var scrollOffset: CGFloat = 0
    @State private var lastUpdateOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Throttle threshold - only update every 10 points
    private let updateThreshold: CGFloat = 10
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .modifier(
                UIGlassMaterial(
                    intensity: min(1.0, abs(scrollOffset) / 100.0),
                    tintColor: .white,
                    isInteractive: false
                )
            )
            .accessibilityAddTraits(.isHeader)
            
            // Content with optimized scroll tracking
            ScrollView {
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .global).minY
                        )
                }
                .frame(height: 0)
                
                content
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // Throttle updates
                if abs(value - lastUpdateOffset) > updateThreshold {
                    scrollOffset = value
                    lastUpdateOffset = value
                }
            }
        }
    }
}
