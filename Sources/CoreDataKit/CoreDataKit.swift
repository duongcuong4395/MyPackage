//
//  CoreDataKit.swift
//  MyLibrary
//
//  Created by Macbook on 29/10/25.
//

//
//  CoreDataKit+Improvements.swift
//  Enhanced version với performance, concurrency, và observability improvements
//
//  Major improvements:
//  - Context pooling & reuse
//  - True batch operations với NSBatchInsertRequest
//  - Atomic operations
//  - Memory-efficient streaming
//  - Comprehensive logging
//  - Testability improvements
//

import SwiftUI
@preconcurrency import CoreData
import OSLog

// MARK: - Logging System

/// Unified logging for CoreData operations
@available(iOS 16.0, *)
public struct CoreDataLogger {
    private static let logger = Logger(subsystem: "com.app.coredata", category: "operations")
    
    public enum LogLevel {
        case debug, info, warning, error
    }
    
    public static func log(_ message: String, level: LogLevel = .info, metadata: [String: Any] = [:]) {
        let metadataStr = metadata.isEmpty ? "" : " | \(metadata)"
        
        switch level {
        case .debug:
            logger.debug("\(message)\(metadataStr)")
        case .info:
            logger.info("\(message)\(metadataStr)")
        case .warning:
            logger.warning("\(message)\(metadataStr)")
        case .error:
            logger.error("\(message)\(metadataStr)")
        }
    }
}

// MARK: - Performance Metrics
@available(iOS 16.0, *)
/// Track operation performance
public struct PerformanceMetrics {
    let operation: String
    let duration: TimeInterval
    let objectCount: Int
    let success: Bool
    
    public func log() {
        CoreDataLogger.log(
            "Performance: \(operation)",
            metadata: [
                "duration": duration,
                "objects": objectCount,
                "success": success
            ]
        )
    }
}

// MARK: - Context Pool (Singleton)

/// Reusable context pool to reduce overhead
@available(iOS 16.0, *)
public class CoreDataContextPool {
    nonisolated(unsafe) public static let shared = CoreDataContextPool()
    
    private var availableContexts: [NSManagedObjectContext] = []
    private let queue = DispatchQueue(label: "com.coredata.pool", attributes: .concurrent)
    private let maxPoolSize = 5
    
    public init() {}
    
    func getContext(parent: NSManagedObjectContext) -> NSManagedObjectContext {
        return queue.sync(flags: .barrier) {
            if let context = availableContexts.popLast() {
                context.parent = parent
                return context
            }
            
            let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            newContext.parent = parent
            return newContext
        }
    }
    
    func returnContext(_ context: NSManagedObjectContext) {
        queue.async(flags: .barrier) { //[weak self] in
            //guard let self = self else { return }
            
            context.reset() // Clear memory
            context.parent = nil
            let pool = CoreDataContextPool.shared
            if pool.availableContexts.count < pool.maxPoolSize {
                pool.availableContexts.append(context)
            }
        }
    }
}

// MARK: - Improved Error Types

public enum CoreDataErrorV2: LocalizedError {
    case conversionFailed(String)
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case objectNotFound
    case batchOperationFailed(succeeded: Int, failed: Int, errors: [Error])
    case invalidPredicate
    case concurrencyConflict(String)
    case validationFailed([String: String])
    
    public var errorDescription: String? {
        switch self {
        case .conversionFailed(let details):
            return "Conversion failed: \(details)"
        case .fetchFailed(let details):
            return "Fetch failed: \(details)"
        case .saveFailed(let details):
            return "Save failed: \(details)"
        case .deleteFailed(let details):
            return "Delete failed: \(details)"
        case .objectNotFound:
            return "Object not found"
        case .batchOperationFailed(let succeeded, let failed, let errors):
            return "Batch: \(succeeded) OK, \(failed) failed. First error: \(errors.first?.localizedDescription ?? "unknown")"
        case .invalidPredicate:
            return "Invalid predicate"
        case .concurrencyConflict(let details):
            return "Concurrency conflict: \(details)"
        case .validationFailed(let details):
            return "Validation failed: \(details)"
        }
    }
}

// MARK: - Operation Result với metrics

