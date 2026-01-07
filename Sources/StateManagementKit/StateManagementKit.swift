//
//  StateManagementKit.swift
//  FootballDt
//
//  Created by Macbook on 2/1/26.
//

//
//  AsyncState.swift
//  StateManagementKit
//
//  Generic async state with optimistic updates support
//

import Foundation

/// Generic async state with optimistic updates support
@frozen
public enum AsyncState<T> {
    case idle
    case loading(previous: T? = nil)
    case success(T)
    case failure(StateError, previous: T? = nil)
    
    /// Returns the current data, considering previous data during loading/error states
    public var data: T? {
        switch self {
        case .idle:
            return nil
        case .loading(let previous):
            return previous
        case .success(let data):
            return data
        case .failure(_, let previous):
            return previous
        }
    }
    
    /// Indicates if the state is currently loading
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    /// Indicates if the state is in success
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    /// Returns the error if state is failure
    public var error: StateError? {
        if case .failure(let error, _) = self { return error }
        return nil
    }
    
    /// Maps the success value to a new type
    public func map<U>(_ transform: (T) -> U) -> AsyncState<U> {
        switch self {
        case .idle:
            return .idle
        case .loading(let previous):
            return .loading(previous: previous.map(transform))
        case .success(let data):
            return .success(transform(data))
        case .failure(let error, let previous):
            return .failure(error, previous: previous.map(transform))
        }
    }
}

// MARK: - Equatable Conformance
extension AsyncState: Equatable where T: Equatable {
    public static func == (lhs: AsyncState<T>, rhs: AsyncState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading(let lhsPrev), .loading(let rhsPrev)):
            return lhsPrev == rhsPrev
        case (.success(let lhsData), .success(let rhsData)):
            return lhsData == rhsData
        case (.failure(let lhsError, let lhsPrev), .failure(let rhsError, let rhsPrev)):
            return lhsError == rhsError && lhsPrev == rhsPrev
        default:
            return false
        }
    }
}

// MARK: - Sendable Conformance
extension AsyncState: Sendable where T: Sendable {}

//
//  StateError.swift
//  StateManagementKit
//
//  Type-safe state errors
//

import Foundation

/// Type-safe state errors with common error cases
public enum StateError: Error, Equatable, Sendable {
    case network(String)
    case decode(String)
    case notFound
    case unauthorized
    case cancelled
    case timeout
    case invalidInput(String)
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .network(let msg):
            return "Network error: \(msg)"
        case .decode(let msg):
            return "Decode error: \(msg)"
        case .notFound:
            return "Resource not found"
        case .unauthorized:
            return "Unauthorized access"
        case .cancelled:
            return "Operation cancelled"
        case .timeout:
            return "Request timeout"
        case .invalidInput(let msg):
            return "Invalid input: \(msg)"
        case .unknown(let msg):
            return msg
        }
    }
    
    /// Check if error is recoverable
    public var isRecoverable: Bool {
        switch self {
        case .network, .timeout, .unknown:
            return true
        case .cancelled, .unauthorized, .notFound, .decode, .invalidInput:
            return false
        }
    }
}

//
//  StateConfiguration.swift
//  StateManagementKit
//
//  Configuration for state management behavior
//

import Foundation

/// Configuration for state management
public struct StateConfiguration: Sendable {
    /// Debounce interval for state updates (in seconds)
    public var debounceInterval: TimeInterval
    
    /// Maximum number of undo steps to keep in memory
    public var maxUndoSteps: Int
    
    /// Enable debug logging
    public var enableLogging: Bool
    
    /// Default page size for pagination
    public var pageSize: Int
    
    /// Timeout for async operations (in seconds)
    public var operationTimeout: TimeInterval
    
    public init(
        debounceInterval: TimeInterval = 0.05,
        maxUndoSteps: Int = 50,
        enableLogging: Bool = false,
        pageSize: Int = 20,
        operationTimeout: TimeInterval = 30
    ) {
        self.debounceInterval = debounceInterval
        self.maxUndoSteps = maxUndoSteps
        self.enableLogging = enableLogging
        self.pageSize = pageSize
        self.operationTimeout = operationTimeout
    }
    
    /// Default configuration
    public static let `default` = StateConfiguration()
    
