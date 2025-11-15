//
//  GeminiAIService.swift
//  MyLibrary
//
//  Created by Macbook on 15/11/25.
//

import Foundation
@preconcurrency import GoogleGenerativeAI

#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, *)
// MARK: - Gemini AI Service Implementation
public actor GeminiAIService: AIServiceProtocol {
    private let configuration: AIConfiguration
    private let retryStrategy: RetryStrategy
    
    public init(
        configuration: AIConfiguration = .default,
        retryStrategy: RetryStrategy = .exponentialBackoff(maxAttempts: 3)
    ) {
        self.configuration = configuration
        self.retryStrategy = retryStrategy
    }
    
    // MARK: - Send Request
    public func sendRequest(_ request: AIRequest, apiKey: String) async throws -> AIResponse {
        let model = createModel(apiKey: apiKey, config: request.configuration)
        
        var attempt = 0
        var lastError: Error?
        
        while retryStrategy.shouldRetry(attempt: attempt) {
            do {
                let result: GenerateContentResponse
                
                if let imageData = request.image {
                    #if canImport(UIKit)
                    guard let image = UIImage(data: imageData) else {
                        throw AIError.requestFailed("Invalid image data")
                    }
                    result = try await withTimeout(seconds: request.configuration.timeout) {
                        try await model.generateContent(request.prompt, image)
                    }
                    #else
                    throw AIError.requestFailed("Image processing not supported on this platform")
                    #endif
                } else {
                    result = try await withTimeout(seconds: request.configuration.timeout) {
                        try await model.generateContent(request.prompt)
                    }
                }
                
                guard let text = result.text else {
                    throw AIError.requestFailed("Empty response")
                }
                
                return AIResponse(
                    text: text,
                    tokenCount: nil,
                    finishReason: mapFinishReason(result)
                )
                
            } catch let error as AIError {
                throw error
            } catch {
                lastError = error
                attempt += 1
                
                if retryStrategy.shouldRetry(attempt: attempt) {
                    await retryStrategy.delay(for: attempt)
                } else {
                    throw mapError(error)
                }
            }
        }
        
        throw lastError.map(mapError) ?? AIError.unknown("Request failed after retries")
    }
    
    // MARK: - Streaming Request
    nonisolated public func sendStreamingRequest(_ request: AIRequest, apiKey: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let model = await self.createModel(apiKey: apiKey, config: request.configuration)
                    
                    let stream: AsyncThrowingStream<GenerateContentResponse, Error>
                    
                    if let imageData = request.image {
                        #if canImport(UIKit)
                        guard let image = UIImage(data: imageData) else {
                            throw AIError.requestFailed("Invalid image data")
                        }
                        stream = model.generateContentStream(request.prompt, image)
                        #else
                        throw AIError.requestFailed("Image processing not supported")
                        #endif
                    } else {
                        stream = model.generateContentStream(request.prompt)
                    }
                    
                    for try await chunk in stream {
                        if let text = chunk.text {
                            continuation.yield(text)
                        }
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: await self.mapError(error))
                }
            }
        }
    }
    
    // MARK: - Validate API Key
    public func validateAPIKey(_ key: String) async throws -> Bool {
        let testRequest = AIRequest(
            prompt: "Say 'OK'",
            configuration: AIConfiguration(maxOutputTokens: 10, timeout: 10, retryAttempts: 1)
        )
        
        do {
            _ = try await sendRequest(testRequest, apiKey: key)
            return true
        } catch {
            throw mapError(error)
        }
    }
    
    // MARK: - Count Tokens
    public func countTokens(_ prompt: String, apiKey: String) async throws -> Int {
        let model = createModel(apiKey: apiKey, config: configuration)
        let response = try await model.countTokens(prompt)
        return response.totalTokens
    }
    
    // MARK: - Private Helpers
    private func createModel(apiKey: String, config: AIConfiguration) -> GenerativeModel {
        GenerativeModel(
            name: config.model.identifier,
            apiKey: apiKey,
            generationConfig: GenerationConfig(
                temperature: config.temperature,
                topP: config.topP,
                topK: config.topK,
                maxOutputTokens: config.maxOutputTokens,
                responseMIMEType: "text/plain"
            ),
            safetySettings: config.safetySettings.map { setting in
                SafetySetting(
                    harmCategory: mapSafetyCategory(setting.category),
                    threshold: mapSafetyThreshold(setting.threshold)
                )
            }
        )
    }
    
    private func mapSafetyCategory(_ category: AISafetySetting.SafetyCategory) -> SafetySetting.HarmCategory {
        switch category {
        case .harassment: return .harassment
        case .hateSpeech: return .hateSpeech
        case .sexuallyExplicit: return .sexuallyExplicit
        case .dangerousContent: return .dangerousContent
        }
    }
    
    // HarmBlockThreshold
    private func mapSafetyThreshold(_ threshold: AISafetySetting.SafetyThreshold) ->  SafetySetting.BlockThreshold {
        switch threshold {
        case .blockNone: return .blockNone
        case .blockLowAndAbove: return .blockLowAndAbove
        case .blockMediumAndAbove: return .blockMediumAndAbove
        case .blockHighOnly: return .blockOnlyHigh
        }
    }
    
    private func mapFinishReason(_ response: GenerateContentResponse) -> AIResponse.FinishReason? {
        guard let candidate = response.candidates.first else { return nil }
        
        switch candidate.finishReason {
        case .stop: return .stop
        case .maxTokens: return .maxTokens
        case .safety: return .safety
        case .recitation: return .recitation
        default: return .other
        }
    }
    
    private func mapError(_ error: Error) -> AIError {
        if let genError = error as? GenerateContentError {
            switch genError {
            case .invalidAPIKey:
                return .invalidAPIKey
            case .promptBlocked:
                return .contentFiltered
            case .internalError(let underlying):
                return .requestFailed(underlying.localizedDescription)
            default:
                return .requestFailed(genError.localizedDescription)
            }
        }
        
        if let aiError = error as? AIError {
            return aiError
        }
        
        let nsError = error as NSError
        if nsError.code == NSURLErrorTimedOut {
            return .timeout
        }
        
        return .unknown(error.localizedDescription)
    }
    
    nonisolated private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AIError.timeout
            }
            
            guard let result = try await group.next() else {
                throw AIError.unknown("Task group returned nil")
            }
            
            group.cancelAll()
            return result
        }
    }
}