@available(iOS 16.0, *)
public struct OperationResult {
    let success: Bool
    let message: String
    let metrics: PerformanceMetrics?
    
    public init(success: Bool, message: String, metrics: PerformanceMetrics? = nil) {
        self.success = success
        self.message = message
        self.metrics = metrics
        metrics?.log()
    }
}

// MARK: - Improved Protocol với atomic operations

@available(iOS 16.0, *)
public protocol CoreDataKit: Equatable {
    associatedtype objCoreData: NSManagedObject
    
    var entityName: String { get }
    var uniqueIdentifier: String { get }
    
    func convertToCoreData(context: NSManagedObjectContext) throws -> objCoreData
    func updateCoreData(_ object: objCoreData, context: NSManagedObjectContext) throws
    func checkExists(from context: NSManagedObjectContext) throws -> (Bool, [objCoreData])
    
    // Improved methods with OperationResult
    func upsert(for context: NSManagedObjectContext) async throws -> OperationResult
    func delete(for context: NSManagedObjectContext) async throws -> OperationResult
}

@available(iOS 16.0, *)
public extension CoreDataKit {
    
    // MARK: - Atomic Upsert (Update or Insert)
    
    /// Atomic upsert operation - thread safe
    func upsert(for context: NSManagedObjectContext) async throws -> OperationResult {
        let startTime = Date()
        let pool = CoreDataContextPool.shared
        let backgroundContext = pool.getContext(parent: context)
        
        defer {
            pool.returnContext(backgroundContext)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    // Atomic check-and-update trong cùng 1 transaction
                    let (exists, objects) = try self.checkExists(from: backgroundContext)
                    
                    if exists, let existingObject = objects.first {
                        // Update
                        try self.updateCoreData(existingObject, context: backgroundContext)
                        
                        if backgroundContext.hasChanges {
                            try backgroundContext.save()
                            try context.save()
                        }
                        
                        let metrics = PerformanceMetrics(
                            operation: "upsert_update",
                            duration: Date().timeIntervalSince(startTime),
                            objectCount: 1,
                            success: true
                        )
                        
                        continuation.resume(returning: OperationResult(
                            success: true,
                            message: "Updated",
                            metrics: metrics
                        ))
                    } else {
                        // Insert
                        _ = try self.convertToCoreData(context: backgroundContext)
                        
                        try backgroundContext.save()
                        try context.save()
                        
                        let metrics = PerformanceMetrics(
                            operation: "upsert_insert",
                            duration: Date().timeIntervalSince(startTime),
                            objectCount: 1,
                            success: true
                        )
                        
                        continuation.resume(returning: OperationResult(
                            success: true,
                            message: "Inserted",
                            metrics: metrics
                        ))
                    }
                } catch {
                    CoreDataLogger.log("Upsert failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Safe Delete
    
    func delete(for context: NSManagedObjectContext) async throws -> OperationResult {
        let startTime = Date()
        let pool = CoreDataContextPool.shared
        let backgroundContext = pool.getContext(parent: context)
        
        defer {
            pool.returnContext(backgroundContext)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let (exists, objects) = try self.checkExists(from: backgroundContext)
                    
                    guard exists, let objectToDelete = objects.first else {
                        continuation.resume(returning: OperationResult(
                            success: false,
                            message: "Not found"
                        ))
                        return
                    }
                    
                    backgroundContext.delete(objectToDelete)
                    
                    if backgroundContext.hasChanges {
                        try backgroundContext.save()
                        try context.save()
                    }
                    
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
                } catch {
                    CoreDataLogger.log("Delete failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - True Batch Operations with NSBatchInsertRequest

@available(iOS 16.0, *)
public protocol BatchCoreDataOperations: CoreDataKit {
    
    /// Convert to dictionary for batch insert
    func toDictionary() -> [String: Any]
    
    /// Batch upsert with NSBatchInsertRequest
    static func batchUpsert(
        _ objects: [Self],
        context: NSManagedObjectContext,
        chunkSize: Int
    ) async throws -> OperationResult
    
    /// Memory-efficient batch delete
    static func batchDelete(
        predicate: NSPredicate,
        context: NSManagedObjectContext
    ) async throws -> OperationResult
    
    init()
}

@available(iOS 16.0, *)
public extension BatchCoreDataOperations {
    
    /// High-performance batch insert/update
    static func batchUpsert(
        _ objects: [Self],
        context: NSManagedObjectContext,
        chunkSize: Int = 500
    ) async throws -> OperationResult {
        
        guard !objects.isEmpty else {
            return OperationResult(success: true, message: "No objects to process")
        }
        
        let startTime = Date()
        let pool = CoreDataContextPool.shared
        let backgroundContext = pool.getContext(parent: context)
        
        defer {
            pool.returnContext(backgroundContext)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    var totalInserted = 0
                    var totalUpdated = 0
                    
                    // Process in chunks to avoid memory spikes
                    for chunk in stride(from: 0, to: objects.count, by: chunkSize) {
                        let end = min(chunk + chunkSize, objects.count)
                        let chunkObjects = Array(objects[chunk..<end])
                        
                        // Separate insert vs update
                        var toInsert: [[String: Any]] = []
                        var toUpdate: [Self] = []
                        
                        for object in chunkObjects {
                            let (exists, _) = try object.checkExists(from: backgroundContext)
                            if exists {
                                toUpdate.append(object)
                            } else {
                                toInsert.append(object.toDictionary())
                            }
                        }
                        
                        // Batch insert with NSBatchInsertRequest
                        if !toInsert.isEmpty {
                            let batchInsert = NSBatchInsertRequest(
                                entityName: chunkObjects[0].entityName,
                                objects: toInsert
                            )
                            batchInsert.resultType = .count
                            
                            let result = try backgroundContext.execute(batchInsert) as? NSBatchInsertResult
                            totalInserted += (result?.result as? Int) ?? 0
                        }
                        
                        // Update manually (no batch update for complex logic)
                        for object in toUpdate {
                            let (_, existing) = try object.checkExists(from: backgroundContext)
                            if let obj = existing.first {
                                try object.updateCoreData(obj, context: backgroundContext)
                                totalUpdated += 1
                            }
                        }
                        
                        // Save chunk
                        if backgroundContext.hasChanges {
                            try backgroundContext.save()
                        }
                    }
                    
                    // Final save to parent
                    try context.save()
                    
                    let metrics = PerformanceMetrics(
                        operation: "batch_upsert",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: objects.count,
                        success: true
                    )
                    
                    CoreDataLogger.log(
                        "Batch upsert completed",
                        metadata: [
                            "inserted": totalInserted,
                            "updated": totalUpdated,
                            "total": objects.count
                        ]
                    )
                    
                    continuation.resume(returning: OperationResult(
                        success: true,
                        message: "Inserted: \(totalInserted), Updated: \(totalUpdated)",
                        metrics: metrics
                    ))
                    
                } catch {
                    CoreDataLogger.log("Batch upsert failed: \(error)", level: .error)
                    continuation.resume(throwing: CoreDataErrorV2.batchOperationFailed(
                        succeeded: 0,
                        failed: objects.count,
                        errors: [error]
                    ))
                }
            }
        }
    }
    
    /// Memory-efficient batch delete with NSBatchDeleteRequest
    static func batchDelete(
        predicate: NSPredicate,
        context: NSManagedObjectContext
    ) async throws -> OperationResult {
        
        let startTime = Date()
        let pool = CoreDataContextPool.shared
        let backgroundContext = pool.getContext(parent: context)
        
        defer {
            pool.returnContext(backgroundContext)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    // Get entity name from first object
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Self.init().entityName)
                    fetchRequest.predicate = predicate
                    
                    let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDelete.resultType = .resultTypeObjectIDs
                    
                    let result = try backgroundContext.execute(batchDelete) as? NSBatchDeleteResult
                    let objectIDs = result?.result as? [NSManagedObjectID] ?? []
                    
                    // Merge changes
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: changes,
                        into: [context, backgroundContext]
                    )
                    
                    try context.save()
                    
                    let metrics = PerformanceMetrics(
                        operation: "batch_delete",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: objectIDs.count,
                        success: true
                    )
                    
                    continuation.resume(returning: OperationResult(
                        success: true,
                        message: "Deleted \(objectIDs.count) objects",
                        metrics: metrics
                    ))
                    
                } catch {
                    CoreDataLogger.log("Batch delete failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Memory-Efficient Streaming Fetch

@available(iOS 13.0, *)
public extension NSManagedObjectContext {
    
    /// Stream large datasets without loading all into memory
    func streamFetch<Entity: NSManagedObject>(
        ofType entityType: Entity.Type,
        batchSize: Int = 100,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [],
        processBatch: @escaping ([Entity]) -> Void
    ) throws {
        
        let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: entityType))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = batchSize
        
        var offset = 0
        var hasMore = true
        
        while hasMore {
            fetchRequest.fetchOffset = offset
            fetchRequest.fetchLimit = batchSize
            
            let batch = try fetch(fetchRequest)
            
            if batch.isEmpty {
                hasMore = false
            } else {
                processBatch(batch)
                offset += batchSize
                
                // Reset context to free memory
                reset()
            }
        }
    }
}

// MARK: - Safe PredicateBuilder (No force unwrap)

public struct SafePredicateBuilder {
    
    public static func equals(_ key: String, value: CVarArg) -> NSPredicate {
        return NSPredicate(format: "%K == %@", key, value)
    }
    
    public static func equals(_ key: String, uuid: UUID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", key, uuid as CVarArg)
    }
    
    public static func equals(_ key: String, int: Int) -> NSPredicate {
        return NSPredicate(format: "%K == %d", key, int)
    }
    
    public static func contains(_ key: String, value: String, options: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive]) -> NSPredicate {
        return NSPredicate(format: "%K CONTAINS[cd] %@", key, value)
    }
    
    public static func and(_ predicates: NSPredicate...) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    public static func or(_ predicates: NSPredicate...) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
}

// MARK: - Example Usage

/*
 
// Model with improved protocol
struct TrafficEvent: CoreDataKit, BatchCoreDataOperations {
    typealias objCoreData = TrafficEventEntity
    
    let id: UUID
    let name: String
    let timestamp: Date
    
    var entityName: String { "TrafficEventEntity" }
    var uniqueIdentifier: String { id.uuidString }
    
    func convertToCoreData(context: NSManagedObjectContext) throws -> TrafficEventEntity {
        let entity = TrafficEventEntity(context: context)
        entity.id = id
        entity.name = name
        entity.timestamp = timestamp
        return entity
    }
    
    func updateCoreData(_ object: TrafficEventEntity, context: NSManagedObjectContext) throws {
        object.name = name
        object.timestamp = timestamp
    }
    
    func checkExists(from context: NSManagedObjectContext) throws -> (Bool, [TrafficEventEntity]) {
        let predicate = SafePredicateBuilder.equals("id", uuid: id)
        return context.doesEntityExistNew(ofType: TrafficEventEntity.self, with: predicate)
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "timestamp": timestamp
        ]
    }
}

// Usage:

// 1. Single upsert - metrics
let event = TrafficEvent(id: UUID(), name: "Accident", timestamp: Date())
let result = try await event.upsert(for: context)
print(result.message) // "Inserted" or "Updated"
print(result.metrics?.duration) // Performance tracking

// 2. High-performance batch insert (1000+ items)
let events = (0..<1000).map { i in
    TrafficEvent(id: UUID(), name: "Event \(i)", timestamp: Date())
}
let batchResult = try await TrafficEvent.batchUpsert(events, context: context, chunkSize: 500)
print(batchResult.message) // "Inserted: 950, Updated: 50"

// 3. Memory-efficient streaming (process 100GB database)
try context.streamFetch(ofType: TrafficEventEntity.self, batchSize: 100) { batch in
    // Process each batch
    for event in batch {
        // Do something
    }
    // Memory automatically freed after each batch
}

// 4. Batch delete - predicate
let predicate = SafePredicateBuilder.and(
    SafePredicateBuilder.contains("name", value: "Accident"),
    NSPredicate(format: "timestamp < %@", Date().addingTimeInterval(-86400) as CVarArg)
)
let deleteResult = try await TrafficEvent.batchDelete(predicate: predicate, context: context)

 // Delete all entities of a type
 let deleteAllPredicate = NSPredicate(value: true) // Matches everything

 let result = try await TrafficEvent.batchDelete(
     predicate: deleteAllPredicate,
     context: context
 )

 print(result.message) // "Deleted 1500 objects"
 
*/
