# MarkdownTypingKit

<p align="center">
  <strong>A beautiful, performant SwiftUI package for rendering Markdown with an elegant typewriter effect</strong>
</p>

<p align="center">
  Perfect for chat interfaces, documentation viewers, and interactive content displays
</p>

---

## ✨ Features

- 🎨 **Complete Markdown Support** - Headers, lists, code blocks, tables, blockquotes, and inline formatting
- ⚡ **Typewriter Effect** - Smooth character-by-character animation with adjustable speeds
- 🎯 **Auto-Scroll** - Intelligent scrolling that follows the content as it appears
- 🎨 **Customizable Themes** - Pre-built themes and full customization support
- 🚀 **Performance Optimized** - Lazy rendering and intelligent caching
- 📱 **SwiftUI Native** - Built with modern SwiftUI practices
- 🔧 **Easy to Use** - Simple API with sensible defaults

## 📦 Installation

### Swift Package Manager

Add MarkdownTypingKit to your project:

```swift
dependencies: [
    .package(url: "https://github.com/duongcuong4395/MarkdownTypingKit.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Packages
2. Enter: `https://github.com/duongcuong4395/MarkdownTypingKit.git`
3. Select version and add to your target

## 🚀 Quick Start

```swift
import SwiftUI
import MarkdownTypingKit

struct ContentView: View {
    @State private var markdown = """
    # Welcome to MarkdownTypingKit
    
    Experience the **magic** of *animated* markdown rendering!
    """
    
    var body: some View {
        MarkdownTypewriterView(text: $markdown)
            .padding()
    }
}
```

That's it! 🎉

## 📚 Usage Examples

### Basic Implementation

```swift
import MarkdownTypingKit

struct ChatView: View {
    @State private var response = ""
    
    var body: some View {
        MarkdownTypewriterView(text: $response)
            .padding()
    }
}
```

### Custom Speed

```swift
@State private var speed: TypingSpeed = .fast

MarkdownTypewriterView(
    text: $markdown,
    configuration: MarkdownConfiguration(
        typingSpeed: speed,
        enableAutoScroll: true
    )
)
```

Available speeds:
- `.veryFast` - 0.005s per character (~200 chars/s)
- `.fast` - 0.01s per character (~100 chars/s)
- `.normal` - 0.05s per character (~20 chars/s)
- `.slow` - 0.1s per character (~10 chars/s)
- `.verySlow` - 0.2s per character (~5 chars/s)

### Custom Theme

```swift
let customTheme = MarkdownTheme(
    h1FontSize: 28,
    h2FontSize: 24,
    bodyFontSize: 16,
    lineSpacing: 4,
    primaryColor: .primary,
    secondaryColor: .gray,
    codeBackgroundColor: Color.blue.opacity(0.1),
    linkColor: .purple
)

MarkdownTypewriterView(
    text: $markdown,
    configuration: MarkdownConfiguration(theme: customTheme)
)
```

### Streaming Content (ChatGPT-like)

```swift
struct AIAssistantView: View {
    @State private var aiResponse = ""
    
    var body: some View {
        VStack {
            MarkdownTypewriterView(text: $aiResponse)
                .padding()
            
            Button("Ask AI") {
                streamAIResponse()
            }
        }
    }
    
    func streamAIResponse() {
        let fullResponse = """
        # AI Response
        
        Here's a **detailed** explanation with:
        - Point 1
        - Point 2
        - Point 3
        
        ```swift
        let example = "code"
        ```
        """
        
        aiResponse = ""
        
        // Simulate streaming
        for (index, char) in fullResponse.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                aiResponse.append(char)
            }
        }
    }
}
```

### Using Modifiers (Alternative Syntax)

```swift
MarkdownTypewriterView(text: $markdown)
    .typingSpeed(.slow)
    .autoScroll(true)
    .markdownTheme(.large)
    .padding()
```

## 🎨 Supported Markdown Syntax

### Text Formatting

```markdown
**Bold text**
*Italic text*
~~Strikethrough~~
`Inline code`
[Link text](https://example.com)
```

### Headers

```markdown
# H1 Header
## H2 Header
### H3 Header
#### H4 Header
```

### Lists

```markdown
- Unordered list item
- Another item
  
1. Ordered list item
2. Second item
```

### Code Blocks

