//
//  CoreDataContextPool.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

@preconcurrency import CoreData

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
