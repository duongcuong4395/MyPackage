import SwiftUI
//import MarkdownTypewriter
/*
@available(iOS 17.0, *)
struct MarkdownTypewriterDemoApp: View {
    var body: some View {
        MarkdownTypewriterDemoView()
    }
}

@available(iOS 17.0, *)
struct MarkdownTypewriterDemoView: View {
    var body: some View {
        TabView {
            BasicDemoView()
                .tabItem {
                    Label("Basic", systemImage: "text.alignleft")
                }
            
            StreamingDemoView()
                .tabItem {
                    Label("Streaming", systemImage: "wave.3.right")
                }
            
            CustomThemeView()
                .tabItem {
                    Label("Themes", systemImage: "paintbrush")
                }
            
            PlaygroundView()
                .tabItem {
                    Label("Playground", systemImage: "play.circle")
                }
        }
    }
}

// MARK: - Basic Demo

@available(iOS 17.0, *)
struct BasicDemoView: View {
    @State private var markdown = """
    # MarkdownTypewriter Demo
    
    Welcome to the **MarkdownTypewriter** package demonstration!
    
    ## Features
    
    This package supports:
    - **Bold** and *italic* text
    - `Inline code` formatting
    - [Links](https://github.com)
    - ~~Strikethrough~~ text
    
    ### Code Blocks
    
    ```swift
    struct ContentView: View {
        var body: some View {
            Text("Hello, World!")
        }
    }
    ```
    
    ### Lists
    
    1. First ordered item
    2. Second ordered item
    3. Third ordered item
    
    ### Quotes
    
    > This is a blockquote.
    > It can span multiple lines.
    
    ### Tables
    
    | Feature | Status |
    |---------|--------|
    | Headers | ✅ |
    | Lists | ✅ |
    | Code | ✅ |
    
    ---
    
    ## Performance
    
    The package is optimized for:
    - **Lazy rendering** for large documents
    - **Cached parsing** to avoid redundant work
    - **Smooth animations** with adjustable speeds
    
    Try changing the speed or theme below!
    """
    
    @State private var selectedSpeed: TypingSpeed = .fast
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Speed", selection: $selectedSpeed) {
                    ForEach(TypingSpeed.allCases, id: \.self) { speed in
                        Text(speed.description).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                MarkdownTypewriterView(text: $markdown)
                    .typingSpeed(selectedSpeed)
                    .padding()
            }
            .navigationTitle("Basic Demo")
        }
    }
}

// MARK: - Streaming Demo (ChatGPT-like)
@available(iOS 17.0, *)
struct StreamingDemoView: View {
    @State private var streamedText = ""
    @State private var isStreaming = false
    
    let sampleResponses = [
        """
        # AI Assistant Response
        
        Hello! I'm an AI assistant. Let me help you with that.
        
        ## Understanding Your Question
        
        Based on what you've asked, here's what I understand:
        - You want to see streaming text
        - You're interested in the typewriter effect
        - You want it to look like a chat interface
        
        ## My Answer
        
        The **MarkdownTypewriter** package is perfect for:
        1. Building chat interfaces
        2. Creating AI assistant UIs
        3. Displaying streaming content
        
        ### Code Example
        
        ```swift
        MarkdownTypewriterView(text: $streamedText)
            .typingSpeed(.fast)
        ```
        
        Is there anything else you'd like to know?
        """,
        
        """
        # SwiftUI Best Practices
        
        Let me share some best practices for SwiftUI development:
        
        ## State Management
        
        - Use `@State` for view-local state
        - Use `@StateObject` for reference types
        - Use `@Binding` to share state
        
        ## Performance Tips
        
        1. **Use LazyVStack/LazyHStack** for large lists
        2. **Minimize view updates** with proper state design
        3. **Profile with Instruments** to find bottlenecks
        
        ### Example
        
        ```swift
        struct EfficientView: View {
            @State private var items: [Item] = []
            
            var body: some View {
                LazyVStack {
                    ForEach(items) { item in
                        ItemRow(item: item)
                    }
                }
            }
        }
        ```
        
        > Remember: Premature optimization is the root of all evil!
        """,
        
        """
        # Markdown Formatting Guide
        
        Here's a comprehensive guide to markdown formatting:
        
        ## Text Styling
        
        - **Bold**: `**text**` or `__text__`
        - *Italic*: `*text*` or `_text_`
        - `Code`: `` `code` ``
        - ~~Strike~~: `~~text~~`
        
        ## Headers
        
        Use 1-6 hash symbols:
        
        ```markdown
        # H1
        ## H2
        ### H3
        ```
        
        ## Lists
        
        ### Unordered
        ```markdown
        - Item 1
        - Item 2
        ```
        
        ### Ordered
        ```markdown
        1. First
        2. Second
        ```
        
        ## Links and Images
        
        - Link: `[text](url)`
        - Image: `![alt](url)`
        
        ---
        
        That's all for now! 🚀
        """
    ]
    
    @State private var currentResponseIndex = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // User message
                        HStack {
                            Spacer()
                            Text("Show me a streaming example")
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .frame(maxWidth: 300, alignment: .trailing)
                        }
                        
                        // AI response
                        if !streamedText.isEmpty {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                                
                                MarkdownTypewriterView(text: $streamedText)
                                    .typingSpeed(.fast)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Controls
                HStack {
                    Button(action: startStreaming) {
                        Label(
                            isStreaming ? "Streaming..." : "Start Stream",
                            systemImage: "play.circle.fill"
                        )
                    }
                    .disabled(isStreaming)
                    
                    Spacer()
                    
                    Button("Next Response") {
                        currentResponseIndex = (currentResponseIndex + 1) % sampleResponses.count
                    }
                    .disabled(isStreaming)
                    
                    Spacer()
                    
                    Button("Clear") {
                        streamedText = ""
                    }
                    .disabled(isStreaming)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            }
            .navigationTitle("Streaming Demo")
        }
    }
    
    private func startStreaming() {
        isStreaming = true
        streamedText = ""
        
        let fullText = sampleResponses[currentResponseIndex]
        
        // Simulate streaming character by character
        for (index, char) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.01) {
                streamedText.append(char)
                
                if index == fullText.count - 1 {
                    isStreaming = false
                }
            }
        }
    }
}

// MARK: - Custom Theme Demo
@available(iOS 17.0, *)
struct CustomThemeView: View {
    @State private var markdown = """
    # Custom Theme Demo
    
    This view demonstrates **custom themes** and how they affect the appearance.
    
    ## Default Theme
    Uses standard sizes and colors.
    
    ## Large Theme
    Everything is *bigger* and more spacious.
    
    ## Custom Theme
    You can create your own with custom:
    - Font sizes
    - Colors
    - Spacing
    - And more!
    
    ```swift
    let theme = MarkdownTheme(
        h1FontSize: 28,
        bodyFontSize: 16,
        linkColor: .purple
    )
    ```
    """
    
    @State private var selectedTheme: ThemeOption = .default
    
    enum ThemeOption: String, CaseIterable {
        case `default` = "Default"
        case large = "Large"
        case custom = "Custom"
        
        var theme: MarkdownTheme {
            switch self {
            case .default:
                return .default
            case .large:
                return .large
            case .custom:
                return MarkdownTheme(
                    h1FontSize: 28,
                    h2FontSize: 24,
                    h3FontSize: 20,
                    bodyFontSize: 16,
                    lineSpacing: 4,
                    primaryColor: .primary,
                    linkColor: .purple
                )
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(ThemeOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                MarkdownTypewriterView(text: $markdown)
                    .markdownTheme(selectedTheme.theme)
                    .padding()
            }
            .navigationTitle("Custom Themes")
        }
    }
}

// MARK: - Playground View
@available(iOS 17.0, *)
struct PlaygroundView: View {
    @State private var markdown = "# Try typing markdown here!\n\nStart writing..."
    @State private var typingSpeed: TypingSpeed = .fast
    @State private var hasAutoScroll: Bool = true
    
    var body: some View {
        NavigationView {
            VStack {
                // Editor
                VStack(alignment: .leading) {
                    Text("Editor")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $markdown)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 200)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Settings
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Speed:")
                            Picker("Speed", selection: $typingSpeed) {
                                ForEach(TypingSpeed.allCases, id: \.self) { speed in
                                    Text(speed.description).tag(speed)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Toggle("Auto-scroll", isOn: $hasAutoScroll)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Preview
                VStack(alignment: .leading) {
                    Text("Preview")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    
                    MarkdownTypewriterView(text: $markdown)
                        .typingSpeed(typingSpeed)
                        .autoScroll(hasAutoScroll)
                        .padding()
                    
                }
            }
            .navigationTitle("Playground")
        }
    }
}

 */
 
// MARK: - Preview
/*
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
*/