````markdown
```swift
let greeting = "Hello, World!"
print(greeting)
```
````

### Blockquotes

```markdown
> This is a quote
> It can span multiple lines
```

### Tables

```markdown
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
```

### Horizontal Rules

```markdown
---
```

## 🏗️ Architecture

MarkdownTypingKit uses a clean, modular architecture:

```
┌─────────────────────────────────────┐
│   MarkdownTypewriterView (Public)  │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┬──────────────────┐
    │                     │                  │
┌───▼──────┐    ┌────────▼────────┐  ┌─────▼────────┐
│  Parser  │    │ TypewriterEngine│  │   Renderer   │
└──────────┘    └─────────────────┘  └──────────────┘
    │                     │                  │
┌───▼──────┐    ┌────────▼────────┐  ┌─────▼────────┐
│ Strategy │    │   Caching       │  │   Themes     │
│ Pattern  │    │   System        │  │   System     │
└──────────┘    └─────────────────┘  └──────────────┘
```

### Components

- **MarkdownParser** - Strategy-based parser for block-level elements
- **InlineMarkdownParser** - Handles inline formatting (bold, italic, links)
- **TypewriterEngine** - Manages animation with performance optimization
- **SectionRenderer** - Converts parsed sections to SwiftUI views
- **Configuration System** - Centralized theme and behavior management

## ⚡ Performance

MarkdownTypingKit is built for performance:

- **Lazy Rendering** - Only renders visible content
- **Intelligent Caching** - Parsed sections are cached automatically
- **Optimized Scrolling** - Smart throttling prevents unnecessary updates
- **Memory Efficient** - Minimal memory footprint even with large documents

### Benchmarks

| Document Size | Parse Time | Memory Usage |
|--------------|------------|--------------|
| Small (1KB)  | <1ms       | ~2MB         |
| Medium (10KB)| ~5ms       | ~5MB         |
| Large (100KB)| ~30ms      | ~15MB        |

## 🎯 Use Cases

### AI Chat Applications
Perfect for ChatGPT-like interfaces with streaming responses

### Documentation Viewers
Display markdown documentation with engaging animations

### Tutorial Systems
Create interactive learning experiences

### Content Readers
Build engaging content reading applications

### Note-Taking Apps
Display formatted notes with style

## 🔧 Advanced Configuration

### All Configuration Options

```swift
let config = MarkdownConfiguration(
    typingSpeed: .fast,              // Animation speed
    showIndicators: false,            // Show scroll indicators
    enableAutoScroll: true,           // Auto-scroll to bottom
    theme: MarkdownTheme(
        // Font sizes
        h1FontSize: 20,
        h2FontSize: 18,
        h3FontSize: 16,
        h4FontSize: 15,
        bodyFontSize: 14,
        codeFontSize: 13,
        
        // Spacing
        lineSpacing: 2,
        sectionSpacing: 8,
        horizontalPadding: 0,
        
        // Colors
        primaryColor: .primary,
        secondaryColor: .secondary,
        codeBackgroundColor: Color.secondary.opacity(0.05),
        linkColor: .blue
    )
)

MarkdownTypewriterView(text: $markdown, configuration: config)
```

### Pre-built Themes

```swift
// Default theme
.markdownTheme(.default)

// Large theme (bigger fonts and spacing)
.markdownTheme(.large)

// Custom theme
.markdownTheme(myCustomTheme)
```

## 📖 API Reference

### MarkdownTypewriterView

```swift
public struct MarkdownTypewriterView: View {
    public init(
        text: Binding<String>,
        configuration: MarkdownConfiguration = MarkdownConfiguration()
    )
    
    public init(
        staticText: String,
        configuration: MarkdownConfiguration = MarkdownConfiguration()
    )
}
```

### Extension Methods

```swift
func typingSpeed(_ speed: TypingSpeed) -> MarkdownTypewriterView
func markdownTheme(_ theme: MarkdownTheme) -> MarkdownTypewriterView
func autoScroll(_ enabled: Bool) -> MarkdownTypewriterView
```

### MarkdownConfiguration

```swift
public struct MarkdownConfiguration {
    public var typingSpeed: TypingSpeed
    public var showIndicators: Bool
    public var enableAutoScroll: Bool
    public var theme: MarkdownTheme
}
```
