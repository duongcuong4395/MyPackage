import SwiftUI
/*
@available(iOS 17.0, *)
/// Main view for displaying markdown with typewriter effect
public struct MarkdownTypewriterView: View {
    @Binding private var text: String
    private let configuration: MarkdownConfiguration
    
    @StateObject private var engine: CachedTypewriterEngine
    @State private var contentHeight: CGFloat = 0
    
    private let parser = MarkdownParser()
    private let renderer: SectionRenderer
    
    /// Initialize with binding and optional configuration
    public init(
        text: Binding<String>,
        configuration: MarkdownConfiguration = MarkdownConfiguration()
    ) {
        self._text = text
        self.configuration = configuration
        self.renderer = SectionRenderer(theme: configuration.theme)
        
        let engine = CachedTypewriterEngine(typingSpeed: configuration.typingSpeed)
        self._engine = StateObject(wrappedValue: engine)
    }
    
    /// Private initializer for modifier support
    private init(
        text: Binding<String>,
        configuration: MarkdownConfiguration,
        renderer: SectionRenderer,
        engine: CachedTypewriterEngine
    ) {
        self._text = text
        self.configuration = configuration
        self.renderer = renderer
        self._engine = StateObject(wrappedValue: engine)
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: configuration.showIndicators) {
                LazyVStack(
                    alignment: .leading,
                    spacing: configuration.theme.sectionSpacing
                ) {
                    let sections = engine.getCachedSections(
                        for: engine.displayedText,
                        parser: parser
                    )
                    
                    ForEach(sections) { section in
                        renderer.render(section)
                            .id(section.id)
                    }
                }
                .padding(.horizontal, configuration.theme.horizontalPadding)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ContentHeightPreferenceKey.self,
                                value: geometry.size.height
                            )
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .id("bottom_anchor")
            }
            .onPreferenceChange(ContentHeightPreferenceKey.self) { newHeight in
                contentHeight = newHeight
                
                if configuration.enableAutoScroll && engine.isTypewriting {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom_anchor", anchor: .bottom)
                    }
                }
            }
            .onChange(of: text) { _, newValue in
                engine.updateSource(newValue)
            }
            .onAppear {
                engine.updateSource(text)
            }
        }
    }
}

// MARK: - Preference Key for Height Tracking
@available(iOS 17.0, *)
private struct ContentHeightPreferenceKey: @preconcurrency PreferenceKey {
    @MainActor static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Convenience Extensions
@available(iOS 17.0, *)
public extension MarkdownTypewriterView {
    /// Initialize with static text (non-binding)
    init(
        staticText: String,
        configuration: MarkdownConfiguration = MarkdownConfiguration()
    ) {
        self.init(
            text: .constant(staticText),
            configuration: configuration
        )
    }
    
    /// Modifier to customize typing speed
    func typingSpeed(_ speed: TypingSpeed) -> MarkdownTypewriterView {
        var config = configuration
        config.typingSpeed = speed
        return MarkdownTypewriterView(text: $text, configuration: config)
    }
    
    /// Modifier to customize theme
    func markdownTheme(_ theme: MarkdownTheme) -> MarkdownTypewriterView {
        var config = configuration
        config.theme = theme
        return MarkdownTypewriterView(text: $text, configuration: config)
    }
    
    /// Modifier to enable/disable auto-scroll
    func autoScroll(_ enabled: Bool) -> MarkdownTypewriterView {
        var config = configuration
        config.enableAutoScroll = enabled
        return MarkdownTypewriterView(text: $text, configuration: config)
    }
}
*/


// MARK: - Preview Support

/*
#if DEBUG
struct MarkdownTypewriterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Basic preview
            MarkdownTypewriterView(
                staticText: """
                # Hello World
                
                This is a **markdown** example with *italic* text and `code`.
                
                ## Features
                - Bullet points
                - **Bold** and *italic*
                - Code blocks
                
                ```swift
                let greeting = "Hello"
                print(greeting)
                ```
                """,
                configuration: MarkdownConfiguration(typingSpeed: .fast)
            )
            .previewDisplayName("Basic")
            
            // Large theme preview
            MarkdownTypewriterView(
                staticText: "# Large Theme\n\nThis uses a larger theme.",
                configuration: MarkdownConfiguration(theme: .large)
            )
            .previewDisplayName("Large Theme")
        }
    }
}
#endif
*/
