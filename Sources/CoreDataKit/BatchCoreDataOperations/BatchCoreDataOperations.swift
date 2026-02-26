//
//  BatchCoreDataOperations.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

import CoreData

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
                    continuation.resume(
                        throwing:
                            CoreDataError.batchOperationFailed(successes: 0, failures: objects.count, underlying: [error]
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
