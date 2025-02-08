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
public protocol ChatSession {
    var chat: Chat? { get set }
    func initializeChat(for schema: Schema?)
    func getKey() -> GeminiAI.GeminiAIModel
    func getModel(with model: GeminiAIModel, and version: GeminiAIVersion, and schema: Schema?) -> GenerativeModel
}

@available(iOS 16.0, *)
public extension ChatSession {
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
public protocol ChatMessaging {
    var inputText: String { get set }
    var messages: [ChatMessage] { get set }
    func sendTextMessage(_ prompt: String, hasStream: Bool) async
    func sendMessage(with prompt: String, and images: [UIImage], hasStream: Bool, versionAI: GeminiAIVersion) async throws
}

@available(iOS 16.0, *)
public protocol ChatImageHandling {
    var imagesSelected: [UIImage] { get set }
    func remove(image: UIImage)
}

@available(iOS 16.0, *)
public protocol ChatHistory {
    var history: [ModelContent] { get set }
    func resetHistory()
    func addChatHistory(by message: ChatMessage)
}

@available(iOS 16.0, *)
public protocol ChatSuggestions {
    var promptsSuggest: [String] { get set }
    func aiSendSuggestIdea() async
    func resetSuggestIdea()
}

