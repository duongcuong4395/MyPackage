//
//  StateCore.swift
//  MyLibrary
//
//  Created by Macbook on 14/1/26.
//

import Foundation

// MARK: CoreTypes.swift

// MARK: - AsyncState

/// Generic async state with optimistic updates support
@frozen
public enum AsyncState<T>: @unchecked Sendable {
    case idle
    case loading(previous: T? = nil)
    case success(T)
    case failure(StateError, previous: T? = nil)
    
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
    
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    public var error: StateError? {
        if case .failure(let error, _) = self { return error }
        return nil
    }
    
    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
    
    public var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

// MARK: - StateError

/// Type-safe state errors
public enum StateError: Error, Equatable, Sendable {
    case network(String)
    case decode(String)
    case notFound
    case unauthorized
    case cancelled
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
        case .unknown(let msg):
            return msg
        }
    }
}

// MARK: - StateConfiguration

/// Configuration for state management
public struct StateConfiguration: Sendable {
    public var debounceInterval: TimeInterval
    public var maxUndoSteps: Int
    public var enableLogging: Bool
    public var pageSize: Int
    
    public init(
        debounceInterval: TimeInterval = 0.05,
        maxUndoSteps: Int = 50,
        enableLogging: Bool = false,
        pageSize: Int = 20
    ) {
        self.debounceInterval = debounceInterval
        self.maxUndoSteps = maxUndoSteps
        self.enableLogging = enableLogging
        self.pageSize = pageSize
    }
    
    public static let `default` = StateConfiguration()
}



// MARK: MutationSystem.swift

// MARK: - TypeSafeMutation

/// Type-safe mutation that prevents runtime crashes
public struct TypeSafeMutation<Model: Equatable>: @unchecked Sendable {
    private let transform: @Sendable (Model) -> Model
    
    public init(_ transform: @escaping @Sendable (Model) -> Model) {
        self.transform = transform
    }
    
    public func apply(to model: Model) -> Model {
        transform(model)
    }
    
    public func merge(with other: TypeSafeMutation<Model>) -> TypeSafeMutation<Model> {
        TypeSafeMutation { model in
            other.apply(to: self.apply(to: model))
        }
    }
}

// MARK: - UpdateBuilder

/// Type-safe update builder
public struct UpdateBuilder<Model>: Sendable{
    private var mutations: [@Sendable (inout Model) -> Void] = []
    
    public init() {}
    
    public mutating func set<Value>(
        _ keyPath: WritableKeyPath<Model, Value> & Sendable,
        to value: Value
    ) where Value: Sendable {
        mutations.append { model in
            model[keyPath: keyPath] = value
        }
    }
    
    public mutating func apply(_ transform: @escaping @Sendable (inout Model) -> Void) {
        mutations.append(transform)
    }
    
    public func build() -> @Sendable (inout Model) -> Void {
        return { model in
            for mutation in self.mutations {
                mutation(&model)
            }
        }
    }
}
