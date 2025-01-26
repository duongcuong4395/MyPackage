//
//  GeminiAI.swift
//  MyLibrary
//
//  Created by Macbook on 22/1/25.
//

import SwiftUI
import GoogleGenerativeAI


public enum GeminiAIVersion: String, Sendable, CaseIterable {
    case gemini_2_0_flash_exp = "gemini-2.0-flash-exp"
    case gemini_exp_1206 = "gemini-exp-1206"
    case gemini_2_0_flash_thinking_exp_01_21 = "gemini-2.0-flash-thinking-exp-01-21"
    
    case gemini_1_5_pro = "gemini-1.5-pro"
    case gemini_1_5_flash = "gemini-1.5-flash"
    case gemini_1_5_flash_8b = "gemini-1.5-flash-8b"
    
    public var name: String {
        switch self {
        case .gemini_2_0_flash_exp:
            return "2.0 Flash Experimental"
        case .gemini_exp_1206:
            return "2.0 Experimental 1206"
        case .gemini_2_0_flash_thinking_exp_01_21:
            return "2.0 Flash Thinking"
        case .gemini_1_5_pro:
            return "1.5 Pro"
        case .gemini_1_5_flash:
            return "1.5 Flash"
        case .gemini_1_5_flash_8b:
            return "1.5 Flash 8B"
        }
    }
    
}

@available(iOS 15.0, *)
public struct ChatMessage: Equatable, Identifiable {
    public var id = UUID()
    public var content: String
    public var isUser: Bool
    public var image: UIImage? = nil
    
    public init(content: String, isUser: Bool, image: UIImage? = nil) {
     
        self.content = content
        self.isUser = isUser
        self.image = image
    }
    public var swiftUIImage: Image? {
        if let uiImage = image {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    public func toModelContent() -> ModelContent {
        return ModelContent(role: isUser ? "user" : "model", parts: content)
    }
}

@available(iOS 15.0, *)
public protocol AIChatEvent: AnyObject {
    var chat: Chat? { get set } // Phiên chat
    var history: [ModelContent] { get set }
    var messages: [ChatMessage] { get set }
    func getKey() -> GeminiAI.GeminiAIModel
    func add(_ message: ChatMessage)
    
    func update(message: ChatMessage, by content: String)
    
    func resetHistory()
}

@available(iOS 15.0, *)
public extension AIChatEvent {
    func initializeChat(for schema: Schema? = nil) {
        if chat == nil {
            let modelKey = getKey()
            let model = getModel(with: modelKey, and: .gemini_2_0_flash_exp, and: schema)
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
        //messages.append(contentsOf: [aiMessage])
        add(aiMessage)
    }
    
    
    func sendMessage(_ text: String) async {
        guard let chat = chat else { return }
        let textSend = text
        // Gửi tin nhắn của người dùng
        let userMessage = ChatMessage(content: textSend, isUser: true)
        //messages.append(userMessage)
        add(userMessage)
        do {
            // Nhận phản hồi từ AI
            
            let response = try await chat.sendMessage(textSend)
            let aiMessage = ChatMessage(content: response.text ?? "", isUser: false)
            //messages.append(aiMessage)
            add(aiMessage)
        } catch {
            print("Error sending message: \(error)")
        }
    }
}

@available(iOS 15.0, *)
public extension AIChatEvent {
    func sendMess(with prompt: String, has stream: Bool = false) async {
        guard let chat = chat else { return }
        
        let userMessage = ChatMessage(content: prompt, isUser: true)
        add(userMessage)
        
        if stream {
            var fullResponse = ""
            var aiMessage = ChatMessage(content: "", isUser: false)
            add(aiMessage)

            let responseStream = chat.sendMessageStream(prompt)

            do {
                for try await chunk in responseStream {
                    if let text = chunk.text {
                        fullResponse += text
                        update(message: aiMessage, by: fullResponse)
                        /*
                        await MainActor.run {
                            // Cập nhật phản hồi từng phần
                            fullResponse += text
                            if let index = self.messages.firstIndex(where: { $0.id == aiMessage.id }) {
                                self.messages[index].content = fullResponse
                            }
                        }
                        */
                    }
                }
            } catch {
                print("Error during streaming: \(error)")
            }
        } else {
            do {
                let response = try await chat.sendMessage(prompt)
                let aiMessage = ChatMessage(content: response.text ?? "", isUser: false)
                add(aiMessage)
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}





