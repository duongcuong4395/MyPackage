//
//  CoreDataKitV2.swift
//  MyLibrary
//
//  Created by Macbook on 26/2/26.
//

// CoreDataKit.swift
// A complete, professional CoreData abstraction layer for SwiftUI apps.
//
// REQUIREMENTS: iOS 16.0+, Swift 5.9+
//
// USAGE EXAMPLE:
//
//   struct User: CoreDataKit {
//       typealias objCoreData = UserEntity
//       var entityName: String { "UserEntity" }
//       var uniqueIdentifier: String { id }
//       let id: String
//       let name: String
//
//       func convertToCoreData(context: NSManagedObjectContext) throws -> UserEntity {
//           let entity = UserEntity(context: context)
//           entity.id = id
//           entity.name = name
//           return entity
//       }
//
//       func updateCoreData(_ object: UserEntity, context: NSManagedObjectContext) throws {
//           object.name = name
//       }
//
//       func checkExists(from context: NSManagedObjectContext) throws -> (Bool, [UserEntity]) {
//           let request = UserEntity.fetchRequest()
//           request.predicate = NSPredicate(format: "id == %@", id)
//           let results = try context.fetch(request) as! [UserEntity]
//           return (!results.isEmpty, results)
//       }
//   }
//
//   // Then use:
//   let result = try await user.upsert(for: viewContext)
//   let users  = try await User.fetchAll(from: viewContext)

import SwiftUI
@preconcurrency import CoreData
import OSLog

// MARK: - Logger
@available(iOS 16.0, *)
/// Centralized logger for CoreDataKit. Uses OSLog for structured, performant logging.
public enum CoreDataLogger {
    public enum Level {
        case debug, info, warning, error, fault
    }

    private static let logger = Logger(subsystem: "com.app.CoreDataKit", category: "CoreData")

    public static func log(
        _ message: String,
        level: Level = .info,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let filename = (file as NSString).lastPathComponent
        var output = "[\(filename):\(line)] \(function) → \(message)"
        if let metadata {
            let meta = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            output += " | \(meta)"
        }
        switch level {
        case .debug:   logger.debug("\(output)")
        case .info:    logger.info("\(output)")
        case .warning: logger.warning("\(output)")
        case .error:   logger.error("\(output)")
        case .fault:   logger.fault("\(output)")
        }
    }
}

// MARK: - Custom Errors

/// Strongly typed errors for CoreDataKit operations.
public enum CoreDataKitError: LocalizedError {
    case contextUnavailable
    case entityNotFound(String)
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case insertFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case batchOperationFailed(successes: Int, failures: Int, underlying: [Error])
    case taskCancelled

    public var errorDescription: String? {
        switch self {
        case .contextUnavailable:
            return "NSManagedObjectContext is unavailable."
        case .entityNotFound(let id):
            return "Entity with identifier '\(id)' was not found."
        case .saveFailed(let e):
            return "Save failed: \(e.localizedDescription)"
        case .fetchFailed(let e):
            return "Fetch failed: \(e.localizedDescription)"
        case .insertFailed(let e):
            return "Insert failed: \(e.localizedDescription)"
        case .updateFailed(let e):
            return "Update failed: \(e.localizedDescription)"
        case .deleteFailed(let e):
            return "Delete failed: \(e.localizedDescription)"
        case .batchOperationFailed(let s, let f, _):
            return "Batch operation: \(s) succeeded, \(f) failed."
        case .taskCancelled:
            return "Operation was cancelled."
        }
    }
}

// MARK: - Performance Metrics

/// Captures timing and outcome data for a single CoreData operation.
@available(iOS 16.0, *)
public struct PerformanceMetrics: Sendable {
    public let operation: String
    public let duration: TimeInterval
    public let objectCount: Int
    public let success: Bool

    public func log() {
        CoreDataLogger.log(
            "Performance: \(operation)",
            level: success ? .info : .warning,
            metadata: [
                "duration_ms": String(format: "%.2f", duration * 1000),
                "objects": objectCount,
                "success": success
            ]
        )
    }
}

// MARK: - Operation Result

