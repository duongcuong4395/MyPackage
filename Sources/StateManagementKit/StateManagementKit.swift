//
//  StateManagementKit.swift
//  FootballDt
//
//  Created by Macbook on 2/1/26.
//

//
//  CoreTypes.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

import Foundation

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

//
//  MutationSystem.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

import Foundation

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

//
//  CircularBuffer.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

import Foundation

/// Circular buffer for undo/redo to prevent memory leaks
internal struct CircularBuffer<T> {
    private var buffer: [T]
    private let capacity: Int
    private var startIndex = 0
    private var count = 0
    
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = []
        self.buffer.reserveCapacity(capacity)
    }
    
    mutating func append(_ element: T) {
        if count < capacity {
            buffer.append(element)
            count += 1
        } else {
            buffer[startIndex] = element
            startIndex = (startIndex + 1) % capacity
        }
    }
    
    mutating func removeLast() -> T? {
        guard count > 0 else { return nil }
        count -= 1
        let index = (startIndex + count) % capacity
        return buffer[index]
    }
    
    mutating func removeAll() {
        buffer.removeAll(keepingCapacity: true)
        count = 0
        startIndex = 0
    }
    
    var isEmpty: Bool { count == 0 }
    var isFull: Bool { count == capacity }
}


//
//  TaskManager.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

import Foundation

/// Manages async tasks with automatic cancellation
@available(iOS 13.0, *)
//@MainActor
public final class TaskManager: Sendable {
    private let tasks: TaskStorage
    
    public init() {
        self.tasks = TaskStorage()
    }
    
    public func run(
        id: String,
        priority: TaskPriority = .userInitiated,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        cancel(id: id)
        
        let task = Task(priority: priority) { [tasks] in
            defer {
                Task { @MainActor in
                    tasks.remove(id: id)
                }
            }
            
            do {
                try await operation()
            } catch is CancellationError {
                // Silently handle cancellation
            } catch {
                // Log error if needed
                #if DEBUG
                print("TaskManager error for '\(id)': \(error.localizedDescription)")
                #endif
            }
        }
        
        tasks.set(task, for: id)
    }
    
    public func cancel(id: String) {
        tasks.cancel(id: id)
    }
    
    public func cancelAll() {
        tasks.cancelAll()
    }
    
    deinit {
        Task { @MainActor [tasks] in
            tasks.cancelAll()
        }
    }
}

// MARK: - TaskStorage

@available(iOS 13.0, *)
private final class TaskStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Task<Void, Never>] = [:]
    
    func set(_ task: Task<Void, Never>, for id: String) {
        lock.lock()
        defer { lock.unlock() }
        storage[id] = task
    }
    
    func cancel(id: String) {
        lock.lock()
        let task = storage.removeValue(forKey: id)
        lock.unlock()
        task?.cancel()
    }
    
    func remove(id: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: id)
    }
    
    func cancelAll() {
        lock.lock()
        let tasks = storage.values
        storage.removeAll()
        lock.unlock()
        
        tasks.forEach { $0.cancel() }
    }
}


//
//  RetryPolicy.swift
//  StateManagementKit
//
//  Version: 2.0.0
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


//
//  Protocols.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

import Foundation

// MARK: - DataSourceProtocol

/// Protocol for data sources (mockable for testing)
@available(iOS 13.0.0, *)
public protocol DataSourceProtocol<Model>: Sendable {
    associatedtype Model: Sendable
    func fetch() async throws -> [Model]
    func fetch(page: Int, pageSize: Int) async throws -> [Model]
}

// MARK: - PersistenceProtocol

/// Protocol for persistence layer
public protocol PersistenceProtocol<Model>: Sendable {
    associatedtype Model: Codable & Sendable
    func save(_ models: [Model], key: String) throws
    func load(key: String) throws -> [Model]?
}

// MARK: - UserDefaultsPersistence

/// Default UserDefaults persistence
public struct UserDefaultsPersistence<Model: Codable & Sendable>: PersistenceProtocol {
    public init() {}
    
    public func save(_ models: [Model], key: String) throws {
        let data = try JSONEncoder().encode(models)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    public func load(key: String) throws -> [Model]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try JSONDecoder().decode([Model].self, from: data)
    }
}

//
//  SingleStateStore.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

import SwiftUI
import Combine

@available(iOS 13.0, *)
@MainActor
public final class SingleStateStore<Model: Equatable & Sendable>: ObservableObject {
    
    @Published public private(set) var state: AsyncState<Model> = .idle
    @Published public private(set) var mutation: TypeSafeMutation<Model>?
    
