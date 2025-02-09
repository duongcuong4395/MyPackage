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
public struct AIImage: Identifiable {
    public var id = UUID()
    public var image: Image
}

@available(iOS 16.0, *)
public struct ChatMessage: Equatable, Identifiable, Hashable {
    public var id = UUID()
    public var content: String // String
    public var isUser: Bool
    public var images: [UIImage] = []
    
    public init(content: String, isUser: Bool, images: [UIImage] = []) {
     
        self.content = content
        self.isUser = isUser
        self.images = images
    }
    public var swiftUIImages: [AIImage] {
        return images.map { uiImage in
            return AIImage(image: Image(uiImage: uiImage)) 
        }
    }
    
    public func toModelContent() -> ModelContent {
        return ModelContent(role: isUser ? "user" : "model", parts: content)
    }
    
    public var localizedContent: LocalizedStringKey {
        return LocalizedStringKey(content)
    }
}

@available(iOS 16.0, *)
public enum RequestBy: String, Sendable {
    case Client
    case System
}

@available(iOS 16.0, *)
public protocol AIChatEvent: AnyObject {
    var chat: Chat? { get set } // Phiên chat
    var inputText: String { get set }
    var history: [ModelContent] { get set }
    var messages: [ChatMessage] { get set }
    var imagesSelected: [UIImage] { get set }
    var promptsSuggest: [String] { get set }
    
    func getKey() -> GeminiAI.GeminiAIModel
    
    func add(_ message: ChatMessage)
    func update(message: ChatMessage, by content: String)
    func resetHistory()
    func addChatHistory(by message: ChatMessage)
    
    func remove(image: UIImage)
    
    func eventFrom(aiResponse: ChatMessage)
    
    func aiSendSuggestIdea() async
    func resetSuggestIdea()
    func chat(by owner: RequestBy, with prompt: String
              , and images: [UIImage]
              , has stream: Bool
              , of versionAI: GeminiAIVersion) async throws
}

@available(iOS 16.0, *)
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
}

@available(iOS 16.0, *)
public extension AIChatEvent {
    func clientSend(with prompt: String
                    , and images: [UIImage]) {
        
        let userMessage = images.count > 0 ? ChatMessage(content: prompt, isUser: true, images: images) : ChatMessage(content: prompt, isUser: true)
        add(userMessage)
    }
    
    // MARK: Send Text
    func aiResponse(with prompt: String, has stream: Bool = false) async {
        guard let chat = chat else { return }
        
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
    
    // MARK: Send Text And Images
    
    func aiResponse(with prompt: String
                    , and images: [UIImage]
                    , has stream: Bool = false
                    , of version: GeminiAIVersion) async throws {
        
        guard chat != nil else { return }
        let modelKey = getKey()
        
        let model = getModel(with: modelKey, and: version)
        if stream {
            var fullResponse = ""
            let aiMessage = ChatMessage(content: "", isUser: false)
            add(aiMessage)
            
            if images.count == 1 {
                let contentStream = model.generateContentStream(prompt, images[0])
                for try await chunk in contentStream {
                  if let text = chunk.text {
                      fullResponse += text
                      update(message: aiMessage, by: fullResponse)
                      
                  }
                }
            } else if images.count == 2 {
                let contentStream = model.generateContentStream(prompt, images[0], images[1])
                for try await chunk in contentStream {
                  if let text = chunk.text {
                      fullResponse += text
                      update(message: aiMessage, by: fullResponse)
                      
                  }
                }
            }
            else if images.count == 3 {
               let contentStream = model.generateContentStream(prompt, images[0], images[1], images[2])
                
                for try await chunk in contentStream {
                  if let text = chunk.text {
                      fullResponse += text
                      print("=== fullResponse", fullResponse)
                      update(message: aiMessage, by: fullResponse)
                      
                  }
                }
           }
            addChatHistory(by: aiMessage)
        } else {
            let response = try await model.generateContent(prompt, images[0])
            if let text = response.text {
              print("=== response", text)
            }
            let aiMessage = ChatMessage(content: response.text ?? "", isUser: false)
            print("=== aiMessage", aiMessage)
            addChatHistory(by: aiMessage)
        }
        
    }
}

@available(iOS 16.0, *)
public extension AIChatEvent {
    
    func add(_ message: ChatMessage) {}
    func update(message: ChatMessage, by content: String) {}
    func resetHistory() {}
    func addChatHistory(by message: ChatMessage) {}
    func remove(image: UIImage) {}
    
    func aiSendSuggestIdea() async {}
    func resetSuggestIdea() {}
    
    func chat(by owner: RequestBy, with prompt: String
              , and images: [UIImage] = []
              , has stream: Bool = false
              , of versionAI: GeminiAIVersion = .gemini_2_0_flash_exp) async throws {}
}