/// Wraps the outcome of a CoreData operation with an optional metrics payload.
@available(iOS 16.0, *)
public struct OperationResult: Sendable {
    public let success: Bool
    public let message: String
    public let metrics: PerformanceMetrics?

    public init(success: Bool, message: String, metrics: PerformanceMetrics? = nil) {
        self.success = success
        self.message = message
        self.metrics = metrics
        metrics?.log()
    }
}

/// Result for batch operations, carrying per-item outcomes.
@available(iOS 16.0, *)
public struct BatchOperationResult: Sendable {
    public let totalCount: Int
    public let successCount: Int
    public let failureCount: Int
    public let metrics: PerformanceMetrics?

    public var isFullSuccess: Bool { failureCount == 0 }
}

// MARK: - Context Pool

/// Manages a pool of reusable child `NSManagedObjectContext` instances to reduce
/// allocation overhead during high-frequency operations.
@available(iOS 16.0, *)
public final class CoreDataContextPool: @unchecked Sendable {
    public static let shared = CoreDataContextPool()

    private let lock = NSLock()
    private var available: [NSManagedObjectContext] = []
    private let maxPoolSize: Int

    public init(maxPoolSize: Int = 4) {
        self.maxPoolSize = maxPoolSize
    }

    /// Returns a pooled child context whose parent is `parent`, or creates a new one.
    public func getContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        lock.lock()
        defer { lock.unlock() }

        if let ctx = available.popLast() {
            ctx.parent = parent
            return ctx
        }
        let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        ctx.parent = parent
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.undoManager = nil // performance: disable undo for background contexts
        return ctx
    }

    /// Returns a context to the pool for future reuse.
    public func returnContext(_ ctx: NSManagedObjectContext) {
        lock.lock()
        defer { lock.unlock() }

        ctx.reset()
        if available.count < maxPoolSize {
            available.append(ctx)
        }
    }
}

// MARK: - CoreDataKit Protocol

/// The core protocol that your Swift model types conform to in order to gain
/// free CRUD, batch, and fetch capabilities backed by CoreData.
///
/// Conforming types must implement four methods:
/// - `convertToCoreData`  — maps self → new NSManagedObject
/// - `updateCoreData`     — applies self's values to an existing NSManagedObject
/// - `checkExists`        — returns whether a matching record exists (and the records)
/// - `entityName`         — the CoreData entity name string
/// - `uniqueIdentifier`   — a stable string that uniquely identifies the record
@available(iOS 16.0, *)
public protocol CoreDataKit: Equatable, Sendable {
    associatedtype objCoreData: NSManagedObject

    var entityName: String { get }
    var uniqueIdentifier: String { get }

    func convertToCoreData(context: NSManagedObjectContext) throws -> objCoreData
    func updateCoreData(_ object: objCoreData, context: NSManagedObjectContext) throws
    func checkExists(from context: NSManagedObjectContext) throws -> (Bool, [objCoreData])
}

// MARK: - Default Implementations

@available(iOS 16.0, *)
public extension CoreDataKit {

    // MARK: Internal helpers

    /// Resolves the correct working context and whether it owns a pool slot.
    private func resolvedContext(
        from context: NSManagedObjectContext
    ) -> (working: NSManagedObjectContext, pooled: Bool) {
        if context.parent != nil {
            let ctx = CoreDataContextPool.shared.getContext(parent: context)
            return (ctx, true)
        }
        return (context, false)
    }

    /// Saves `workingContext` and, if pooled, its parent. Rolls back on failure.
    private func save(
        working: NSManagedObjectContext,
        parent: NSManagedObjectContext,
        pooled: Bool
    ) throws {
        guard working.hasChanges || parent.hasChanges else { return }
        do {
            if working.hasChanges {
                try working.save()
            }
            if pooled && parent.hasChanges {
                try parent.save()
            }
        } catch {
            working.rollback()
            throw CoreDataKitError.saveFailed(underlying: error)
        }
    }

    // MARK: - Upsert (Insert or Update)

