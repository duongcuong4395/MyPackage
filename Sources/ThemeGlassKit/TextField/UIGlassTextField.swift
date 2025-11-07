//
//  UIGlassTextField.swift
//  MyLibrary
//
//  Created by Macbook on 7/11/25.
//

import SwiftUI

// MARK: - Optimized Form Controls
@available(iOS 17.0, *)
public struct UIGlassTextField: View {
    @Binding var text: String
    let placeholder: String
    
    @State private var isFocused = false
    @FocusState private var textFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(placeholder)
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isFocused || !text.isEmpty ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isFocused ? Color.blue : Color.white.opacity(colorScheme == .dark ? 0.4 : 0.3),
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                )
                .focused($textFieldFocused)
                .onChange(of: textFieldFocused) { _, focused in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = focused
                    }
                }
                .accessibilityLabel(placeholder)
                .accessibilityValue(text)
        }
    }
}
