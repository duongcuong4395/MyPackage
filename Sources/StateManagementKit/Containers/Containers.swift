//
//  Containers.swift
//  MyLibrary
//
//  Created by Macbook on 8/1/26.
//

import SwiftUI

// MARK: - SingleStateContainer

@available(iOS 13.0, *)
@MainActor
open class SingleStateContainer<Model: Equatable & Sendable>: ObservableObject {
    
    @Published public var store: SingleStateStore<Model>
    
    public init(config: StateConfiguration = .default) {
        self.store = SingleStateStore<Model>(config: config)
    }
    
    public func load(
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable () async throws -> Model
    ) async {
        await store.load(retryPolicy: retryPolicy, operation: operation)
    }
    
    public func update<Value: Sendable>(
        keyPath: WritableKeyPath<Model, Value> & Sendable,
        value: Value
    ) {
        store.update(keyPath: keyPath, value: value)
    }
    
    public func batchUpdate(_ builder: (inout UpdateBuilder<Model>) -> Void) {
        store.batchUpdate(builder)
    }
    
    public var model: Model? { store.currentModel }
    public func commit() { store.commitMutation() }
    public func discard() { store.discardMutation() }
}

// MARK: - StateContainer

@available(iOS 13.0, *)
@MainActor
open class StateContainer<Model: Identifiable & Equatable & Sendable>: ObservableObject where Model.ID: Hashable & Sendable {
    
    @Published public var store: StateStore<Model>
    
    public init(config: StateConfiguration = .default) {
        self.store = StateStore<Model>(config: config)
    }
    
    public func loadPage(
        page: Int = 0,
        append: Bool = false,
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable (Int, Int) async throws -> [Model]
    ) async {
        await store.loadPage(page: page, append: append, retryPolicy: retryPolicy, operation: operation)
    }
    
    public func loadNextPage(
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable (Int, Int) async throws -> [Model]
    ) async {
        await store.loadNextPage(retryPolicy: retryPolicy, operation: operation)
    }
    
    public func refresh(
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable (Int, Int) async throws -> [Model]
    ) async {
        await store.refresh(retryPolicy: retryPolicy, operation: operation)
    }
    
    public func update<Value: Sendable>(
        _ id: Model.ID,
        keyPath: WritableKeyPath<Model, Value> & Sendable,
        value: Value
    ) {
        store.update(id, keyPath: keyPath, value: value)
    }
    
    public func batchUpdate(_ id: Model.ID, _ builder: (inout UpdateBuilder<Model>) -> Void) {
        store.batchUpdate(id, builder)
    }
    
    public func model(withId id: Model.ID) -> Model? { store.model(withId: id) }
    public func allModels() -> [Model] { store.allModels() }
    public func commit() { store.commitMutations() }
    public func discard() { store.discardMutations() }
}
