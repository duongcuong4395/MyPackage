import Foundation
import Combine

/// Engine for managing typewriter effect with optimized performance
@available(iOS 13.0, *)
@MainActor
class TypewriterEngine: ObservableObject {
    @Published private(set) var displayedText: String = ""
    @Published private(set) var isTypewriting: Bool = false
    
    private var sourceText: String = ""
    private var currentIndex: String.Index
    nonisolated(unsafe) private var timer: Timer?
    private var typingSpeed: TypingSpeed
    
    init(typingSpeed: TypingSpeed = .fast) {
        self.typingSpeed = typingSpeed
        self.currentIndex = "".startIndex
    }
    
    
    deinit {
        //stop()
        timer?.invalidate()
       timer = nil
    }
    
    // MARK: - Public API
    
    /// Update the source text and start/continue typewriting
    func updateSource(_ newText: String) {
        // If text hasn't changed, do nothing
        guard newText != sourceText else { return }
        
        let oldText = sourceText
        sourceText = newText
        
        // If we're starting fresh or text got shorter
        if oldText.isEmpty || newText.count < oldText.count {
            displayedText = ""
            currentIndex = newText.startIndex
        }
        
        // If displayed text matches source, we're done
        if displayedText == sourceText {
            isTypewriting = false
            return
        }
        
        // Start typewriting if not already running
        if !isTypewriting && currentIndex < sourceText.endIndex {
            startTypewriting()
        }
    }
    
    /// Stop typewriting and show all text immediately
    //@MainActor
    func skipToEnd() {
        stop()
        displayedText = sourceText
        currentIndex = sourceText.endIndex
    }
    
    /// Stop typewriting
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isTypewriting = false
    }
    
    /// Update typing speed
    func setSpeed(_ speed: TypingSpeed) {
        let wasTypewriting = isTypewriting
        stop()
        typingSpeed = speed
        if wasTypewriting {
            startTypewriting()
        }
    }
    
    // MARK: - Private Methods
    
    private func startTypewriting() {
        guard currentIndex < sourceText.endIndex else {
            isTypewriting = false
            return
        }
        
        isTypewriting = true
        
        timer = Timer.scheduledTimer(
            withTimeInterval: typingSpeed.rawValue,
            repeats: true) { [weak self] _ in
            
                Task { @MainActor in
                self?.typeNextCharacter()
            }
        }
    }
    
    private func typeNextCharacter() {
        guard currentIndex < sourceText.endIndex else {
            stop()
            return
        }
        
        let nextIndex = sourceText.index(after: currentIndex)
        displayedText = String(sourceText[..<nextIndex])
        currentIndex = nextIndex
    }
}

/// Cached version of TypewriterEngine for better performance
@available(iOS 13.0, *)
@MainActor
final class CachedTypewriterEngine: TypewriterEngine {
    private var parsedSectionsCache: [String: [MarkdownSection]] = [:]
    private let cacheLimit = 50 
    
    func getCachedSections(for text: String, parser: MarkdownParser) -> [MarkdownSection] {
        if let cached = parsedSectionsCache[text] {
            return cached
        }
        
        let sections = parser.parse(text)
        
        // Clean cache if too large
        if parsedSectionsCache.count >= cacheLimit {
            let keysToRemove = Array(parsedSectionsCache.keys.prefix(10))
            keysToRemove.forEach { parsedSectionsCache.removeValue(forKey: $0) }
        }
        
        parsedSectionsCache[text] = sections
        return sections
    }
    
    func clearCache() {
        parsedSectionsCache.removeAll()
    }
}
