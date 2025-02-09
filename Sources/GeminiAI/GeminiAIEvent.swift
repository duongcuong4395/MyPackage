//
//  GeminiAIEvent.swift
//  MyLibrary
//
//  Created by Macbook on 22/1/25.
//

import GoogleGenerativeAI
import CoreData
import SwiftUI

@available(iOS 16.0, *)
public protocol ChatManager: MessageHandling {
    var chat: Chat? { get set }
    var messages: [ChatMessage] { get set }
    var history: [ModelContent] { get set }
    
    func initializeChat(for schema: Schema)
    func getKey() -> GeminiAI.GeminiAIModel
    func chat(by owner: RequestBy, with prompt: String, and images: [UIImage], has stream: Bool, of versionAI: GeminiAIVersion) async throws
}
@available(iOS 16.0, *)
public extension ChatManager {
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
public protocol MessageHandling: AnyObject {
    var messages: [ChatMessage] { get set }
    var history: [ModelContent] { get set }
    
    func add(_ message: ChatMessage)
    func update(message: ChatMessage, by content: String)
    func addChatHistory(by message: ChatMessage)
}

@available(iOS 16.0, *)
public extension MessageHandling {
    func add(_ message: ChatMessage) {
        //messages.append(message)
    }
    
    func update(message: ChatMessage, by content: String) {
        /*
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].content = content
        }
        */
    }

    func addChatHistory(by message: ChatMessage) {}
}


@available(iOS 16.0, *)
public protocol ImageHandling: AnyObject {
    var imagesSelected: [UIImage] { get set }
    func remove(image: UIImage)
}

@available(iOS 16.0, *)
public extension ImageHandling {
    func remove(image: UIImage) {
        imagesSelected.removeAll { $0 == image }
    }
}



@available(iOS 16.0, *)
public protocol AISuggestionHandling: AnyObject {
    var promptsSuggest: [String] { get set }
    func aiSendSuggestIdea() async
    func resetSuggestIdea()
}

@available(iOS 16.0, *)
public extension AISuggestionHandling {
    func aiSendSuggestIdea() async {
        // Mặc định là không có gợi ý, có thể override nếu cần
    }
    
    func resetSuggestIdea() {
        promptsSuggest.removeAll()
    }
}

