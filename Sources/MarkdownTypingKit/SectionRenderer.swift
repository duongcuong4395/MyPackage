import SwiftUI

@available(iOS 15.0, *)
/// Renders markdown sections into SwiftUI views
struct SectionRenderer {
    let theme: MarkdownTheme
    let inlineParser: InlineMarkdownParser
    
    init(theme: MarkdownTheme) {
        self.theme = theme
        self.inlineParser = InlineMarkdownParser()
    }
    
    @MainActor @ViewBuilder
    func render(_ section: MarkdownSection) -> some View {
        switch section.type {
        case .header(let level):
            renderHeader(section.content, level: level)
            
        case .paragraph:
            renderParagraph(section.content)
            
        case .codeBlock(let language):
            renderCodeBlock(section.content, language: language)
            
        case .unorderedList:
            renderUnorderedList(section.content)
            
        case .orderedList(let number):
            renderOrderedList(section.content, number: number)
            
        case .blockquote:
            renderBlockquote(section.content)
            
        case .horizontalRule:
            renderHorizontalRule()
            
        case .table(let rows):
            renderTable(rows: rows)
            
        case .emptyLine:
            Spacer().frame(height: theme.sectionSpacing)
        }
    }
    
    // MARK: - Specific Renderers
    
    private func renderHeader(_ content: String, level: Int) -> some View {
        let fontSize: CGFloat
        let weight: Font.Weight
        let topPadding: CGFloat
        let bottomPadding: CGFloat
        
        switch level {
        case 1:
            fontSize = theme.h1FontSize
            weight = .bold
            topPadding = 16
            bottomPadding = 6
        case 2:
            fontSize = theme.h2FontSize
            weight = .bold
            topPadding = 12
            bottomPadding = 4
        case 3:
            fontSize = theme.h3FontSize
            weight = .semibold
            topPadding = 8
            bottomPadding = 2
        default:
            fontSize = theme.h4FontSize
            weight = .medium
            topPadding = 6
            bottomPadding = 2
        }
        
        return Text(inlineParser.parse(content))
            .font(.system(size: fontSize, weight: weight))
            .foregroundColor(theme.primaryColor)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func renderParagraph(_ content: String) -> some View {
        Text(inlineParser.parse(content))
            .font(.system(size: theme.bodyFontSize))
            .foregroundColor(theme.primaryColor)
            .multilineTextAlignment(.leading)
            .lineSpacing(theme.lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @MainActor
    private func renderCodeBlock(_ content: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                HStack {
                    Text(language.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryColor)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.secondaryColor.opacity(0.1))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(content)
                    .font(.system(size: theme.codeFontSize).monospaced())
                    .foregroundColor(theme.primaryColor)
                    .multilineTextAlignment(.leading)
                    .padding(12)
            }
        }
        .background(theme.codeBackgroundColor)
        .cornerRadius(8)
        .padding(.vertical, 4)
    }
    
    @MainActor
    private func renderUnorderedList(_ content: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: theme.bodyFontSize, weight: .medium))
                .foregroundColor(theme.secondaryColor)
                .padding(.top, 1)
            
            Text(inlineParser.parse(content))
                .font(.system(size: theme.bodyFontSize))
                .foregroundColor(theme.primaryColor)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.leading, 8)
    }
    
    @MainActor
    private func renderOrderedList(_ content: String, number: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(size: theme.bodyFontSize, weight: .medium))
                .foregroundColor(theme.secondaryColor)
                .padding(.top, 1)
                .frame(minWidth: 20, alignment: .trailing)
            
            Text(inlineParser.parse(content))
                .font(.system(size: theme.bodyFontSize))
                .foregroundColor(theme.primaryColor)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.leading, 8)
    }
    
    @MainActor
    private func renderBlockquote(_ content: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(theme.linkColor.opacity(0.4))
                .frame(width: 3)
            
            Text(inlineParser.parse(content))
                .font(.system(size: theme.bodyFontSize))
                .foregroundColor(theme.secondaryColor)
                .italic()
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(theme.secondaryColor.opacity(0.05))
        .cornerRadius(4)
    }
    
    private func renderHorizontalRule() -> some View {
        Divider()
            .padding(.vertical, 8)
    }
    
    private func renderTable(rows: [String]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                let cells = row
                    .components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                HStack(spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { cellIndex, cell in
                        Text(inlineParser.parse(cell))
                            .font(.system(
                                size: theme.codeFontSize,
                                weight: index == 0 ? .semibold : .regular
                            ))
                            .foregroundColor(theme.primaryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if cellIndex < cells.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(index == 0 ? theme.secondaryColor.opacity(0.1) : Color.clear)
                
                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.secondaryColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
}
