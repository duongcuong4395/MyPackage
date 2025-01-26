//
//  GeminiAIEvent.swift
//  MyLibrary
//
//  Created by Macbook on 22/1/25.
//

import GoogleGenerativeAI
import CoreData
import SwiftUI



// MARK: - For Event
@available(iOS 15.0, *)
public protocol GeminiAIEvent {
    func getKey() async -> (exists: Bool, model: GeminiAIModel)
}

@available(iOS 15.0, *)
public extension GeminiAIEvent {
    func getModel(with model: GeminiAIModel, and version: GeminiAIVersion) -> GenerativeModel {
        return GenerativeModel(
            name: version.rawValue,
          // "gemini-1.5-flash-latest", // "gemini-1.5-pro-latest", // "gemini-1.5-flash-latest",
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
    
    func checKeyExist(with version: GeminiAIVersion) async -> Bool {
        let (_, status, _) = await GeminiSend(prompt: "Test prompt", and: true, with: version)
        switch status {
        case .NotExistsKey, .ExistsKey, .SendReqestFail:
            return false
        case .Success:
            return true
        }
    }
    
    // MARK: - New
    func GeminiSend(prompt: String
                    , and image: UIImage
                    , with version: GeminiAIVersion
    ) async -> String {
        let modelKey = await getKey()
        guard modelKey.exists else { return "" }
        let model = getModel(with: modelKey.model, and: version)
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
    
    func GeminiSend(prompt: String
                    , with hasStream: Bool
                    , and version: GeminiAIVersion
    ) async -> GeminiResponse {
        
        let modelKey = await getKey()
        guard modelKey.exists else { return GeminiResponse(text: "", status: .NotExistsKey)}
        let model = getModel(with: modelKey.model, and: version)
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
                return GeminiResponse(text: result, status: .Success)
            } else {
                let response = try await chat.sendMessage(prompt)
                let _ = try await model.countTokens(prompt)
                return GeminiResponse(text: response.text ?? "Empty", status: .Success)
            }
        } catch {
            return GeminiResponse(text: "Data not found", status: .SendReqestFail)
        }
    }
    
    func GeminiSend(prompt: String, and hasStream: Bool
                    , with version: GeminiAIVersion
    ) async -> (String, GeminiStatus, String) {
        let modelKey = await getKey()
        guard modelKey.exists else { return ("", .NotExistsKey, "") }
        
        let model = getModel(with: modelKey.model, and: version)
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
