//
//  StateStores.swift
//  MyLibrary
//
//  Created by Macbook on 14/1/26.
//

import SwiftUI
import Combine

// MARK: StateStore.swift

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

// MARK: SingleStateStore.swift

@available(iOS 13.0, *)
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