    /// Configuration optimized for testing
    public static let testing = StateConfiguration(
        debounceInterval: 0,
        maxUndoSteps: 10,
        enableLogging: true,
        pageSize: 10,
        operationTimeout: 5
    )
    
    /// Configuration for production use
    public static let production = StateConfiguration(
        debounceInterval: 0.1,
        maxUndoSteps: 100,
        enableLogging: false,
        pageSize: 50,
        operationTimeout: 60
    )
}

//
//  TypeSafeMutation.swift
//  StateManagementKit
//
//  Type-safe mutation system that prevents runtime crashes
//

import Foundation

/// Type-safe mutation that prevents runtime crashes
public struct TypeSafeMutation<Model: Equatable> {
    private let transform: (Model) -> Model
    
    /// Creates a new type-safe mutation
    /// - Parameter transform: The transformation function to apply to the model
    public init(_ transform: @escaping (Model) -> Model) {
        self.transform = transform
    }
    
    /// Applies the mutation to a model
    /// - Parameter model: The model to mutate
    /// - Returns: The mutated model
    public func apply(to model: Model) -> Model {
        transform(model)
    }
    
    /// Merges this mutation with another mutation
    /// - Parameter other: The mutation to merge with
    /// - Returns: A new mutation that applies both transformations
    public func merge(with other: TypeSafeMutation<Model>) -> TypeSafeMutation<Model> {
        TypeSafeMutation { model in
            other.apply(to: self.apply(to: model))
        }
    }
}

// MARK: - Convenience Initializers

extension TypeSafeMutation {
    /// Creates a mutation that updates a single keypath
    public static func set<Value>(
        _ keyPath: WritableKeyPath<Model, Value>,
        to value: Value
    ) -> TypeSafeMutation<Model> {
        TypeSafeMutation { model in
            var mutableModel = model
            mutableModel[keyPath: keyPath] = value
            return mutableModel
        }
    }
    
    /// Creates a mutation from an inout closure
    public static func modify(
        _ transform: @escaping (inout Model) -> Void
    ) -> TypeSafeMutation<Model> {
        TypeSafeMutation { model in
            var mutableModel = model
            transform(&mutableModel)
            return mutableModel
        }
    }
}


//
//  UpdateBuilder.swift
//  StateManagementKit
//
//  Type-safe update builder for batch mutations
//

import Foundation

/// Type-safe update builder for batch mutations
public struct UpdateBuilder<Model> {
    private var mutations: [(inout Model) -> Void] = []
    
    public init() {}
    
    /// Sets a value at a specific keypath
    /// - Parameters:
    ///   - keyPath: The keypath to update
    ///   - value: The new value
    public mutating func set<Value>(
        _ keyPath: WritableKeyPath<Model, Value>,
        to value: Value
    ) {
        mutations.append { model in
            model[keyPath: keyPath] = value
        }
    }
    
    /// Applies a custom transformation
    /// - Parameter transform: The transformation to apply
    public mutating func apply(_ transform: @escaping (inout Model) -> Void) {
        mutations.append(transform)
    }
    
    /// Conditionally applies a mutation
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - mutation: The mutation to apply if condition is true
    public mutating func `if`(_ condition: Bool, _ mutation: (inout UpdateBuilder<Model>) -> Void) {
        if condition {
            mutation(&self)
        }
    }
    
    /// Builds the final mutation function
    /// - Returns: A function that applies all accumulated mutations
    public func build() -> (inout Model) -> Void {
        return { model in
            for mutation in self.mutations {
                mutation(&model)
            }
        }
    }
    
    /// Builds a TypeSafeMutation
    /// - Returns: A TypeSafeMutation that applies all accumulated mutations
    public func buildMutation() -> TypeSafeMutation<Model> where Model: Equatable {
        let transform = build()
        return TypeSafeMutation { model in
            var mutableModel = model
            transform(&mutableModel)
            return mutableModel
        }
    }
}

// MARK: - DSL Support

extension UpdateBuilder {
    /// Creates an UpdateBuilder using a result builder syntax
    public static func build(@UpdateBuilderDSL _ content: (inout UpdateBuilder<Model>) -> Void) -> UpdateBuilder<Model> {
        var builder = UpdateBuilder<Model>()
        content(&builder)
        return builder
    }
}

@resultBuilder
public struct UpdateBuilderDSL {
    public static func buildBlock() -> [(inout Any) -> Void] {
        []
    }
}
