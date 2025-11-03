//
//  RelationshipAwareCoreData.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

// Extension: Support for Core Data Relationships

import CoreData

// MARK: - Relationship-Aware Protocol

@available(iOS 16.0, *)
public protocol RelationshipAwareCoreData: CoreDataKit {
    
    /// Indicates if this entity has relationships that need special handling
    var hasRelationships: Bool { get }
    
    /// Handle relationship updates (called after main update)
    func updateRelationships(_ object: objCoreData, context: NSManagedObjectContext) throws
    
    /// Handle relationship cascade delete (called before delete)
    func cleanupRelationships(_ object: objCoreData, context: NSManagedObjectContext) throws
}

@available(iOS 16.0, *)
public extension RelationshipAwareCoreData {
    
    // Default implementations
    var hasRelationships: Bool { false }
    
    func updateRelationships(_ object: objCoreData, context: NSManagedObjectContext) throws {
        // Default: No-op
    }
    
    func cleanupRelationships(_ object: objCoreData, context: NSManagedObjectContext) throws {
        // Default: No-op
    }
    
    /// Enhanced upsert with relationship support
    func upsertWithRelationships(for context: NSManagedObjectContext) async throws -> OperationResult {
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
                    
                    if exists, let existingObject = objects.first {
                        // Update main attributes
                        try self.updateCoreData(existingObject, context: backgroundContext)
                        
                        // Update relationships
                        if self.hasRelationships {
                            try self.updateRelationships(existingObject, context: backgroundContext)
                        }
                        
                        if backgroundContext.hasChanges {
                            try backgroundContext.save()
                            try context.save()
                        }
                        
                        let metrics = PerformanceMetrics(
                            operation: "upsert_with_relationships",
                            duration: Date().timeIntervalSince(startTime),
                            objectCount: 1,
                            success: true
                        )
                        
                        continuation.resume(returning: OperationResult(
                            success: true,
                            message: "Updated with relationships",
                            metrics: metrics
                        ))
                    } else {
                        // Insert
                        let newObject = try self.convertToCoreData(context: backgroundContext)
                        
                        // Set relationships after creation
                        if self.hasRelationships {
                            try self.updateRelationships(newObject, context: backgroundContext)
                        }
                        
                        try backgroundContext.save()
                        try context.save()
                        
                        let metrics = PerformanceMetrics(
                            operation: "insert_with_relationships",
                            duration: Date().timeIntervalSince(startTime),
                            objectCount: 1,
                            success: true
                        )
                        
                        continuation.resume(returning: OperationResult(
                            success: true,
                            message: "Inserted with relationships",
                            metrics: metrics
                        ))
                    }
                } catch {
                    CoreDataLogger.log("Upsert with relationships failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Enhanced delete with relationship cleanup
    func deleteWithRelationships(for context: NSManagedObjectContext) async throws -> OperationResult {
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
                    
                    // Cleanup relationships first
                    if self.hasRelationships {
                        try self.cleanupRelationships(objectToDelete, context: backgroundContext)
                    }
                    
                    // Then delete
                    backgroundContext.delete(objectToDelete)
                    
                    if backgroundContext.hasChanges {
                        try backgroundContext.save()
                        try context.save()
                    }
                    
                    let metrics = PerformanceMetrics(
                        operation: "delete_with_relationships",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: 1,
                        success: true
                    )
                    
                    continuation.resume(returning: OperationResult(
                        success: true,
                        message: "Deleted with relationships cleaned",
                        metrics: metrics
                    ))
                } catch {
                    CoreDataLogger.log("Delete with relationships failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Batch Operations for Relationships (Manual Loop Required)

@available(iOS 16.0, *)
public extension BatchCoreDataOperations where Self: RelationshipAwareCoreData {
    
    /// Batch upsert for entities with relationships
    /// NOTE: Cannot use NSBatchInsertRequest - must loop manually
    static func batchUpsertWithRelationships(
        _ objects: [Self],
        context: NSManagedObjectContext,
        chunkSize: Int = 100 // Smaller chunks for relationships
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
                    
                    // Process in chunks
                    for chunk in stride(from: 0, to: objects.count, by: chunkSize) {
                        let end = min(chunk + chunkSize, objects.count)
                        let chunkObjects = Array(objects[chunk..<end])
                        
                        for object in chunkObjects {
                            let (exists, existing) = try object.checkExists(from: backgroundContext)
                            
                            if exists, let existingObject = existing.first {
                                // Update
                                try object.updateCoreData(existingObject, context: backgroundContext)
                                
                                if object.hasRelationships {
                                    try object.updateRelationships(existingObject, context: backgroundContext)
                                }
                                
                                totalUpdated += 1
                            } else {
                                // Insert
                                let newObject = try object.convertToCoreData(context: backgroundContext)
                                
                                if object.hasRelationships {
                                    try object.updateRelationships(newObject, context: backgroundContext)
                                }
                                
                                totalInserted += 1
                            }
                        }
                        
                        // Save chunk
                        if backgroundContext.hasChanges {
                            try backgroundContext.save()
                        }
                        
                        // Reset to free memory
                        backgroundContext.reset()
                    }
                    
                    // Final save
                    try context.save()
                    
                    let metrics = PerformanceMetrics(
                        operation: "batch_upsert_relationships",
                        duration: Date().timeIntervalSince(startTime),
                        objectCount: objects.count,
                        success: true
                    )
                    
                    CoreDataLogger.log(
                        "Batch upsert with relationships completed",
                        metadata: [
                            "inserted": totalInserted,
                            "updated": totalUpdated
                        ]
                    )
                    
                    continuation.resume(returning: OperationResult(
                        success: true,
                        message: "Inserted: \(totalInserted), Updated: \(totalUpdated) (with relationships)",
                        metrics: metrics
                    ))
                    
                } catch {
                    CoreDataLogger.log("Batch with relationships failed: \(error)", level: .error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Example Usage

/*
 
 // Example 1: Parent with Children relationship
 struct Parent: CoreDataKit, BatchCoreDataOperations, RelationshipAwareCoreData {
     typealias objCoreData = ParentEntity
     
     let id: UUID
     let name: String
     var children: [Child] // Relationship
     
     var entityName: String { "ParentEntity" }
     var uniqueIdentifier: String { id.uuidString }
     var hasRelationships: Bool { true } // Flag this has relationships
     
     func convertToCoreData(context: NSManagedObjectContext) throws -> ParentEntity {
         let entity = ParentEntity(context: context)
         entity.id = id
         entity.name = name
         return entity
     }
     
     func updateCoreData(_ object: ParentEntity, context: NSManagedObjectContext) throws {
         object.name = name
         // Relationships handled separately
     }
     
     func updateRelationships(_ object: ParentEntity, context: NSManagedObjectContext) throws {
         // Clear old relationships
         if let oldChildren = object.children as? Set<ChildEntity> {
             object.removeFromChildren(oldChildren)
         }
         
         // Add new relationships
         for childData in children {
             let (exists, existingChildren) = try childData.checkExists(from: context)
             
             let childEntity: ChildEntity
             if exists, let existing = existingChildren.first {
                 try childData.updateCoreData(existing, context: context)
                 childEntity = existing
             } else {
                 childEntity = try childData.convertToCoreData(context: context)
             }
             
             object.addToChildren(childEntity)
         }
     }
     
     func cleanupRelationships(_ object: ParentEntity, context: NSManagedObjectContext) throws {
         // Optional: Manual cleanup if needed
         // Core Data's delete rule will handle cascade automatically
     }
     
     func checkExists(from context: NSManagedObjectContext) throws -> (Bool, [ParentEntity]) {
         let predicate = SafePredicateBuilder.equals("id", uuid: id)
         return context.doesEntityExistNew(ofType: ParentEntity.self, with: predicate)
     }
     
     func toDictionary() -> [String: Any] {
         // NOTE: Cannot include relationships in dictionary for batch insert
         return [
             "id": id,
             "name": name
         ]
     }
 }
 
 // Usage:
 let parent = Parent(
     id: UUID(),
     name: "Parent 1",
     children: [
         Child(id: UUID(), name: "Child 1"),
         Child(id: UUID(), name: "Child 2")
     ]
 )
 
 // Upsert with relationships
 let result = try await parent.upsertWithRelationships(for: context)
 print(result.message) // "Inserted with relationships"
 
 // Batch upsert with relationships (manual loop)
 let parents = [parent1, parent2, parent3]
 let batchResult = try await Parent.batchUpsertWithRelationships(
     parents,
     context: context,
     chunkSize: 50
 )
 
 */
