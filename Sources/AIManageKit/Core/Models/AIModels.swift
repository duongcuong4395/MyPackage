//
//  AIModels.swift
//  MyLibrary
//
//  Created by Macbook on 15/11/25.
//

import Foundation

// MARK: - AI Configuration
public struct AIConfiguration: Sendable {
    public let model: AIModelType
    public let temperature: Float
    public let topP: Float
    public let topK: Int
    public let maxOutputTokens: Int
    public let timeout: TimeInterval
    public let retryAttempts: Int
    public let safetySettings: [AISafetySetting]
    
    public init(
        model: AIModelType = .gemini25Flash,
        temperature: Float = 1.0,
        topP: Float = 0.95,
        topK: Int = 64,
        maxOutputTokens: Int = 8192,
        timeout: TimeInterval = 60,
        retryAttempts: Int = 3,
        safetySettings: [AISafetySetting] = AISafetySetting.defaultSettings
    ) {
        self.model = model
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.maxOutputTokens = maxOutputTokens
        self.timeout = timeout
        self.retryAttempts = retryAttempts
        self.safetySettings = safetySettings
    }
    
    public static let `default` = AIConfiguration()
    
    // Convenience method to change model
    public func with(model: AIModelType) -> AIConfiguration {
        AIConfiguration(
            model: model,
            temperature: temperature,
            topP: topP,
            topK: topK,
            maxOutputTokens: maxOutputTokens,
            timeout: timeout,
            retryAttempts: retryAttempts,
            safetySettings: safetySettings
        )
    }
}

// MARK: - AI Model Types
public struct AIModelType: Sendable, Hashable, Codable {
    public let identifier: String
    public let displayName: String
    public let description: String?
    
    public init(identifier: String, displayName: String? = nil, description: String? = nil) {
        self.identifier = identifier
        self.displayName = displayName ?? identifier
        self.description = description
    }
    
    // MARK: - Predefined Models
    public static let gemini25Flash = AIModelType(
        identifier: "gemini-2.5-flash",
        displayName: "Gemini 2.5 Flash",
        description: "Latest fast model with multimodal capabilities"
    )
    
    public static let gemini15Flash = AIModelType(
        identifier: "gemini-1.5-flash",
        displayName: "Gemini 1.5 Flash",
        description: "Fast and efficient for everyday tasks"
    )
    
    public static let gemini15Pro = AIModelType(
        identifier: "gemini-1.5-pro",
        displayName: "Gemini 1.5 Pro",
        description: "Most capable model for complex tasks"
    )
    
    public static let gemini2Flash = AIModelType(
        identifier: "gemini-2.0-flash-exp",
        displayName: "Gemini 2.0 Flash (Experimental)",
        description: "Experimental version with latest features"
    )
    
    // MARK: - All Available Models
    public static let allPredefined: [AIModelType] = [
        .gemini25Flash,
        .gemini2Flash,
        .gemini15Flash,
        .gemini15Pro
    ]
    
    // MARK: - Custom Model Creation
    public static func custom(identifier: String, displayName: String? = nil) -> AIModelType {
        AIModelType(identifier: identifier, displayName: displayName)
    }
}

// MARK: - Safety Settings
public struct AISafetySetting: Sendable {
    public let category: SafetyCategory
    public let threshold: SafetyThreshold
    
    public init(category: SafetyCategory, threshold: SafetyThreshold) {
        self.category = category
        self.threshold = threshold
    }
    
    public enum SafetyCategory: String, Sendable {
        case harassment
        case hateSpeech
        case sexuallyExplicit
        case dangerousContent
    }
    
    public enum SafetyThreshold: String, Sendable {
        case blockNone
        case blockLowAndAbove
        case blockMediumAndAbove
        case blockHighOnly
    }
    
    public static let defaultSettings: [AISafetySetting] = [
        .init(category: .harassment, threshold: .blockMediumAndAbove),
        .init(category: .hateSpeech, threshold: .blockMediumAndAbove),
        .init(category: .sexuallyExplicit, threshold: .blockMediumAndAbove),
        .init(category: .dangerousContent, threshold: .blockMediumAndAbove)
    ]
}

// MARK: - AI Request
public struct AIRequest: Sendable {
    public let prompt: String
    public let image: Data?
    public let isStreaming: Bool
    public let configuration: AIConfiguration
    
    public init(
        prompt: String,
        image: Data? = nil,
        isStreaming: Bool = false,
        configuration: AIConfiguration = .default
    ) {
        self.prompt = prompt
        self.image = image
        self.isStreaming = isStreaming
        self.configuration = configuration
    }
}

// MARK: - AI Response
public struct AIResponse: Sendable {
    public let text: String
    public let tokenCount: Int?
    public let finishReason: FinishReason?
    
    public enum FinishReason: String, Sendable {
        case stop
        case maxTokens
        case safety
        case recitation
        case other
    }
    
    public init(text: String, tokenCount: Int? = nil, finishReason: FinishReason? = nil) {
        self.text = text
        self.tokenCount = tokenCount
        self.finishReason = finishReason
    }
}

// MARK: - AI Error
public enum AIError: LocalizedError, Sendable {
    case invalidAPIKey
    case keyNotFound
    case keyValidationFailed(String)
    case requestFailed(String)
    case timeout
    case rateLimitExceeded
    case contentFiltered
    case networkError(String)
    case storageError(String)
    case cancelled
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "API key is invalid. Please check your key."
        case .keyNotFound:
            return "API key not found. Please add a valid key."
        case .keyValidationFailed(let message):
            return "Key validation failed: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .timeout:
            return "Request timeout. Please try again."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait and try again."
        case .contentFiltered:
            return "Content filtered by safety settings."
        case .networkError(let message):
            return "Network error: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .cancelled:
            return "Request was cancelled."
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Key Status
public enum AIKeyStatus: Sendable {
    case notConfigured
    case valid
    case invalid
    case validating
}
