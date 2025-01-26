//
//  TextEffectAdvanced.swift
//  MyLibrary
//
//  Created by Macbook on 24/1/25.
//

import SwiftUI

@available(iOS 13.0, *)
struct TextEffectAdvanced: View {
    let text: String
    @State private var displayedCharacters = ""
    @State private var isTyping = true
    let typingSpeed: Double

    var body: some View {
        Text(displayedCharacters)
            .font(Font.custom("Bebas Neue", size: 45))
            .bold()
            .onAppear {
                startTypingEffect()
            }
    }

    private func startTypingEffect() {
        isTyping = true
        DispatchQueue.global(qos: .userInteractive).async {
            for index in text.indices {
                DispatchQueue.main.async {
                    displayedCharacters.append(text[index])
                }
                Thread.sleep(forTimeInterval: typingSpeed) // Tốc độ gõ (tùy chỉnh)
            }
            DispatchQueue.main.async {
                isTyping = false // Kết thúc hiệu ứng
            }
        }
    }
}
