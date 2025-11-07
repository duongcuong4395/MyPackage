# ThemeGlassKit

A modern, performance-optimized SwiftUI design system featuring glassmorphism effects with comprehensive accessibility support. Inspired by Apple's Liquid Glass, reimagined with developer control and cross-version compatibility.

## ✨ Features

### 🎨 Complete Component Library
- **UIGlassButton** - Interactive buttons with ripple effects and haptic feedback
- **UIGlassCard** - Elevated cards with customizable shadows
- **UIGlassTextField** - Animated text inputs with focus states
- **UIGlassSlider** - Gradient sliders with smooth dragging
- **UIGlassToggle** - Custom toggle switches
- **UIGlassTabBar** - Animated tab navigation
- **UIGlassNavigationBar** - Scroll-reactive navigation bars
- **UIGlassProgressView** - Gradient progress indicators
- **UIGlassSkeletonLoader** - Shimmer loading states
- **ParticleGlass** - Animated particle system

### ⚡️ Performance Optimized
- **Device Tier Detection** - Adaptive rendering based on hardware capability
- **Throttled Updates** - Efficient scroll and animation tracking
- **Memory Management** - Proper timer cleanup and weak references
- **Cached Animations** - Reusable animation configurations
- **Conditional Rendering** - Smart feature degradation on low-end devices

### ♿️ Accessibility First
- **Reduce Motion Support** - Respects system accessibility settings
- **VoiceOver Ready** - Semantic labels and traits
- **Dynamic Type** - Scales with user font preferences
- **Dark Mode Adaptive** - Intelligent opacity adjustments
- **Haptic Feedback** - Optional tactile responses

### 🎯 Advanced Effects
- **Shimmer** - Animated light reflections
- **Glow** - Pulsing luminescence
- **Morphing Shapes** - Fluid animated contours
- **Lensing Effect** - Interactive focal points
- **Particle System** - Floating ambient particles
- **Blur Layers** - Native and custom blur implementations

## 📦 Installation

### Swift Package Manager

Add ThemeGlassKit to your project via Xcode:

1. File → Add Package Dependencies
2. Enter repository URL: `https://github.com/duongcuong4395/ThemeGlassKit.git`
3. Select version/branch
4. Add to your target

Or add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/duongcuong4395/ThemeGlassKit.git", from: "1.0.0")
]
```

## 🚀 Quick Start

### Basic Glass Effect

```swift
import SwiftUI
import ThemeGlassKit

struct ContentView: View {
    var body: some View {
        Text("Hello, Glass!")
            .padding()
            .uiGlass(
                cornerRadius: 16,
                intensity: 0.8,
                tintColor: .blue,
                hasShimmer: true,
                hasGlow: false
            )
    }
}
```

### Glass Card

```swift
UIGlassCard(elevation: 2.0) {
    VStack(alignment: .leading, spacing: 12) {
        Text("Card Title")
            .font(.headline)
        
        Text("Card content with automatic glass styling")
            .font(.body)
            .foregroundColor(.secondary)
    }
}
```

### Glass Button

```swift
UIGlassButton(action: {
    print("Button tapped!")
}) {
    HStack {
        Image(systemName: "star.fill")
        Text("Action Button")
    }
}
```

### Preset Styles

```swift
// Use predefined configurations
Text("Card Style")
    .padding()
    .modifier(UIGlassMaterial.card)

Text("Button Style")
    .padding()
    .modifier(UIGlassMaterial.button)

Text("Shimmer Style")
    .padding()
    .modifier(UIGlassMaterial.shimmer)
```

## 📱 Components Guide

### UIGlassButton

Interactive button with haptic feedback and ripple animation.

```swift
UIGlassButton(
    hapticStyle: .medium,
    action: { /* action */ }
) {
    Text("Tap Me")
}
```

**Features:**
- Automatic haptic feedback
- Press/release animations
- Ripple effect (respects reduce motion)
- Accessibility traits

### UIGlassCard

Container with glass material and elevation.

```swift
UIGlassCard(elevation: 1.5) {
    // Your content
}
```

**Parameters:**
- `elevation: Double` - Shadow intensity (0.0-3.0)
- Automatic dark mode adaptation
- Glow effect on iOS 14+

### UIGlassTextField

Animated text input with focus indicators.

```swift
@State private var text = ""

UIGlassTextField(
    text: $text,
    placeholder: "Enter text"
)
```

**Features:**
- Floating label animation
- Focus border highlight
- VoiceOver support
- Dark mode adaptive

### UIGlassSlider

Custom slider with gradient track.

```swift
@State private var value: Double = 0.5

UIGlassSlider(
    value: $value,
    in: 0...1
)
```

**Features:**
- Gradient fill
- Drag interaction
- Haptic feedback
- Accessibility adjustable

### UIGlassToggle

Custom toggle switch with smooth animation.

```swift
@State private var isOn = false

UIGlassToggle(
    isOn: $isOn,
    label: "Enable Feature"
)
```

### UIGlassTabBar

Animated tab bar navigation.

```swift
@State private var selectedTab = 0

