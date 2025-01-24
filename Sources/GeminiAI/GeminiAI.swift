//
//  GeminiAI.swift
//  MyLibrary
//
//  Created by Macbook on 22/1/25.
//

import SwiftUI
import GoogleGenerativeAI
//import GoogleGenerativeAI

@available(iOS 15.0, *)
public struct ChatMessage: Identifiable {
    public var id = UUID()
    public var content: String
    public var isUser: Bool
    public var image: UIImage? = nil
    
    public init(content: String, isUser: Bool, image: UIImage? = nil) {
     
        self.content = content
        self.isUser = isUser
        self.image = image
    }
    var swiftUIImage: Image? {
        if let uiImage = image {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    public func toModelContent() -> ModelContent {
        //ModelContent(text: content, author: isUser ? "user" : "bot")
        return ModelContent(role: isUser ? "user" : "model", parts: content)
    }
}

@available(iOS 15.0, *)
public protocol AIChatEvent: AnyObject {
    
    var chat: Chat? { get set } // Phiên chat
    var history: [ModelContent] { get set }
    var messages: [ChatMessage] { get set }
    func getKey() -> GeminiAI.GeminiAIModel
}

@available(iOS 15.0, *)
public extension AIChatEvent {
    func initializeChat() {
        if chat == nil {
            let modelKey = getKey()
            let model = getModel(with: modelKey, and: .gemini_2_0_flash_exp)
            chat = model.startChat(history: history )
        }
    }
    
    func getModel(with model: GeminiAIModel, and version: GeminiAIVersion, and schema: Schema? = nil) -> GenerativeModel {
        return GenerativeModel(
            name: version.rawValue,
          apiKey:  model.valueItem,
          generationConfig: GenerationConfig(
            temperature: 1,
            topP: 0.95,
            topK: 64,
            maxOutputTokens: 1048576, //8192,
            responseMIMEType: (schema != nil) ? "application/json" : "text/plain"
            , responseSchema: schema
          ),
          safetySettings: [
            SafetySetting(harmCategory: .harassment, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .hateSpeech, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .dangerousContent, threshold: .blockMediumAndAbove)
          ]
        )
    }
    
    func chat(with message: String, and image: UIImage, of version: GeminiAIVersion) async throws {
        let modelKey = getKey()
        
        let model = getModel(with: modelKey, and: version)
        
        let response = try await model.generateContent(message, image)
        if let text = response.text {
          print(text)
        }
        let aiMessage = ChatMessage(content: response.text ?? "", isUser: false)
        chat?.history.append(aiMessage.toModelContent())
        print("=== chat", chat?.history ?? "")
        messages.append(contentsOf: [aiMessage])
    }
    
    //@MainActor
    func sendMessage(_ text: String) async {
        guard let chat = chat else { return }
        
        // Gửi tin nhắn của người dùng
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        do {
            // Nhận phản hồi từ AI
            
            let response = try await chat.sendMessage(text)
            let aiMessage = ChatMessage(content: response.text ?? "", isUser: false)
            print("=== chat", chat.history)
            messages.append(aiMessage)
        } catch {
            print("Error sending message: \(error)")
        }
    }
}
