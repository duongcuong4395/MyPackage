import SwiftUI

@available(iOS 17.0, *)
/// Main view for displaying markdown with typewriter effect
public struct MarkdownTypewriterView: View {
    @Binding private var text: String
    @Binding private var isTypingComplete: Bool
    private let configuration: MarkdownConfiguration
    
    @StateObject private var engine: CachedTypewriterEngine
    @State private var lastSectionCount: Int = 0
    
    private let parser = MarkdownParser()
    private let renderer: SectionRenderer
    
    public init(
        text: Binding<String>,
        isTypingComplete: Binding<Bool>,
        configuration: MarkdownConfiguration = MarkdownConfiguration()
    ) {
        self._text = text
        self._isTypingComplete = isTypingComplete
        self.configuration = configuration
        self.renderer = SectionRenderer(theme: configuration.theme)
        
        let engine = CachedTypewriterEngine(typingSpeed: configuration.typingSpeed)
        self._engine = StateObject(wrappedValue: engine)
    }
    
    private init(
        text: Binding<String>,
        isTypingComplete: Binding<Bool>,
        configuration: MarkdownConfiguration,
        renderer: SectionRenderer,
        engine: CachedTypewriterEngine
    ) {
        self._text = text
        self._isTypingComplete = isTypingComplete
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
                    
                    // Invisible anchor at the bottom
                    Color.clear
                        .frame(height: 1)
                        .id("bottom_anchor")
                }
                .padding(.horizontal, configuration.theme.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            .onChange(of: engine.displayedText) { _, newValue in
                if configuration.enableAutoScroll && engine.isTypewriting {
                    let sections = engine.getCachedSections(for: newValue, parser: parser)
                    
                    // Only scroll when:
                    // - Section count changes (new paragraph/header/etc)
                    // - Every 30 characters (for long paragraphs)
                    if sections.count != lastSectionCount || newValue.count % 100 == 0 {
                        lastSectionCount = sections.count
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("bottom_anchor", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .onChange(of: text) { _, newValue in
                isTypingComplete = false
                engine.updateSource(newValue)
            }
            .onChange(of: configuration.typingSpeed) { _, newSpeed in
                engine.setSpeed(newSpeed)
            }
            .onAppear {
                engine.updateSource(text)
                
                isTypingComplete = false
                
                //engine.setSpeed(configuration.typingSpeed)
                engine.onTypewritingComplete = {
                    isTypingComplete = true
                }
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
        isTypingComplete: Binding<Bool>,
        configuration: MarkdownConfiguration = MarkdownConfiguration()
    ) {
        self.init(
            text: .constant(staticText),
            isTypingComplete: isTypingComplete,
            configuration: configuration
        )
    }
    
    /// Modifier to customize typing speed
    func typingSpeed(_ speed: TypingSpeed) -> MarkdownTypewriterView {
        var config = configuration
        config.typingSpeed = speed
        return MarkdownTypewriterView(text: $text, isTypingComplete: $isTypingComplete, configuration: config)
    }
    
    /// Modifier to customize theme
    func markdownTheme(_ theme: MarkdownTheme) -> MarkdownTypewriterView {
        var config = configuration
        config.theme = theme
        return MarkdownTypewriterView(text: $text, isTypingComplete: $isTypingComplete, configuration: config)
    }
    
    /// Modifier to enable/disable auto-scroll
    func autoScroll(_ enabled: Bool) -> MarkdownTypewriterView {
        var config = configuration
        config.enableAutoScroll = enabled
        return MarkdownTypewriterView(text: $text, isTypingComplete: $isTypingComplete, configuration: config)
    }
    
    /*
    /// Use `false` when embedding in another ScrollView (e.g., chat bubbles)
    func scrollable(_ enabled: Bool) -> MarkdownTypewriterView {
        var config = configuration
        config.enableScrollView = enabled
        return MarkdownTypewriterView(text: $text, configuration: config)
    }
    
    /// Convenience modifier for embedded use (disables ScrollView and auto-scroll)
    func embedded() -> MarkdownTypewriterView {
        var config = configuration
        config.enableScrollView = false
        config.enableAutoScroll = false
        return MarkdownTypewriterView(text: $text, configuration: config)
    }
    */
}