UIGlassTabBar(
    selection: $selectedTab,
    items: [
        TabItem2(title: "Home", icon: "house.fill"),
        TabItem2(title: "Search", icon: "magnifyingglass"),
        TabItem2(title: "Profile", icon: "person.fill")
    ]
)
```

**Features:**
- Animated indicator
- Icon + label
- Haptic feedback
- Accessibility navigation

### UIGlassNavigationBar

Scroll-reactive navigation bar.

```swift
UIGlassNavigationBar(title: "My App") {
    ScrollView {
        // Your content
    }
}
```

**Features:**
- Blur intensity adjusts with scroll
- Throttled updates for performance
- Automatic header accessibility trait

### UIGlassProgressView

Progress indicator with gradient.

```swift
UIGlassProgressView(progress: 0.75)
```

### UIGlassSkeletonLoader

Shimmer loading placeholder.

```swift
UIGlassSkeletonLoader(
    height: 60,
    cornerRadius: 12
)
```

### ParticleGlass

Ambient particle animation.

```swift
ZStack {
    ParticleGlass()
        .ignoresSafeArea()
    
    // Your content
}
```

**Performance:**
- High tier: 20 particles
- Medium tier: 10 particles
- Low tier: 5 particles
- Disabled on reduce motion

## 🎨 Customization

### Glass Material Parameters

```swift
.uiGlass(
    cornerRadius: 16,      // Border radius
    intensity: 0.8,        // Glass opacity (0.0-1.0)
    tintColor: .blue,      // Base tint color
    isInteractive: true,   // Enable hover effects
    hasShimmer: true,      // Animated light reflection
    hasGlow: false         // Pulsing glow effect
)
```

### Preset Styles

```swift
// Predefined configurations
UIGlassMaterial.card        // Standard card
UIGlassMaterial.button      // Interactive button
UIGlassMaterial.navigation  // Nav bar
UIGlassMaterial.subtle      // Minimal glass
UIGlassMaterial.shimmer     // With shimmer
UIGlassMaterial.glow        // With glow
```

### Advanced Effects

```swift
// Blur effect
.uiGlassBlur(radius: 10, opaque: false)

// Lensing effect (iOS 17+)
.lensingEffect()

// Morphing glass (iOS 14+)
.morphingGlass()
```

## ⚙️ Performance Optimization

ThemeGlassKit automatically optimizes rendering based on device capability:

### Device Tiers
- **High** (6+ cores): Full effects, 20 particles, morphing animations
- **Medium** (4-5 cores): Reduced particles (10), simplified animations
- **Low** (<4 cores): Minimal effects (5 particles), static rendering

### Accessibility
- **Reduce Motion**: Disables animations, uses instant transitions
- **VoiceOver**: Proper labels, traits, and navigation
- **Dynamic Type**: Text scales with system settings

### Memory Management
- Automatic timer cleanup on view disappear
- Weak self references in closures
- Haptic generator pooling

## 🎯 Best Practices

### 1. Use Preset Styles
```swift
// ✅ Good - Consistent design
Text("Content").modifier(UIGlassMaterial.card)

// ❌ Avoid - Manual tuning unless needed
Text("Content").uiGlass(intensity: 0.891, tintColor: .init(red: 0.234, ...))
```

### 2. Respect Reduce Motion
```swift
// ✅ Framework handles this automatically
UIGlassButton { ... }

// ❌ Don't force animations
.animation(.spring, value: someState) // Will be disabled if reduce motion is on
```

### 3. Combine Components
```swift
// ✅ Good - Use high-level components
UIGlassCard {
    VStack {
        UIGlassTextField(...)
        UIGlassButton(...)
    }
}

// ❌ Avoid - Nested glass materials
.uiGlass()
    .uiGlass() // Creates visual artifacts
```

### 4. Test on Real Devices
- ThemeGlassKit adapts to device capability
- Simulator always reports high-tier
- Test on iPhone SE/older devices for low-tier behavior

## 🧪 Example App

See `UIGlassDemoApp.swift` for comprehensive usage examples including:
- All component variations
- Form layouts
- Navigation patterns
- Loading states
- Accessibility features
- Performance comparisons

Run the demo:
```swift
import SwiftUI
import ThemeGlassKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            UIGlassDemoApp()
        }
    }
}
```

## 🔧 Requirements

- iOS 14.0+
- Swift 5.9+
- Xcode 15.0+

**Optional Features:**
- iOS 17.0+ for `UIGlassTextField`, `UIGlassTabBar`, `LensingEffect`
- iOS 15.0+ for native `.ultraThinMaterial` blur
- iOS 14.0+ for most components

### Development Setup
```bash
git clone https://github.com/duongcuong4395/ThemeGlassKit.git
cd ThemeGlassKit
open Package.swift
```

## 🙏 Acknowledgments

Inspired by:
- Apple's Liquid Glass design language
- Glassmorphism design trend
- SwiftUI community best practices
