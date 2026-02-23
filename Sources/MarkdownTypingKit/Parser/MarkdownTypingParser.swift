//
//  MarkdownTypingParser.swift
//  MyLibrary
//
//  Created by Macbook on 14/1/26.
//

import Foundation
import SwiftUI

// MARK: InlineParser.swift

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

// MARK: MarkdownParser.swift

/// Protocol for markdown parsing strategies
protocol MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection?
}

/// Context for parsing state
struct ParsingContext {
    var lines: [String]
    var currentIndex: Int
    var inCodeBlock: Bool = false
    var codeBlockLanguage: String = ""
    var codeBlockLines: [String] = []
    
    mutating func advance() {
        currentIndex += 1
    }
    
    func hasMoreLines() -> Bool {
        currentIndex < lines.count
    }
    
    func currentLine() -> String {
        guard hasMoreLines() else { return "" }
        return lines[currentIndex]
    }
}

/// Main markdown parser using strategy pattern
final class MarkdownParser {
    private let strategies: [MarkdownParsingStrategy]
    
    init() {
        self.strategies = [
            CodeBlockStrategy(),
            HeaderStrategy(),
            HorizontalRuleStrategy(),
            OrderedListStrategy(),
            UnorderedListStrategy(),
            BlockquoteStrategy(),
            TableStrategy(),
            EmptyLineStrategy(),
            ParagraphStrategy() // Must be last (fallback)
        ]
    }
    
    func parse(_ text: String) -> [MarkdownSection] {
        let lines = text.components(separatedBy: .newlines)
        var context = ParsingContext(lines: lines, currentIndex: 0)
        var sections: [MarkdownSection] = []
        
        while context.hasMoreLines() {
            let line = context.currentLine()
            
            // Try each strategy
            for strategy in strategies {
                if strategy.canParse(line) {
                    if let section = strategy.parse(line, context: &context) {
                        sections.append(section)
                    }
                    break
                }
            }
            
            context.advance()
        }
        
        return sections
    }
}

// MARK: - Parsing Strategies

struct CodeBlockStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("```")
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        
        var codeLines: [String] = []
        context.advance()
        
        while context.hasMoreLines() {
            let currentLine = context.currentLine()
            if currentLine.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("```") {
                break
            }
            codeLines.append(currentLine)
            context.advance()
        }
        
        let codeContent = codeLines.joined(separator: "\n")
        return MarkdownSection(
            type: .codeBlock(language: language),
            content: codeContent,
            metadata: ["language": language]
        )
    }
}

struct HeaderStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("#") && !trimmed.hasPrefix("####") ||
               trimmed.hasPrefix("##") ||
               trimmed.hasPrefix("###") ||
               trimmed.hasPrefix("####")
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var level = 0
        var content = trimmed
        
        if trimmed.hasPrefix("#### ") {
            level = 4
            content = String(trimmed.dropFirst(5))
        } else if trimmed.hasPrefix("### ") {
            level = 3
            content = String(trimmed.dropFirst(4))
        } else if trimmed.hasPrefix("## ") {
            level = 2
            content = String(trimmed.dropFirst(3))
        } else if trimmed.hasPrefix("# ") {
            level = 1
            content = String(trimmed.dropFirst(2))
        }
        
        return MarkdownSection(
            type: .header(level: level),
            content: content,
            metadata: ["level": "\(level)"]
        )
    }
}

struct HorizontalRuleStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("---") || trimmed.hasPrefix("***")
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        MarkdownSection(type: .horizontalRule, content: "")
    }
}

struct OrderedListStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            let content = String(trimmed[match.upperBound...])
            let number = String(trimmed[..<match.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            return MarkdownSection(
                type: .orderedList(number: number),
                content: content,
                metadata: ["number": number]
            )
        }
        
        return nil
    }
}

struct UnorderedListStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ")
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = String(trimmed.dropFirst(2))
        
        return MarkdownSection(type: .unorderedList, content: content)
    }
}

struct BlockquoteStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("> ")
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = String(trimmed.dropFirst(2))
        
        return MarkdownSection(type: .blockquote, content: content)
    }
}

struct TableStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("| ") && trimmed.hasSuffix(" |")
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        var tableRows: [String] = []
        
        while context.hasMoreLines() {
            let currentLine = context.currentLine()
            let trimmed = currentLine.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("| ") && trimmed.hasSuffix(" |") {
                tableRows.append(trimmed)
                context.advance()
            } else if trimmed.hasPrefix("|") && trimmed.contains("-") {
                // Skip separator row
                context.advance()
            } else {
                break
            }
        }
        
        // Move back one line since we advanced past the table
        if context.currentIndex > 0 {
            context.currentIndex -= 1
        }
        
        return MarkdownSection(
            type: .table(rows: tableRows),
            content: tableRows.joined(separator: "\n")
        )
    }
}

struct EmptyLineStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        MarkdownSection(type: .emptyLine, content: "")
    }
}

struct ParagraphStrategy: MarkdownParsingStrategy {
    func canParse(_ line: String) -> Bool {
        true // Fallback strategy
    }
    
    func parse(_ line: String, context: inout ParsingContext) -> MarkdownSection? {
        var paragraph = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let startIndex = context.currentIndex
        
        context.advance()
        
        // Collect consecutive non-empty lines
        while context.hasMoreLines() {
            let nextLine = context.currentLine()
            let trimmed = nextLine.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmed.isEmpty &&
               !trimmed.hasPrefix("#") &&
               !trimmed.hasPrefix("-") &&
               !trimmed.hasPrefix("*") &&
               !trimmed.hasPrefix(">") &&
               !trimmed.hasPrefix("```") &&
               !trimmed.hasPrefix("|") {
                paragraph += " " + trimmed
                context.advance()
            } else {
                break
            }
        }
        
        // Move back one line
        if context.currentIndex > startIndex + 1 {
            context.currentIndex -= 1
        }
        
        return MarkdownSection(type: .paragraph, content: paragraph)
    }
}
