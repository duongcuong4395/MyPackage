# 🪟 GlassEffect

A powerful and flexible SwiftUI package for creating stunning glass morphism effects with advanced customization and built-in animations.

## ✨ Features

- 🎨 **Fully Customizable** - 20+ parameters to fine-tune your glass effect
- 🌈 **Multiple Gradient Types** - Linear, Radial, Angular, and Solid
- ✨ **Built-in Animations** - Shimmer and glow effects with customizable speeds
- 🎭 **Border Options** - Solid, gradient, or no border
- 🎯 **Performance Optimized** - Respects system reduce motion preferences
- 🎮 **Interactive Playground** - Visual editor to preview and generate code
- 📦 **Ready-to-use Presets** - Quick start with subtle, animated, fast, and slow variants

## 📱 Preview

```swift
Button("Glass Button") { }
    .padding(20)
    .modifier(GlassEffect(
        tintColor: .blue,
        hasShimmer: true,
        hasGlow: true
    ))
```

## 🚀 Installation

### Swift Package Manager

Add this package to your Xcode project:

1. File → Add Package Dependencies
2. Enter package URL: `YOUR_REPOSITORY_URL`
3. Select version and add to target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "[https://github.com/duongcuong4395/MyPackage](https://github.com/duongcuong4395/MyPackage)", from: "1.0.0")
]
```

## 📖 Usage

### Basic Usage

```swift
import GlassEffect

struct ContentView: View {
    var body: some View {
        Text("Hello, Glass!")
            .padding()
            .modifier(GlassEffect())
    }
}
```

### Using Presets

```swift
// Subtle effect - no animations
Button("Subtle") { }
    .padding()
    .modifier(GlassEffect.subtle(tintColor: .blue))

// Animated - balanced effect
Button("Animated") { }
    .padding()
    .modifier(GlassEffect.animated(tintColor: .purple))

// Fast animations
Button("Fast") { }
    .padding()
    .modifier(GlassEffect.fast(tintColor: .green))

// Slow, relaxed animations
Button("Slow") { }
    .padding()
    .modifier(GlassEffect.slow(tintColor: .orange))
```

### Custom Configuration

```swift
Button("Custom Glass") { }
    .padding(30)
    .modifier(GlassEffect(
        cornerRadius: 20,
        intensity: 1.5,
        tintColor: .cyan,
        isInteractive: true,
        hasShimmer: true,
        hasGlow: true,
        gradientType: .radial,
        gradientCenterX: 0.5,
        gradientCenterY: 0.5,
        gradientStartRadius: 20,
        gradientEndRadius: 200,
        borderType: .gradient,
        borderColor: .white,
        borderOpacity: 0.6,
        borderWidth: 2.0,
        blurRadius: 5,
        shimmerSpeed: 2.5,
        glowSpeed: 2.0
    ))
```

## 🎮 Interactive Playground

Use `GlassPlaygroundView` to experiment with all parameters in real-time:

```swift
import SwiftUI
import GlassEffect

struct ContentView: View {
    var body: some View {
        GlassPlaygroundView()
    }
}
```

Features:
- Live preview with customizable background
- Real-time parameter adjustment
- Code generation
- Copy-to-clipboard functionality

## ⚙️ Parameters

### Basic Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cornerRadius` | `Double` | `16` | Corner radius of the glass effect |
| `intensity` | `Double` | `0.8` | Overall intensity of the effect (0-10) |
| `tintColor` | `Color` | `.white` | Base tint color for the glass |
| `isInteractive` | `Bool` | `true` | Enable hover/press animations |
| `blurRadius` | `CGFloat` | `0` | Additional blur radius |

### Gradient Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `gradientType` | `GradientType` | `.linear` | Type: linear, radial, angular, solid |
| `gradientStart` | `UnitPoint` | `.topLeading` | Linear gradient start point |
| `gradientEnd` | `UnitPoint` | `.bottomTrailing` | Linear gradient end point |
| `gradientCenterX` | `Double` | `0.5` | Radial/Angular center X (0-1) |
| `gradientCenterY` | `Double` | `0.5` | Radial/Angular center Y (0-1) |
| `gradientStartRadius` | `CGFloat` | `10` | Radial gradient start radius |
| `gradientEndRadius` | `CGFloat` | `150` | Radial gradient end radius |
| `gradientStartAngle` | `Double` | `0` | Angular gradient start angle |
| `gradientEndAngle` | `Double` | `360` | Angular gradient end angle |

