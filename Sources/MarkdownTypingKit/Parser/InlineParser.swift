import Foundation
import SwiftUI

@available(iOS 15.0, *)
/// Parser for inline markdown formatting (bold, italic, code, links, etc.)
final class InlineMarkdownParser {
    
    private struct InlinePattern {
        let regex: NSRegularExpression
        let transformer: (String) -> AttributedString
        let priority: Int // Higher = applied first
        
        init(pattern: String, priority: Int = 0, transformer: @escaping (String) -> AttributedString) {
            self.regex = try! NSRegularExpression(pattern: pattern, options: [])
            self.transformer = transformer
            self.priority = priority
        }
    }
    
    private let patterns: [InlinePattern]
    
    init() {
        self.patterns = [
            // Code spans (highest priority)
            InlinePattern(pattern: "`([^`]+)`", priority: 5) { content in
                var attr = AttributedString(content)
                attr.font = .system(size: 13).monospaced()
                attr.backgroundColor = Color.secondary.opacity(0.15)
                return attr
            },
            
            // Links
            InlinePattern(pattern: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", priority: 4) { content in
                var attr = AttributedString(content)
                attr.foregroundColor = .blue
                attr.underlineStyle = .single
                return attr
            },
            
            // Bold (** or __)
            InlinePattern(pattern: "\\*\\*((?:[^*]|\\*(?!\\*))+)\\*\\*", priority: 3) { content in
                var attr = AttributedString(content)
                attr.font = .system(size: 14, weight: .bold)
                return attr
            },
            InlinePattern(pattern: "__((?:[^_]|_(?!_))+)__", priority: 3) { content in
                var attr = AttributedString(content)
                attr.font = .system(size: 14, weight: .bold)
                return attr
            },
            
            // Italic (* or _)
            InlinePattern(pattern: "(?<!\\*)\\*([^*\\s][^*]*[^*\\s]|[^*\\s])\\*(?!\\*)", priority: 2) { content in
                var attr = AttributedString(content)
                attr.font = .system(size: 14).italic()
                return attr
            },
            InlinePattern(pattern: "(?<!_)_([^_\\s][^_]*[^_\\s]|[^_\\s])_(?!_)", priority: 2) { content in
                var attr = AttributedString(content)
                attr.font = .system(size: 14).italic()
                return attr
            },
            
            // Strikethrough
            InlinePattern(pattern: "~~([^~]+)~~", priority: 1) { content in
                var attr = AttributedString(content)
                attr.strikethroughStyle = .single
                attr.foregroundColor = .secondary
                return attr
            }
        ]
    }
    
    func parse(_ text: String) -> AttributedString {
        var result = text
        var ranges: [(NSRange, (AttributedString) -> AttributedString)] = []
        
        // Sort patterns by priority
        let sortedPatterns = patterns.sorted { $0.priority > $1.priority }
        
        for pattern in sortedPatterns {
            let matches = pattern.regex.matches(
                in: result,
                options: [],
                range: NSRange(0..<result.utf16.count)
            )
            
            for match in matches.reversed() {
                let contentGroupIndex = match.numberOfRanges > 1 ? 1 : 0
                
                if let contentRange = Range(match.range(at: contentGroupIndex), in: result) {
                    let content = String(result[contentRange])
                    
                    ranges.append((match.range, { _ in
                        pattern.transformer(content)
                    }))
                    
                    // Replace with spaces to avoid re-matching
                    if let fullRange = Range(match.range, in: result) {
                        result.replaceSubrange(
                            fullRange,
                            with: String(repeating: " ", count: match.range.length)
                        )
                    }
                }
            }
        }
        
        // Build final AttributedString
        var finalAttributedString = AttributedString(text)
        
        // Sort ranges by position (reversed)
        ranges.sort { $0.0.location > $1.0.location }
        
        for (range, transformer) in ranges {
            if let swiftRange = Range(range, in: text),
               let attrRange = Range(swiftRange, in: finalAttributedString) {
                let transformedAttr = transformer(finalAttributedString)
                finalAttributedString.replaceSubrange(attrRange, with: transformedAttr)
            }
        }
        
        return finalAttributedString
    }
}
