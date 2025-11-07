//
//  UIGlassDemoApp.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Comprehensive Demo App
@available(iOS 17.0, *)
public struct UIGlassDemoApp: View {
    @State private var selectedTab = 0
    @State private var sliderValue: Double = 0.5
    @State private var toggleValue = false
    @State private var textFieldValue = ""
    @State private var showLoadingDemo = false
    @State private var progressValue: Double = 0
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
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
