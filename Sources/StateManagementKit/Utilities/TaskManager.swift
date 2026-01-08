//
//  TaskManager.swift
//  MyLibrary
//
//  Created by Macbook on 8/1/26.
//

import Foundation

/// Manages async tasks with automatic cancellation
@available(iOS 13.0, *)
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
