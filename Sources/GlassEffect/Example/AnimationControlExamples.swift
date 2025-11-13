//
//  AnimationControlExamples.swift
//  MyLibrary
//
//  Created by Macbook on 13/11/25.
//

import SwiftUI


@available(iOS 15.0, *)
public struct AnimationControlExamples: View {
    @State private var animationsEnabled = true
    
    public init() { }
    
    public var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Glass Effect Animation Examples")
                        .font(.title2)
                        .bold()
                        .padding(.top)
                    
                    // Example 1: No Animation
                    VStack(spacing: 8) {
                        Button("No Animation") { }
                            .padding(20)
                            .modifier(GlassEffect(
                                tintColor: .blue,
                                hasShimmer: true,
                                hasGlow: true,
                                enableAnimations: false
                            ))
                        Text("enableAnimations: false")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Example 2: Fast animation
                    VStack(spacing: 8) {
                        Button("Fast Animation (1s)") { }
                            .padding(20)
                            .modifier(GlassEffect(
                                tintColor: .purple,
                                hasShimmer: true,
                                hasGlow: true,
                                shimmerSpeed: 1.0,
                                glowSpeed: 0.8
                            ))
                        Text("shimmerSpeed: 1.0, glowSpeed: 0.8")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Example 3: Normal animation
                    VStack(spacing: 8) {
                        Button("Normal Animation (2s)") { }
                            .padding(20)
                            .modifier(GlassEffect(
                                tintColor: .green,
                                hasShimmer: true,
                                hasGlow: true,
                                shimmerSpeed: 2.0,
                                glowSpeed: 1.5
                            ))
                        Text("shimmerSpeed: 2.0, glowSpeed: 1.5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Example 4: Slow animation
                    VStack(spacing: 8) {
                        Button("Slow Animation (4s)") { }
                            .padding(20)
                            .modifier(GlassEffect(
                                tintColor: .orange,
                                hasShimmer: true,
                                hasGlow: true,
                                shimmerSpeed: 4.0,
                                glowSpeed: 3.5
                            ))
                        Text("shimmerSpeed: 4.0, glowSpeed: 3.5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    Text("Presets")
                        .font(.headline)
                    
                    // Example 5: Preset Subtle
                    VStack(spacing: 8) {
                        Button("Preset: Subtle") { }
                            .padding(20)
                            .modifier(GlassEffect.subtle(tintColor: .cyan))
                        Text("No animations, minimal effect")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Example 6: Preset Animated
                    VStack(spacing: 8) {
                        Button("Preset: Animated") { }
                            .padding(20)
                            .modifier(GlassEffect.animated(tintColor: .pink))
                        Text("Balanced animation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Example 7: Preset Fast
                    VStack(spacing: 8) {
                        Button("Preset: Fast") { }
                            .padding(20)
                            .modifier(GlassEffect.fast(tintColor: .indigo))
                        Text("Quick, snappy animation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Example 8: Preset Slow
                    VStack(spacing: 8) {
                        Button("Preset: Slow") { }
                            .padding(20)
                            .modifier(GlassEffect.slow(tintColor: .mint))
                        Text("Smooth, relaxed animation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    /*
                    // Example 9: Dynamic control
                    VStack(spacing: 12) {
                        Toggle("Enable All Animations", isOn: $animationsEnabled)
                            .padding(.horizontal)
                        
                        Button("Dynamic Control") { }
                            .padding(20)
                            .modifier(GlassEffect(
                                cornerRadius: 20,
                                intensity: 1.5,
                                tintColor: .blue,
                                hasShimmer: true,
                                hasGlow: true,
                                enableAnimations: animationsEnabled,
                                shimmerSpeed: 2.0,
                                glowSpeed: 1.5
                            ))
                        
                        Text(animationsEnabled ? "Animations Enabled ✅" : "Animations Disabled ❌")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 40)
                    */
                }
                .padding()
            }
        }
    }
}
