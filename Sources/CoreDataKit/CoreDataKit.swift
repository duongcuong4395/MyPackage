//
//  CoreDataKit.swift
//  MyLibrary
//
//  Created by Macbook on 29/10/25.
//

//
//  CoreDataKit+Improvements.swift
//  Enhanced version with performance, concurrency, and observability improvements
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
    /// Handles both contexts with parent (NSPersistentContainer) and without parent (SwiftUI viewContext)
    func upsert(for context: NSManagedObjectContext) async throws -> OperationResult {
        let startTime = Date()
        
        // Check if context has a parent - if not, use context directly
        // SwiftUI's viewContext is a root context without parent
        let workingContext: NSManagedObjectContext
        let shouldUsePool = context.parent != nil
        
        if shouldUsePool {
            let pool = CoreDataContextPool.shared
            workingContext = pool.getContext(parent: context)
        } else {
            workingContext = context
        }
        
        let cleanup: () -> Void = {
            if shouldUsePool {
                CoreDataContextPool.shared.returnContext(workingContext)
            }
        }
        
        defer {
            cleanup()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            workingContext.perform {
                do {
                    // Atomic check-and-update trong cùng 1 transaction
                    let (exists, objects) = try self.checkExists(from: workingContext)
                    
                    if exists, let existingObject = objects.first {
                        // Update
                        try self.updateCoreData(existingObject, context: workingContext)
                        
                        if workingContext.hasChanges {
                            try workingContext.save()
                            // Only save parent context if we have one
                            if shouldUsePool && context.hasChanges {
                                try context.save()
                            }
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
                        _ = try self.convertToCoreData(context: workingContext)
                        
                        try workingContext.save()
                        // Only save parent context if we have one
                        if shouldUsePool && context.hasChanges {
                            try context.save()
                        }
                        
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
    
    /// Safe delete operation - handles both contexts with parent and without parent
    func delete(for context: NSManagedObjectContext) async throws -> OperationResult {
        let startTime = Date()
        
        // Check if context has a parent - if not, use context directly
        // SwiftUI's viewContext is a root context without parent
        let workingContext: NSManagedObjectContext
        let shouldUsePool = context.parent != nil
        
        if shouldUsePool {
            let pool = CoreDataContextPool.shared
            workingContext = pool.getContext(parent: context)
        } else {
            workingContext = context
        }
        
        let cleanup: () -> Void = {
            if shouldUsePool {
                CoreDataContextPool.shared.returnContext(workingContext)
            }
        }
        
        defer {
            cleanup()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            workingContext.perform {
                do {
                    let (exists, objects) = try self.checkExists(from: workingContext)
                    
                    guard exists, let objectToDelete = objects.first else {
                        continuation.resume(returning: OperationResult(
                            success: false,
                            message: "Not found"
                        ))
                        return
                    }
                    
                    workingContext.delete(objectToDelete)
                    
                    if workingContext.hasChanges {
                        try workingContext.save()
                        // Only save parent context if we have one
                        if shouldUsePool && context.hasChanges {
                            try context.save()
                        }
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