    private var undoBuffer: CircularBuffer<TypeSafeMutation<Model>?>
    private var redoBuffer: CircularBuffer<TypeSafeMutation<Model>?>
    private var isUndoRedoEnabled = false
    
    private let taskManager = TaskManager()
    private let config: StateConfiguration
    
    public init(config: StateConfiguration = .default) {
        self.config = config
        self.undoBuffer = CircularBuffer(capacity: config.maxUndoSteps)
        self.redoBuffer = CircularBuffer(capacity: config.maxUndoSteps)
    }
    
    // MARK: - Public API
    
    public func setState(_ newState: AsyncState<Model>) {
        state = newState
        mutation = nil
    }
    
    public var currentModel: Model? {
        guard let baseModel = state.data else { return nil }
        return mutation?.apply(to: baseModel) ?? baseModel
    }
    
    public func update<Value: Sendable>(
        keyPath: WritableKeyPath<Model, Value> & Sendable,
        value: Value
    ) {
        guard state.data != nil else { return }
        
        let newMutation = TypeSafeMutation<Model> { model in
            var mutableModel = model
            mutableModel[keyPath: keyPath] = value
            return mutableModel
        }
        
        applyMutation(newMutation)
    }
    
    public func batchUpdate(_ builder: (inout UpdateBuilder<Model>) -> Void) {
        guard state.data != nil else { return }
        
        var updateBuilder = UpdateBuilder<Model>()
        builder(&updateBuilder)
        let transform = updateBuilder.build()
        
        let newMutation = TypeSafeMutation<Model> { model in
            var mutableModel = model
            transform(&mutableModel)
            return mutableModel
        }
        
        applyMutation(newMutation)
    }
    
    private func applyMutation(_ newMutation: TypeSafeMutation<Model>) {
        if isUndoRedoEnabled {
            undoBuffer.append(mutation)
            redoBuffer.removeAll()
        }
        
        if let existingMutation = mutation {
            mutation = existingMutation.merge(with: newMutation)
        } else {
            mutation = newMutation
        }
    }
    
    public func commitMutation() {
        guard let mutatedModel = currentModel else { return }
        state = .success(mutatedModel)
        mutation = nil
        
        if isUndoRedoEnabled {
            undoBuffer.removeAll()
            redoBuffer.removeAll()
        }
    }
    
    public func discardMutation() {
        mutation = nil
    }
    
    public var hasMutation: Bool { mutation != nil }
    
    // MARK: - Undo/Redo
    
    public func enableUndoRedo() {
        isUndoRedoEnabled = true
    }
    
    public func disableUndoRedo() {
        isUndoRedoEnabled = false
        undoBuffer.removeAll()
        redoBuffer.removeAll()
    }
    
    public func undo() {
        guard isUndoRedoEnabled, !undoBuffer.isEmpty else { return }
        redoBuffer.append(mutation)
        mutation = undoBuffer.removeLast() ?? nil
    }
    
    public func redo() {
        guard isUndoRedoEnabled, !redoBuffer.isEmpty else { return }
        undoBuffer.append(mutation)
        mutation = redoBuffer.removeLast() ?? nil
    }
    
    public var canUndo: Bool { isUndoRedoEnabled && !undoBuffer.isEmpty }
    public var canRedo: Bool { isUndoRedoEnabled && !redoBuffer.isEmpty }
    
    // MARK: - Async Operations with Cancellation
    
    public func load(
        id: String = "load",
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable () async throws -> Model
    ) async {
        taskManager.cancel(id: id)
        
        state = .loading(previous: state.data)
        
        taskManager.run(id: id) { [weak self] in
            do {
                let model = try await Task.retrying(policy: retryPolicy, operation: operation)
                await MainActor.run {
                    self?.state = .success(model)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.state = .failure(.cancelled, previous: self?.state.data)
                }
            } catch {
                await MainActor.run {
                    self?.state = .failure(.unknown(error.localizedDescription), previous: self?.state.data)
                }
            }
        }
    }
    
    public func cancelLoad(id: String = "load") {
        taskManager.cancel(id: id)
    }
    
    deinit {
        Task { @MainActor [taskManager] in
            taskManager.cancelAll()
        }
    }
}


//
//  StateStore.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

import SwiftUI
import Combine

@available(iOS 13.0, *)
@MainActor
open class StateStore<Model: Identifiable & Equatable & Sendable>: ObservableObject where Model.ID: Hashable & Sendable {
    
    @Published public private(set) var state: AsyncState<[Model]> = .idle
    @Published public private(set) var stateSelected: AsyncState<Model> = .idle
    
