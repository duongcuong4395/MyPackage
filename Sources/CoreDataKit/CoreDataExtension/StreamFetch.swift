//
//  StreamFetch.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

import CoreData

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
