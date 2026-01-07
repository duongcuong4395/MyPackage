//
//  StateManagementKit.swift
//  FootballDt
//
//  Created by Macbook on 2/1/26.
//

import SwiftUI
import Foundation
import Combine

// MARK: ====================================================
// MARK: - 1. Core Types & Protocols
// MARK: ====================================================

/// Generic async state with optimistic updates support
@frozen
public enum AsyncState<T: Sendable>: Sendable {
    case idle
    case loading(previous: T? = nil)
    case success(T)
    case failure(StateError, previous: T? = nil)
    
    public var data: T? {
        switch self {
        case .idle: return nil
        case .loading(let previous): return previous
        case .success(let data): return data
        case .failure(_, let previous): return previous
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
}

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
        case .network(let msg): return "Network error: \(msg)"
        case .decode(let msg): return "Decode error: \(msg)"
        case .notFound: return "Resource not found"
        case .unauthorized: return "Unauthorized access"
        case .cancelled: return "Operation cancelled"
        case .unknown(let msg): return msg
        }
    }
}

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

// MARK: ====================================================
// MARK: - 2. Type-Safe Mutation System
// MARK: ====================================================

/// Type-safe mutation that prevents runtime crashes
public struct TypeSafeMutation<Model: Equatable & Sendable>: Sendable {
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

// Type-safe update builder
public struct UpdateBuilder<Model: Sendable>: Sendable {
    private var mutations: [ @Sendable (inout Model) -> Void] = []
    
    public init() {}
    
    public mutating func set<Value: Sendable>(
        _ keyPath: WritableKeyPath<Model, Value> & Sendable,
       to value: Value
    ) {
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

// MARK: ====================================================
// MARK: - 3. Memory-Efficient Undo/Redo
// MARK: ====================================================

/// Circular buffer for undo/redo to prevent memory leaks
private struct CircularBuffer<T> {
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

// MARK: ====================================================
// MARK: - 4. Cancellable Task Manager
// MARK: ====================================================
@available(iOS 16.0, *)
/// Manages async tasks with automatic cancellation
@MainActor
public final class TaskManager {
    private var tasks: [String: Task<Void, Never>] = [:]
    
    public init() {}
    
    public func run(id: String, priority: TaskPriority = .userInitiated, operation: @escaping @Sendable () async throws -> Void) {
        cancel(id: id)
        
        tasks[id] = Task(priority: priority) { [weak self] in
            defer {
                Task { @MainActor in
                    self?.tasks.removeValue(forKey: id)
                }
            }
            
            do {
                try await operation()
            } catch is CancellationError {
                // Silently handle cancellation
            } catch {
                // Log error if needed
            }
        }
    }
    
    public func cancel(id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }
    
    public func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    public func cancelA() {
        let tasksToCancel = tasks.values
        tasksToCancel.forEach { $0.cancel() }
    }
    
    deinit {
        //cancelAll()
        let tasksToCancel = tasks.values
        tasksToCancel.forEach { $0.cancel() }
    }
    
}

// MARK: ====================================================
// MARK: - 5. Retry Logic with Exponential Backoff
// MARK: ====================================================
@available(iOS 16.0, *)
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
}

@available(iOS 16.0, *)
extension Task where Failure == Error {
    static func retrying(
        policy: RetryPolicy = .default,
        operation: @escaping () async throws -> Success
    ) async throws -> Success {
        var lastError: Error?
        
        for attempt in 0..<policy.maxAttempts {
            do {
                return try await operation()
            } catch is CancellationError {
                //throw CancellationError()
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

// MARK: ====================================================
// MARK: - 6. Protocol-Based Architecture (Dependency Injection)
// MARK: ====================================================
@available(iOS 16.0, *)
/// Protocol for data sources (mockable for testing)
public protocol DataSourceProtocol<Model>: Sendable {
    associatedtype Model: Sendable
    func fetch() async throws -> [Model]
    func fetch(page: Int, pageSize: Int) async throws -> [Model]
}

/// Protocol for persistence layer
public protocol PersistenceProtocol<Model>: Sendable {
    associatedtype Model: Codable & Sendable
    func save(_ models: [Model], key: String) throws
    func load(key: String) throws -> [Model]?
}

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

// MARK: ====================================================
// MARK: - 7. Enhanced SingleStateStore
// MARK: ====================================================
@available(iOS 16.0, *)
@MainActor
open class SingleStateStore<Model: Equatable & Sendable>: ObservableObject {
    
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
        guard let baseModel = state.data else { return }
        
        let newMutation = TypeSafeMutation<Model> { model in
            var mutableModel = model
            mutableModel[keyPath: keyPath] = value
            return mutableModel
        }
        
        applyMutation(newMutation)
    }
    
    public func batchUpdate(_ builder: (inout UpdateBuilder<Model>) -> Void) {
        guard let baseModel = state.data else { return }
        
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
        let manager = taskManager
        Task { @MainActor in
            manager.cancelAll()
        }
    }
}

// MARK: ====================================================
// MARK: - 8. Enhanced StateStore with Pagination
// MARK: ====================================================
@available(iOS 16.0, *)
@MainActor
open class StateStore<Model: Identifiable & Equatable & Sendable>: ObservableObject where Model.ID: Sendable {
    
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
        guard let baseModel = baseModel(withId: id) else { return }
        
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
        // Subscribe vào mutationTrigger
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
        
        taskManager.run(id: taskId) { [weak self] in
            guard let self = self else { return }
            
            do {
                let newModels = try await Task.retrying(policy: retryPolicy) {
                    try await operation(page, self.config.pageSize)
                }
                
                await MainActor.run {
                    if append, case .success(let existing) = self.state {
                        self.state = .success(existing + newModels)
                    } else {
                        self.state = .success(newModels)
                    }
                    
                    self.currentPage = page
                    self.hasMorePages = newModels.count >= self.config.pageSize
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
        //taskManager.cancelAll()
        let manager = taskManager
        Task { @MainActor in
            manager.cancelAll()
        }
    }
}

// MARK: ====================================================
// MARK: - 9. Enhanced Containers with DI
// MARK: ====================================================
@available(iOS 16.0, *)
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

@available(iOS 16.0, *)
@MainActor
open class StateContainer<Model: Identifiable & Equatable & Sendable>: ObservableObject where Model.ID: Sendable {
    
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
