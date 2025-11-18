//
//  MarkdownModels.swift
//  MyLibrary
//
//  Created by Macbook on 15/11/25.
//

import Foundation
import SwiftUI

// MARK: - Public Configuration Models

/// Typing speed configuration for typewriter effect
public enum TypingSpeed: Double, CaseIterable, Sendable {
    case veryFast = 0.005
    case fast = 0.01
    case normal = 0.05
    case slow = 0.1
    case verySlow = 0.2
    
    public var description: String {
        switch self {
        case .veryFast: return "Very Fast"
        case .fast: return "Fast"
        case .normal: return "Normal"
        case .slow: return "Slow"
        case .verySlow: return "Very Slow"
        }
    }
}

@available(iOS 13.0, *)
/// Configuration for MarkdownTypewriter appearance
public struct MarkdownConfiguration: Sendable {
    public var typingSpeed: TypingSpeed
    public var showIndicators: Bool
    public var enableAutoScroll: Bool
    public var enableScrollView: Bool
    public var theme: MarkdownTheme
    
    public init(
        typingSpeed: TypingSpeed = .fast,
        showIndicators: Bool = false,
        enableAutoScroll: Bool = true,
        enableScrollView: Bool = true,
        theme: MarkdownTheme = .default
    ) {
        self.typingSpeed = typingSpeed
        self.showIndicators = showIndicators
        self.enableAutoScroll = enableAutoScroll
        self.enableScrollView = enableScrollView
        self.theme = theme
    }
}

@available(iOS 13.0, *)
/// Theme configuration for markdown rendering
public struct MarkdownTheme: Sendable {
    // Font sizes
    public var h1FontSize: CGFloat
    public var h2FontSize: CGFloat
    public var h3FontSize: CGFloat
    public var h4FontSize: CGFloat
    public var bodyFontSize: CGFloat
    public var codeFontSize: CGFloat
    
    // Spacing
    public var lineSpacing: CGFloat
    public var sectionSpacing: CGFloat
    public var horizontalPadding: CGFloat
    
    // Colors
    public var primaryColor: Color
    public var secondaryColor: Color
    public var codeBackgroundColor: Color
    public var linkColor: Color
    
    public static let `default` = MarkdownTheme(
        h1FontSize: 20,
        h2FontSize: 18,
        h3FontSize: 16,
        h4FontSize: 15,
        bodyFontSize: 14,
        codeFontSize: 13,
        lineSpacing: 2,
        sectionSpacing: 8,
        horizontalPadding: 0,
        primaryColor: .primary,
        secondaryColor: .secondary,
        codeBackgroundColor: Color.secondary.opacity(0.05),
        linkColor: .blue
    )
    
    public static let large = MarkdownTheme(
        h1FontSize: 24,
        h2FontSize: 22,
        h3FontSize: 20,
        h4FontSize: 18,
        bodyFontSize: 16,
        codeFontSize: 15,
        lineSpacing: 3,
        sectionSpacing: 12,
        horizontalPadding: 0,
        primaryColor: .primary,
        secondaryColor: .secondary,
        codeBackgroundColor: Color.secondary.opacity(0.05),
        linkColor: .blue
    )
    
    public init(
        h1FontSize: CGFloat = 20,
        h2FontSize: CGFloat = 18,
        h3FontSize: CGFloat = 16,
        h4FontSize: CGFloat = 15,
        bodyFontSize: CGFloat = 14,
        codeFontSize: CGFloat = 13,
        lineSpacing: CGFloat = 2,
        sectionSpacing: CGFloat = 8,
        horizontalPadding: CGFloat = 0,
        primaryColor: Color = .primary,
        secondaryColor: Color = .secondary,
        codeBackgroundColor: Color = Color.secondary.opacity(0.05),
        linkColor: Color = .blue
    ) {
        self.h1FontSize = h1FontSize
        self.h2FontSize = h2FontSize
        self.h3FontSize = h3FontSize
        self.h4FontSize = h4FontSize
        self.bodyFontSize = bodyFontSize
        self.codeFontSize = codeFontSize
        self.lineSpacing = lineSpacing
        self.sectionSpacing = sectionSpacing
        self.horizontalPadding = horizontalPadding
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.codeBackgroundColor = codeBackgroundColor
        self.linkColor = linkColor
    }
}

// MARK: - Internal Models

/// Represents a parsed markdown section
struct MarkdownSection: Identifiable {
    let id = UUID()
    let type: MarkdownSectionType
    let content: String
    let metadata: [String: String]
    
    init(type: MarkdownSectionType, content: String, metadata: [String: String] = [:]) {
        self.type = type
        self.content = content
        self.metadata = metadata
    }
}

/// Types of markdown sections
enum MarkdownSectionType {
    case header(level: Int)
    case paragraph
    case codeBlock(language: String)
    case unorderedList
    case orderedList(number: String)
    case blockquote
    case horizontalRule
    case table(rows: [String])
    case emptyLine
}
