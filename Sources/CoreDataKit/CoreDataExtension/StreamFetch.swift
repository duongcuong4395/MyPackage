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

extension NSManagedObjectContext {
    
    public func doesEntityExist<Entity: NSManagedObject>(ofType entityType: Entity.Type, with predicate: NSPredicate?) -> (result: Bool, models: [Entity]) {
        do {
            let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: entityType))
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            
            let results = try self.fetch(fetchRequest)
            
            return (!results.isEmpty, results)
        } catch {
            print("Error fetching: \(error)")
            return (false, [])
        }
    }
    
    public func getEntities<Entity: NSManagedObject>(ofType entityType: Entity.Type, with condition: NSPredicate?) -> (result: Bool, models: [Entity]) {
        let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: entityType))
        fetchRequest.predicate = condition

        do {
            let results = try self.fetch(fetchRequest)
            return (!results.isEmpty, results)
        } catch {
            print("Error fetching: \(error)")
            return (false, [])
        }
    }
    
    public func removeAllEntities<Entity: NSManagedObject>(ofType entityType: Entity.Type) -> Bool {
            let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: entityType))
            
            do {
                let results = try self.fetch(fetchRequest)
                
                for object in results {
                    self.delete(object)
                }
                
                try self.save()
                
                return true
            } catch {
                print("Error removing all entities: \(error)")
                return false
            }
        }
}