### Border Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `borderType` | `BorderType` | `.gradient` | Border type: solid, gradient, none |
| `borderColor` | `Color` | `.white` | Border color |
| `borderOpacity` | `Double` | `0.5` | Border opacity (0-1) |
| `borderWidth` | `Double` | `1.0` | Border width |

### Animation Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hasShimmer` | `Bool` | `false` | Enable shimmer effect |
| `hasGlow` | `Bool` | `false` | Enable glow effect |
| `enableAnimations` | `Bool` | `true` | Master toggle for all animations |
| `shimmerSpeed` | `Double` | `2.0` | Shimmer animation duration |
| `shimmerDelay` | `Double` | `0.0` | Shimmer start delay |
| `glowSpeed` | `Double` | `1.5` | Glow animation duration |
| `glowDelay` | `Double` | `0.0` | Glow start delay |
| `hoverAnimationSpeed` | `Double` | `0.2` | Hover/press animation speed |

## 🎨 Gradient Types

```swift
// Linear Gradient
.modifier(GlassEffect(gradientType: .linear))

// Radial Gradient
.modifier(GlassEffect(
    gradientType: .radial,
    gradientCenterX: 0.5,
    gradientCenterY: 0.5
))

// Angular Gradient
.modifier(GlassEffect(
    gradientType: .angular,
    gradientStartAngle: 0,
    gradientEndAngle: 360
))

// Solid Color
.modifier(GlassEffect(gradientType: .solid))
```

## 🎭 Border Types

```swift
// Gradient Border (default)
.modifier(GlassEffect(borderType: .gradient))

// Solid Border
.modifier(GlassEffect(borderType: .solid))

// No Border
.modifier(GlassEffect(borderType: .none))
```

## 📋 Examples

### Card with Glass Effect

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Glass Card")
        .font(.headline)
    Text("Beautiful glassmorphism effect")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
.padding()
.modifier(GlassEffect(
    cornerRadius: 20,
    intensity: 1.2,
    tintColor: .blue,
    hasShimmer: true
))
```

### Navigation Bar Style

```swift
HStack {
    Button(action: {}) {
        Image(systemName: "chevron.left")
    }
    Spacer()
    Text("Title")
    Spacer()
    Button(action: {}) {
        Image(systemName: "ellipsis")
    }
}
.padding()
.modifier(GlassEffect(
    intensity: 0.6,
    tintColor: .white,
    borderType: .solid,
    borderOpacity: 0.3
))
```

### Floating Action Button

```swift
Button(action: {}) {
    Image(systemName: "plus")
        .font(.title2)
        .foregroundColor(.white)
}
.padding()
.modifier(GlassEffect(
    cornerRadius: 30,
    intensity: 2.0,
    tintColor: .purple,
    hasGlow: true,
    glowSpeed: 2.0
))
```

## ♿️ Accessibility

GlassEffect automatically respects system preferences:
- **Reduce Motion**: Disables animations when enabled
- **Color Scheme**: Adjusts opacity for light/dark modes
- **Performance**: Monitors device capabilities for optimal rendering

## 🔧 Advanced Features

### Performance Monitoring

The package includes a built-in `PerformanceMonitor` that:
- Detects device tier (high/medium/low)
- Monitors reduce motion settings
- Optimizes animation complexity based on device

### Dynamic Animation Control

```swift
@State private var enableAnimations = true

Button("Toggle Glass") { }
    .modifier(GlassEffect(
        hasShimmer: true,
        hasGlow: true,
        enableAnimations: enableAnimations
    ))
```

## 📱 Example App

Check out `AnimationControlExamples.swift` for a complete demo showcasing:
- Animation speed variations
- All available presets
- Dynamic animation toggling
- Best practices

## 🎯 Requirements

- iOS 15.0+
- Swift 5.5+
- SwiftUI 3.0+

## 🙏 Acknowledgments

- Inspired by modern glassmorphism design trends
- Built with SwiftUI and love ❤️

---

Made with ❤️ using SwiftUI
