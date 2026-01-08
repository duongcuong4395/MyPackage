//
//  SingleStateStore.swift
//  MyLibrary
//
//  Created by Macbook on 8/1/26.
//

import SwiftUI
import Combine

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
