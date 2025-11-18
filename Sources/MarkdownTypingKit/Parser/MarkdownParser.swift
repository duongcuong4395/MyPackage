import Foundation

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