    /// Atomically inserts or updates a single record.
    ///
    /// - Parameter context: The `NSManagedObjectContext` to operate on.
    /// - Returns: An `OperationResult` describing the outcome.
    @discardableResult
    func upsert(for context: NSManagedObjectContext) async throws -> OperationResult {
        try Task.checkCancellation()
        let startTime = Date()
        let (working, pooled) = resolvedContext(from: context)
        defer { if pooled { CoreDataContextPool.shared.returnContext(working) } }

        return try await withCheckedThrowingContinuation { continuation in
            working.perform {
                do {
                    try Task.checkCancellation()
                    let (exists, objects) = try self.checkExists(from: working)
                    let op: String

                    if exists, let existing = objects.first {
                        try self.updateCoreData(existing, context: working)
                        op = "upsert_update"
                    } else {
                        _ = try self.convertToCoreData(context: working)
                        op = "upsert_insert"
                    }

                    try self.save(working: working, parent: context, pooled: pooled)

                    let metrics = PerformanceMetrics(
                        operation: op,
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: 1,
                        success: true
                    )
                    continuation.resume(returning: OperationResult(
                        success: true,
                        message: exists ? "Updated" : "Inserted",
                        metrics: metrics
                    ))
                } catch is CancellationError {
                    working.rollback()
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    working.rollback()
                    CoreDataLogger.log("upsert failed [\(self.uniqueIdentifier)]: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Delete

    /// Deletes a single record matching `uniqueIdentifier`.
    ///
    /// - Returns: `OperationResult` with `success = false` if the record did not exist.
    @discardableResult
    func delete(for context: NSManagedObjectContext) async throws -> OperationResult {
        try Task.checkCancellation()
        let startTime = Date()
        let (working, pooled) = resolvedContext(from: context)
        defer { if pooled { CoreDataContextPool.shared.returnContext(working) } }

        return try await withCheckedThrowingContinuation { continuation in
            working.perform {
                do {
                    try Task.checkCancellation()
                    let (exists, objects) = try self.checkExists(from: working)

                    guard exists, let target = objects.first else {
                        continuation.resume(returning: OperationResult(
                            success: false,
                            message: "Not found: \(self.uniqueIdentifier)"
                        ))
                        return
                    }

                    working.delete(target)
                    try self.save(working: working, parent: context, pooled: pooled)

                    let metrics = PerformanceMetrics(
                        operation: "delete",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: 1,
                        success: true
                    )
                    continuation.resume(returning: OperationResult(
                        success: true,
                        message: "Deleted",
                        metrics: metrics
                    ))
                } catch is CancellationError {
                    working.rollback()
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    working.rollback()
                    CoreDataLogger.log("delete failed [\(self.uniqueIdentifier)]: \(error)", level: .error)
                    continuation.resume(throwing: CoreDataKitError.deleteFailed(underlying: error))
                }
            }
        }
    }
}

// MARK: - Static / Collection Operations

@available(iOS 16.0, *)
public extension CoreDataKit {

    // MARK: - Batch Upsert

    /// Upserts a collection of items inside a single transaction.
    ///
    /// All items are processed together; if any item fails the entire batch is
    /// rolled back and a `CoreDataKitError.batchOperationFailed` is thrown.
    ///
    /// - Parameters:
    ///   - items:   The Swift model values to upsert.
    ///   - context: The `NSManagedObjectContext` to operate on.
    /// - Returns: A `BatchOperationResult` summarising the outcome.
    @discardableResult
    func batchUpsert(
        _ items: [Self],
        for context: NSManagedObjectContext
    ) async throws -> BatchOperationResult {
        guard !items.isEmpty else {
            return BatchOperationResult(totalCount: 0, successCount: 0, failureCount: 0, metrics: nil)
        }
        try Task.checkCancellation()

        let startTime = Date()
        let pooled = context.parent != nil
        let working = pooled
            ? CoreDataContextPool.shared.getContext(parent: context)
            : context
        defer { if pooled { CoreDataContextPool.shared.returnContext(working) } }

        return try await withCheckedThrowingContinuation { continuation in
            working.perform {
                do {
                    try Task.checkCancellation()
                    var errors: [Error] = []
                    var successCount = 0

                    for item in items {
                        do {
                            let (exists, objects) = try item.checkExists(from: working)
                            if exists, let existing = objects.first {
                                try item.updateCoreData(existing, context: working)
                            } else {
                                _ = try item.convertToCoreData(context: working)
                            }
                            successCount += 1
                        } catch {
                            errors.append(error)
                        }
                    }

                    if !errors.isEmpty {
                        working.rollback()
                        throw CoreDataKitError.batchOperationFailed(
                            successes: successCount,
                            failures: errors.count,
                            underlying: errors
                        )
                    }

                    if working.hasChanges { try working.save() }
                    if pooled && context.hasChanges { try context.save() }

                    let metrics = PerformanceMetrics(
                        operation: "batch_upsert",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: items.count,
                        success: true
                    )
                    continuation.resume(returning: BatchOperationResult(
                        totalCount: items.count,
                        successCount: successCount,
                        failureCount: 0,
                        metrics: metrics
                    ))
                } catch is CancellationError {
                    working.rollback()
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    working.rollback()
                    CoreDataLogger.log("batchUpsert failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Batch Delete

    /// Deletes a collection of items inside a single transaction.
    ///
    /// Items that don't exist in the store are silently skipped.
    ///
    /// - Parameters:
    ///   - items:   The Swift model values to delete.
    ///   - context: The `NSManagedObjectContext` to operate on.
    /// - Returns: A `BatchOperationResult` summarising the outcome.
    @discardableResult
    func batchDelete(
        _ items: [Self],
        for context: NSManagedObjectContext
    ) async throws -> BatchOperationResult {
        guard !items.isEmpty else {
            return BatchOperationResult(totalCount: 0, successCount: 0, failureCount: 0, metrics: nil)
        }
        try Task.checkCancellation()

        let startTime = Date()
        let pooled = context.parent != nil
        let working = pooled
            ? CoreDataContextPool.shared.getContext(parent: context)
            : context
        defer { if pooled { CoreDataContextPool.shared.returnContext(working) } }

        return try await withCheckedThrowingContinuation { continuation in
            working.perform {
                do {
                    try Task.checkCancellation()
                    var errors: [Error] = []
                    var successCount = 0

                    for item in items {
                        do {
                            let (exists, objects) = try item.checkExists(from: working)
                            if exists, let target = objects.first {
                                working.delete(target)
                                successCount += 1
                            }
                        } catch {
                            errors.append(error)
                        }
                    }

                    if !errors.isEmpty {
                        working.rollback()
                        throw CoreDataKitError.batchOperationFailed(
                            successes: successCount,
                            failures: errors.count,
                            underlying: errors
                        )
                    }

                    if working.hasChanges { try working.save() }
                    if pooled && context.hasChanges { try context.save() }

                    let metrics = PerformanceMetrics(
                        operation: "batch_delete",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: successCount,
                        success: true
                    )
                    continuation.resume(returning: BatchOperationResult(
                        totalCount: items.count,
                        successCount: successCount,
                        failureCount: 0,
                        metrics: metrics
                    ))
                } catch is CancellationError {
                    working.rollback()
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    working.rollback()
                    CoreDataLogger.log("batchDelete failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Delete All

    /// Deletes **all** records of this entity type from the store.
    ///
    /// Uses `NSBatchDeleteRequest` for efficiency — does not load objects into memory.
    ///
    /// - Parameters:
    ///   - context:     The view or background context.
    ///   - entityName:  The CoreData entity name (required as a static parameter).
    @discardableResult
    func deleteAll(
        entityName: String,
        for context: NSManagedObjectContext
    ) async throws -> OperationResult {
        try Task.checkCancellation()
        let startTime = Date()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDelete.resultType = .resultTypeCount

                    let result = try context.execute(batchDelete) as? NSBatchDeleteResult
                    let count = result?.result as? Int ?? 0

                    // Merge changes into the context so SwiftUI views update
                    context.reset()

                    let metrics = PerformanceMetrics(
                        operation: "delete_all",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: count,
                        success: true
                    )
                    continuation.resume(returning: OperationResult(
                        success: true,
                        message: "Deleted \(count) records",
                        metrics: metrics
                    ))
                } catch is CancellationError {
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    CoreDataLogger.log("deleteAll failed (\(entityName)): \(error)", level: .error)
                    continuation.resume(throwing: CoreDataKitError.deleteFailed(underlying: error))
                }
            }
        }
    }

    // MARK: - Fetch All

    /// Fetches all records, transforming each `NSManagedObject` into a `Sendable`
    /// value type **inside** `context.perform` — the only pattern that fully satisfies
    /// Swift 6 strict concurrency.
    ///
    /// `NSManagedObject` is not `Sendable` and must never cross a concurrency boundary.
    /// By accepting a `transform` closure, callers map each managed object to their own
    /// `Sendable` struct/value *before* the result leaves the context's isolation domain.
    ///
    /// **Example**
    /// ```swift
    /// let users = try await UserModel.fetchAll(from: context) { entity in
    ///     UserDTO(id: entity.id ?? "", name: entity.name ?? "")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - context:         The `NSManagedObjectContext` to fetch from.
    ///   - sortDescriptors: Optional sort descriptors.
    ///   - fetchLimit:      Maximum records (0 = unlimited).
    ///   - transform:       Maps each `objCoreData` → your `Sendable` value type.
    ///                      Runs on the context's private queue.
    /// - Returns: Array of transformed `Result` values.
    func fetchAll<Result: Sendable>(
        from context: NSManagedObjectContext,
        sortDescriptors: [NSSortDescriptor] = [],
        fetchLimit: Int = 0,
        transform: @Sendable @escaping (objCoreData) throws -> Result
    ) async throws -> [Result] {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    try Task.checkCancellation()
                    let request = NSFetchRequest<objCoreData>(
                        entityName: String(describing: objCoreData.self)
                    )
                    request.sortDescriptors = sortDescriptors.isEmpty ? nil : sortDescriptors
                    if fetchLimit > 0 { request.fetchLimit = fetchLimit }

                    // transform happens here — inside perform — before crossing the boundary.
                    let results: [Result] = try context.fetch(request).map(transform)
                    continuation.resume(returning: results)
                } catch is CancellationError {
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    CoreDataLogger.log("fetchAll failed: \(error)", level: .error)
                    continuation.resume(throwing: CoreDataKitError.fetchFailed(underlying: error))
                }
            }
        }
    }

    /// Convenience overload that returns raw `NSManagedObjectID` array.
    /// Use this when you only need stable identifiers — no Sendable issue.
    ///
    /// - Parameters:
    ///   - context:         The `NSManagedObjectContext` to fetch from.
    ///   - sortDescriptors: Optional sort descriptors.
    ///   - fetchLimit:      Maximum records (0 = unlimited).
    /// - Returns: Array of `NSManagedObjectID` (inherently `Sendable`).
    func fetchAllIDs(
        from context: NSManagedObjectContext,
        sortDescriptors: [NSSortDescriptor] = [],
        fetchLimit: Int = 0
    ) async throws -> [NSManagedObjectID] {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    try Task.checkCancellation()
                    let request = NSFetchRequest<NSManagedObjectID>(
                        entityName: String(describing: objCoreData.self)
                    )
                    request.resultType = .managedObjectIDResultType
                    request.sortDescriptors = sortDescriptors.isEmpty ? nil : sortDescriptors
                    if fetchLimit > 0 { request.fetchLimit = fetchLimit }

                    let ids = try context.fetch(request)
                    continuation.resume(returning: ids)
                } catch is CancellationError {
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    CoreDataLogger.log("fetchAllIDs failed: \(error)", level: .error)
                    continuation.resume(throwing: CoreDataKitError.fetchFailed(underlying: error))
                }
            }
        }
    }

    // MARK: - Fetch with Predicate

    /// Fetches records matching a custom `NSPredicate`, transforming each managed object
    /// into a `Sendable` value type **inside** `context.perform`.
    ///
    /// Same reasoning as `fetchAll` — `NSManagedObject` must never escape its context's
    /// isolation domain. The `transform` closure runs on the context's private queue,
    /// producing only `Sendable` values that safely cross the concurrency boundary.
    ///
    /// **Example**
    /// ```swift
    /// let active = try await UserModel.fetch(
    ///     where: NSPredicate(format: "isActive == true"),
    ///     from: context
    /// ) { entity in
    ///     UserDTO(id: entity.id ?? "", name: entity.name ?? "")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - predicate:       The filter predicate.
    ///   - context:         The `NSManagedObjectContext` to fetch from.
    ///   - sortDescriptors: Optional sort descriptors.
    ///   - fetchLimit:      Maximum records (0 = unlimited).
    ///   - transform:       Maps each `objCoreData` → your `Sendable` value type.
    ///                      Runs on the context's private queue.
    /// - Returns: Array of transformed `Result` values.
    func fetch<Result: Sendable>(
        where predicate: NSPredicate,
        from context: NSManagedObjectContext,
        sortDescriptors: [NSSortDescriptor] = [],
        fetchLimit: Int = 0,
        transform: @Sendable @escaping (objCoreData) throws -> Result
    ) async throws -> [Result] {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    try Task.checkCancellation()
                    let request = NSFetchRequest<objCoreData>(
                        entityName: String(describing: objCoreData.self)
                    )
                    request.predicate = predicate
                    request.sortDescriptors = sortDescriptors.isEmpty ? nil : sortDescriptors
                    if fetchLimit > 0 { request.fetchLimit = fetchLimit }

                    // transform happens here — inside perform — before crossing the boundary.
                    let results: [Result] = try context.fetch(request).map(transform)
                    continuation.resume(returning: results)
                } catch is CancellationError {
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    CoreDataLogger.log("fetch(where:) failed: \(error)", level: .error)
                    continuation.resume(throwing: CoreDataKitError.fetchFailed(underlying: error))
                }
            }
        }
    }

    /// Convenience overload that returns matching `NSManagedObjectID` values only.
    /// No Sendable issue, useful when you need to pass IDs across actors.
    ///
    /// - Parameters:
    ///   - predicate:       The filter predicate.
    ///   - context:         The `NSManagedObjectContext` to fetch from.
    ///   - sortDescriptors: Optional sort descriptors.
    ///   - fetchLimit:      Maximum records (0 = unlimited).
    /// - Returns: Matching `NSManagedObjectID` array.
    func fetchIDs(
        where predicate: NSPredicate,
        from context: NSManagedObjectContext,
        sortDescriptors: [NSSortDescriptor] = [],
        fetchLimit: Int = 0
    ) async throws -> [NSManagedObjectID] {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    try Task.checkCancellation()
                    let request = NSFetchRequest<NSManagedObjectID>(
                        entityName: String(describing: objCoreData.self)
                    )
                    request.resultType = .managedObjectIDResultType
                    request.predicate = predicate
                    request.sortDescriptors = sortDescriptors.isEmpty ? nil : sortDescriptors
                    if fetchLimit > 0 { request.fetchLimit = fetchLimit }

                    let ids = try context.fetch(request)
                    continuation.resume(returning: ids)
                } catch is CancellationError {
                    continuation.resume(throwing: CoreDataKitError.taskCancelled)
                } catch {
                    CoreDataLogger.log("fetchIDs(where:) failed: \(error)", level: .error)
                    continuation.resume(throwing: CoreDataKitError.fetchFailed(underlying: error))
                }
            }
        }
    }

    // MARK: - Count

    /// Returns the total number of records for this entity in the store.
    ///
    /// - Parameter context: The `NSManagedObjectContext` to count from.
    static func count(
        from context: NSManagedObjectContext,
        predicate: NSPredicate? = nil
    ) async throws -> Int {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<objCoreData>(
                        entityName: String(describing: objCoreData.self)
                    )
                    request.predicate = predicate
                    let count = try context.count(for: request)
                    continuation.resume(returning: count)
                } catch {
                    CoreDataLogger.log("count failed: \(error)", level: .error)
                    continuation.resume(throwing: CoreDataKitError.fetchFailed(underlying: error))
                }
            }
        }
    }

    // MARK: - Exists Check (Convenience)

    /// Returns `true` if a record with `uniqueIdentifier` exists in the store.
    func exists(in context: NSManagedObjectContext) async throws -> Bool {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let (exists, _) = try self.checkExists(from: context)
                    continuation.resume(returning: exists)
                } catch {
                    continuation.resume(throwing: CoreDataKitError.fetchFailed(underlying: error))
                }
            }
        }
    }
}
