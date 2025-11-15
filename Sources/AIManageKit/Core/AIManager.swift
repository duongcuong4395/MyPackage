//
//  AIManager.swift
//  MyLibrary
//
//  Created by Macbook on 15/11/25.
//

// Sources/AIManageKit/Core/AIManager.swift

import Foundation
import Observation

// MARK: - AI Manager (Main Interface)
@available(iOS 17.0, *)
@Observable
public final class AIManager: @unchecked Sendable {
    
    // MARK: - Properties
    private let storage: AIStorageProtocol
    private let service: AIServiceProtocol
    //private let configuration: AIConfiguration
    public private(set) var configuration: AIConfiguration
    
    private var currentTask: Task<Void, Never>?
    
    public private(set) var keyStatus: AIKeyStatus = .notConfigured
    public private(set) var isLoading = false
    public private(set) var lastError: AIError?
    
    // MARK: - Initialization
    public init(
        storage: AIStorageProtocol,
        service: AIServiceProtocol,
        configuration: AIConfiguration = .default
    ) {
        self.storage = storage
        self.service = service
        self.configuration = configuration
        
        Task {
            await checkKeyStatus()
        }
    }
    
    // Convenience initializer
    public convenience init(
        useKeychain: Bool = true,
        configuration: AIConfiguration = .default
    ) {
        let storage: AIStorageProtocol = useKeychain
            ? KeychainAIStorage()
            : UserDefaultsAIStorage()
        
        let service = GeminiAIService(
            configuration: configuration,
            retryStrategy: .exponentialBackoff(maxAttempts: configuration.retryAttempts)
        )
        
        self.init(storage: storage, service: service, configuration: configuration)
    }
    
    // MARK: - Configuration Management
    public func updateConfiguration(_ newConfig: AIConfiguration) {
        Task { @MainActor in
            self.configuration = newConfig
        }
    }
    
    public func switchModel(_ model: AIModelType) {
        let newConfig = configuration.with(model: model)
        updateConfiguration(newConfig)
    }
    
    // MARK: - Key Management
    public func setAPIKey(_ key: String) async throws {
        setLoading(true)
        defer { setLoading(false) }
        
        // Validate key first
        setKeyStatus(.validating)
        
        do {
            let isValid = try await service.validateAPIKey(key)
            
            if isValid {
                try await storage.saveKey(key)
                setKeyStatus(.valid)
                clearError()
            } else {
                setKeyStatus(.invalid)
                throw AIError.keyValidationFailed("Key validation returned false")
            }
        } catch {
            setKeyStatus(.invalid)
            let aiError = error as? AIError ?? AIError.unknown(error.localizedDescription)
            setError(aiError)
            throw aiError
        }
    }
    
    public func getAPIKey() async throws -> String {
        guard let key = try await storage.getKey() else {
            throw AIError.keyNotFound
        }
        return key
    }
    
    public func deleteAPIKey() async throws {
        try await storage.deleteKey()
        setKeyStatus(.notConfigured)
    }
    
    public func hasValidKey() async -> Bool {
        await storage.keyExists()
    }
    
    private func checkKeyStatus() async {
        if await storage.keyExists() {
            setKeyStatus(.valid)
        } else {
            setKeyStatus(.notConfigured)
        }
    }
    
    // MARK: - Send Requests
    public func sendRequest(
        prompt: String,
        imageData: Data? = nil,
        configuration: AIConfiguration? = nil
    ) async throws -> AIResponse {
        
        guard let apiKey = try await storage.getKey() else {
            throw AIError.keyNotFound
        }
        
        setLoading(true)
        clearError()
        
        defer { setLoading(false) }
        
        let request = AIRequest(
            prompt: prompt,
            image: imageData,
            isStreaming: false,
            configuration: configuration ?? self.configuration
        )
        
        do {
            let response = try await service.sendRequest(request, apiKey: apiKey)
            return response
        } catch {
            let aiError = error as? AIError ?? AIError.unknown(error.localizedDescription)
            setError(aiError)
            throw aiError
        }
    }
    
    public func sendStreamingRequest(
        prompt: String,
        imageData: Data? = nil,
        configuration: AIConfiguration? = nil
    ) async throws -> AsyncThrowingStream<String, Error> {
        
        guard let apiKey = try await storage.getKey() else {
            throw AIError.keyNotFound
        }
        
        setLoading(true)
        clearError()
        
        let request = AIRequest(
            prompt: prompt,
            image: imageData,
            isStreaming: true,
            configuration: configuration ?? self.configuration
        )
        
        let stream = service.sendStreamingRequest(request, apiKey: apiKey)
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await chunk in stream {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                    setLoading(false)
                } catch {
                    let aiError = error as? AIError ?? AIError.unknown(error.localizedDescription)
                    setError(aiError)
                    continuation.finish(throwing: aiError)
                    setLoading(false)
                }
            }
        }
    }
    
    // MARK: - Token Counting
    public func countTokens(for prompt: String) async throws -> Int {
        guard let apiKey = try await storage.getKey() else {
            throw AIError.keyNotFound
        }
        
        return try await service.countTokens(prompt, apiKey: apiKey)
    }
    
    // MARK: - Cancellation
    public func cancelCurrentRequest() {
        currentTask?.cancel()
        currentTask = nil
        setLoading(false)
    }
    
    // MARK: - Private State Updates (Thread-safe)
    private func setLoading(_ value: Bool) {
        Task { @MainActor in
            self.isLoading = value
        }
    }
    
    private func setKeyStatus(_ status: AIKeyStatus) {
        Task { @MainActor in
            self.keyStatus = status
        }
    }
    
    private func setError(_ error: AIError) {
        Task { @MainActor in
            self.lastError = error
        }
    }
    
    private func clearError() {
        Task { @MainActor in
            self.lastError = nil
        }
    }
}

@available(iOS 17.0, *)
// MARK: - Convenience Extensions
extension AIManager {
    public func quickSend(_ prompt: String) async throws -> String {
        let response = try await sendRequest(prompt: prompt)
        return response.text
    }
    
    public func quickStream(_ prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        try await sendStreamingRequest(prompt: prompt)
    }
}
