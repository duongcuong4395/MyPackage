//
//  RetryPolicy.swift
//  MyLibrary
//
//  Created by Macbook on 8/1/26.
//

import Foundation

// MARK: - RetryPolicy

public struct RetryPolicy: Sendable {
    public var maxAttempts: Int
    public var initialDelay: TimeInterval
    public var maxDelay: TimeInterval
    public var multiplier: Double
    
    public init(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        multiplier: Double = 2.0
    ) {
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
    }
    
    public static let `default` = RetryPolicy()
    public static let aggressive = RetryPolicy(maxAttempts: 5, initialDelay: 0.5, multiplier: 1.5)
    public static let conservative = RetryPolicy(maxAttempts: 2, initialDelay: 2.0, multiplier: 3.0)
}

// MARK: - Task Extension

@available(iOS 13.0, *)
extension Task where Failure == Error {
    public static func retrying(
        policy: RetryPolicy = .default,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        var lastError: Error?
        
        for attempt in 0..<policy.maxAttempts {
            do {
                return try await operation()
            } catch is CancellationError {
                throw _Concurrency.CancellationError()
            } catch {
                lastError = error
                
                if attempt < policy.maxAttempts - 1 {
                    let delay = min(
                        policy.initialDelay * pow(policy.multiplier, Double(attempt)),
                        policy.maxDelay
                    )
                    try await Task<Never, Never>.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? StateError.unknown("Retry failed")
    }
}
