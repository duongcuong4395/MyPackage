//
//  CoreDataExample.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

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
