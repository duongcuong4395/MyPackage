//
//  GeminiAIModel.swift
//  MyLibrary
//
//  Created by Macbook on 22/1/25.
//

import Foundation
import GoogleGenerativeAI
import CoreData
import SwiftUI

// MARK: - Gemini Status
public enum GeminiStatus {
    case NotExistsKey
    case ExistsKey
    case SendReqestFail
    case Success
}

// MARK: - For model
public struct GeminiAIModel: Codable {
    public var itemKey: String
    public var valueItem: String
    
    enum CodingKeys: String, CodingKey {
        case itemKey = "itemKey"
        case valueItem = "valueItem"
    }
    
    init() {
        self.itemKey = ""
        self.valueItem = ""
    }
    
    init(itemKey: String, valueItem: String) {
        self.itemKey = itemKey
        self.valueItem = valueItem
    }
}

// MARK: - For Event
@available(iOS 15.0, *)
protocol GeminiAIEvent {
    func getKey() async -> (exists: Bool, model: GeminiAIModel)
}

@available(iOS 15.0, *)
extension GeminiAIEvent {
    public func getModel(with model: GeminiAIModel) -> GenerativeModel {
        return GenerativeModel(
          name:   "gemini-1.5-flash-latest", // "gemini-1.5-pro-latest", // "gemini-1.5-flash-latest",
          apiKey:  model.valueItem,
          generationConfig: GenerationConfig(
            temperature: 1,
            topP: 0.95,
            topK: 64,
            maxOutputTokens: 1048576, //8192,
            responseMIMEType: "text/plain"
          ),
          safetySettings: [
            SafetySetting(harmCategory: .harassment, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .hateSpeech, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .dangerousContent, threshold: .blockMediumAndAbove)
          ]
        )
    }
    
    public func checKeyExist() async -> Bool {
        let (_, status, _) = await GeminiSend(prompt: "Test prompt", and: true)
        switch status {
        case .NotExistsKey, .ExistsKey, .SendReqestFail:
            return false
        case .Success:
            return true
        }
    }
    
    // MARK: - New
    public func GeminiSend(prompt: String
                    , and image: UIImage
                    , withKeyFrom keyString: String
    ) async -> String {
        let modelKey = GeminiAIModel(itemKey: "key", valueItem: keyString)
        let model = getModel(with: modelKey)
        let _ = model.startChat(history: [])

        do {
            let contentStream = model.generateContentStream(prompt, image)
            var result = ""

            for try await chunk in contentStream {
                if let text = chunk.text {
                    result += text
                }
            }
            return result
        } catch {
            return "Data not found"
        }
    }
    
    public func GeminiSend(prompt: String
                    , and hasStream: Bool
    ) async -> (String, GeminiStatus) {
        
        let modelKey = await getKey()
        guard modelKey.exists else { return ("", .NotExistsKey)}
        let model = getModel(with: modelKey.model)
        let chat = model.startChat(history: [])

        do {
            if hasStream {
                var result = ""
                let responseStream = chat.sendMessageStream(prompt)
                for try await chunk in responseStream {
                    if let text = chunk.text {
                        result += text
                    }
                }
                return (result, .Success)
            } else {
                let response = try await chat.sendMessage(prompt)
                let _ = try await model.countTokens(prompt)
                return (response.text ?? "Empty", .Success)
            }
        } catch {
            return ("Data not found", .SendReqestFail)
        }
    }
    
    public func GeminiSend(prompt: String, and hasStream: Bool) async -> (String, GeminiStatus, String) {
        let modelKey = await getKey()
        guard modelKey.exists else { return ("", .NotExistsKey, "") }
        
        let model = getModel(with: modelKey.model)
        let chat = model.startChat(history: [])
        
        do {
            if hasStream {
                var result = ""
                let responseStream = chat.sendMessageStream(prompt)
                for try await chunk in responseStream {
                    if let text = chunk.text {
                        result += text
                    }
                }
                return (result, .Success, modelKey.model.valueItem)
            } else {
                let response = try await chat.sendMessage(prompt)
                let _ = try await model.countTokens(prompt)
                return (response.text ?? "Empty", .Success, modelKey.model.valueItem)
            }
        } catch {
            return ("Data not found", .SendReqestFail, "")
        }
    }

}
