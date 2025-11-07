//
//  UIGlassProgressView.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Progress Indicator with Glass Effect
@available(iOS 14.0, *)
public struct UIGlassProgressView: View {
    let progress: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(progress: Double) {
        self.progress = min(max(progress, 0), 1)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(progress))
                
                Capsule()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}