    @Published public private(set) var mutations: [Model.ID: TypeSafeMutation<Model>] = [:]
    @Published public private(set) var currentPage = 0
    @Published public private(set) var hasMorePages = true
    
    @Published private var mutationTrigger = UUID()
    
    private var undoBuffer: CircularBuffer<[Model.ID: TypeSafeMutation<Model>]>
    private var redoBuffer: CircularBuffer<[Model.ID: TypeSafeMutation<Model>]>
    private var isUndoRedoEnabled = false
    
    private let taskManager = TaskManager()
    private let config: StateConfiguration
    private var cancellables = Set<AnyCancellable>()
    
    // Lazy computed models (no unnecessary copies)
    private var modelsCache: [Model]?
    private var cacheInvalidated = true
    
    public init(config: StateConfiguration = .default) {
        self.config = config
        self.undoBuffer = CircularBuffer(capacity: config.maxUndoSteps)
        self.redoBuffer = CircularBuffer(capacity: config.maxUndoSteps)
        
        // Invalidate cache when mutations change
        $mutations.sink { [weak self] _ in
            self?.cacheInvalidated = true
        }.store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    public func setState(_ newState: AsyncState<[Model]>) {
        state = newState
        mutations.removeAll()
        cacheInvalidated = true
        currentPage = 0
        hasMorePages = true
        if case .idle = newState {
            stateSelected = .idle
        }
    }
    
    public func setStateSelected(_ newState: AsyncState<Model>) {
        stateSelected = newState
    }
    
    public func model(withId id: Model.ID) -> Model? {
        guard let baseModel = baseModel(withId: id) else { return nil }
        return mutations[id]?.apply(to: baseModel) ?? baseModel
    }
    
    public func allModels() -> [Model] {
        if !cacheInvalidated, let cached = modelsCache {
            return cached
        }
        
        guard case .success(let models) = state else { return [] }
        
        let result = models.map { model in
            mutations[model.id]?.apply(to: model) ?? model
        }
        
        modelsCache = result
        cacheInvalidated = false
        return result
    }
    
    public func update<Value: Sendable>(
        _ id: Model.ID,
        keyPath: WritableKeyPath<Model, Value> & Sendable,
        value: Value
    ) {
        guard baseModel(withId: id) != nil else { return }
        
        let newMutation = TypeSafeMutation<Model> { model in
            var mutableModel = model
            mutableModel[keyPath: keyPath] = value
            return mutableModel
        }
        
        applyMutation(for: id, mutation: newMutation)
    }
    
    public func batchUpdate(_ id: Model.ID, _ builder: (inout UpdateBuilder<Model>) -> Void) {
        guard baseModel(withId: id) != nil else { return }
        
        var updateBuilder = UpdateBuilder<Model>()
        builder(&updateBuilder)
        let transform = updateBuilder.build()
        
        let newMutation = TypeSafeMutation<Model> { model in
            var mutableModel = model
            transform(&mutableModel)
            return mutableModel
        }
        
        applyMutation(for: id, mutation: newMutation)
    }
    
    private func applyMutation(for id: Model.ID, mutation: TypeSafeMutation<Model>) {
        if isUndoRedoEnabled {
            undoBuffer.append(mutations)
            redoBuffer.removeAll()
        }
        
        if let existingMutation = mutations[id] {
            mutations[id] = existingMutation.merge(with: mutation)
        } else {
            mutations[id] = mutation
        }
        
        mutationTrigger = UUID()
    }
    
    public func mutatedModel(withId id: Model.ID) -> Model? {
        // Subscribe to mutationTrigger
        _ = mutationTrigger
        return model(withId: id)
    }
    
    public func commitMutations() {
        guard case .success(var models) = state else { return }
        
        for (id, mutation) in mutations {
            if let index = models.firstIndex(where: { $0.id == id }) {
                models[index] = mutation.apply(to: models[index])
            }
        }
        
        state = .success(models)
        mutations.removeAll()
        cacheInvalidated = true
        
        if isUndoRedoEnabled {
            undoBuffer.removeAll()
            redoBuffer.removeAll()
        }
    }
    
    public func discardMutations() {
        mutations.removeAll()
        cacheInvalidated = true
    }
    
    public func hasMutations(for id: Model.ID) -> Bool {
        mutations[id] != nil
    }
    
    // MARK: - Pagination Support
    
    public func loadPage(
        page: Int = 0,
        append: Bool = false,
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable (Int, Int) async throws -> [Model]
    ) async {
        let taskId = "load_page_\(page)"
        taskManager.cancel(id: taskId)
        
        let previousData = append ? state.data : nil
        state = .loading(previous: previousData)
        
        let pageSize = config.pageSize
        
        taskManager.run(id: taskId) { [weak self] in
            guard let self = self else { return }
            
            do {
                let newModels = try await Task.retrying(policy: retryPolicy) {
                    try await operation(page, pageSize)
                }
                
                await MainActor.run {
                    if append, case .success(let existing) = self.state {
                        self.state = .success(existing + newModels)
                    } else {
                        self.state = .success(newModels)
                    }
                    
                    self.currentPage = page
                    self.hasMorePages = newModels.count >= pageSize
                    self.cacheInvalidated = true
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.state = .failure(.cancelled, previous: previousData)
                }
            } catch {
                await MainActor.run {
                    self.state = .failure(.unknown(error.localizedDescription), previous: previousData)
                }
            }
        }
    }
    
    public func loadNextPage(
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable (Int, Int) async throws -> [Model]
    ) async {
        guard hasMorePages, !state.isLoading else { return }
        await loadPage(page: currentPage + 1, append: true, retryPolicy: retryPolicy, operation: operation)
    }
    
    public func refresh(
        retryPolicy: RetryPolicy = .default,
        operation: @escaping @Sendable (Int, Int) async throws -> [Model]
    ) async {
        await loadPage(page: 0, append: false, retryPolicy: retryPolicy, operation: operation)
    }
    
    // MARK: - Undo/Redo
    
    public func enableUndoRedo() {
        isUndoRedoEnabled = true
    }
    
    public func disableUndoRedo() {
        isUndoRedoEnabled = false
        undoBuffer.removeAll()
        redoBuffer.removeAll()
    }
    
    public func undo() {
        guard isUndoRedoEnabled, !undoBuffer.isEmpty else { return }
        redoBuffer.append(mutations)
        mutations = undoBuffer.removeLast() ?? [:]
        cacheInvalidated = true
    }
    
    public func redo() {
        guard isUndoRedoEnabled, !redoBuffer.isEmpty else { return }
        undoBuffer.append(mutations)
        mutations = redoBuffer.removeLast() ?? [:]
        cacheInvalidated = true
    }
    
    public var canUndo: Bool { isUndoRedoEnabled && !undoBuffer.isEmpty }
    public var canRedo: Bool { isUndoRedoEnabled && !redoBuffer.isEmpty }
    
    // MARK: - Helpers
    
    private func baseModel(withId id: Model.ID) -> Model? {
        guard case .success(let models) = state else { return nil }
        return models.first(where: { $0.id == id })
    }
    
    public func cancelAll() {
        taskManager.cancelAll()
    }
    
    deinit {
        Task { @MainActor [taskManager] in
            taskManager.cancelAll()
        }
    }
}


//
//  Containers.swift
//  StateManagementKit
//
//  Version: 2.0.0
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


//
//  TestUtilities.swift
//  StateManagementKit
//
//  Version: 2.0.0
//

/*
import Foundation

#if DEBUG

// MARK: - MockDataSource

@available(iOS 13.0.0, *)
public final class MockDataSource<Model: Sendable>: DataSourceProtocol {
    public var fetchHandler: (@Sendable () async throws -> [Model])?
    public var fetchPageHandler: (@Sendable (Int, Int) async throws -> [Model])?
    
    public init() {}
    
    public func fetch() async throws -> [Model] {
        guard let handler = fetchHandler else {
            throw StateError.unknown("fetchHandler not set")
        }
        return try await handler()
    }
    
    public func fetch(page: Int, pageSize: Int) async throws -> [Model] {
        guard let handler = fetchPageHandler else {
            throw StateError.unknown("fetchPageHandler not set")
        }
        return try await handler(page, pageSize)
    }
}

// MARK: - MockPersistence

public final class MockPersistence<Model: Codable & Sendable>: PersistenceProtocol {
    public var storage: [String: [Model]] = [:]
    
    public init() {}
    
    public func save(_ models: [Model], key: String) throws {
        storage[key] = models
    }
    
    public func load(key: String) throws -> [Model]? {
        storage[key]
    }
    
    public func clear() {
        storage.removeAll()
    }
}

// MARK: - Test Helpers

extension AsyncState {
    public var isIdleForTesting: Bool {
        if case .idle = self { return true }
        return false
    }
    
    public var successDataForTesting: T? {
        if case .success(let data) = self { return data }
        return nil
    }
    
    public var failureErrorForTesting: StateError? {
        if case .failure(let error, _) = self { return error }
        return nil
    }
}

#endif
*/
