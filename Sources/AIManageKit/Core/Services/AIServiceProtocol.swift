//
//  AIServiceProtocol.swift
//  MyLibrary
//
//  Created by Macbook on 15/11/25.
//

import Foundation

@available(iOS 13.0, *)
// MARK: - AI Service Protocol
public protocol AIServiceProtocol: Sendable {
    func sendRequest(_ request: AIRequest, apiKey: String) async throws -> AIResponse
    nonisolated func sendStreamingRequest(_ request: AIRequest, apiKey: String) -> AsyncThrowingStream<String, Error>
    func validateAPIKey(_ key: String) async throws -> Bool
    func countTokens(_ prompt: String, apiKey: String) async throws -> Int
}

// MARK: - Request Context (for cancellation)
public final class AIRequestContext: @unchecked Sendable {
    private var isCancelled = false
    private let lock = NSLock()
    
    public init() {}
    
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
    }
    
    public var cancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }
}

@available(iOS 13.0, *)
// MARK: - Retry Strategy
public enum RetryStrategy: Sendable {
    case exponentialBackoff(maxAttempts: Int)
    case fixedDelay(attempts: Int, delay: TimeInterval)
    case none
    
    func shouldRetry(attempt: Int) -> Bool {
        switch self {
        case .exponentialBackoff(let max):
            return attempt < max
        case .fixedDelay(let attempts, _):
            return attempt < attempts
        case .none:
            return false
        }
    }
    
    func delay(for attempt: Int) async {
            switch self {
            case .exponentialBackoff:
                let delay = min(pow(2.0, Double(attempt)), 32.0)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            case .fixedDelay(_, let delay):
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            case .none:
                break
            }
        }
}
