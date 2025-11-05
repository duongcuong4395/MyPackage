//
//  CoreDataManage.swift
//  MyLibrary
//
//  Created by Macbook on 2/1/25.
//

import Foundation
import CoreData

public protocol ModelCoreData: Codable {
    associatedtype objCoreData: NSManagedObject
    
    func convertToCoreData(for context: NSManagedObjectContext) throws -> objCoreData
    
    func checkExists(in context: NSManagedObjectContext
                     , complete: @escaping (Bool, [Any]) -> Void) throws
    
    func updateCoreData(_ existingObj: objCoreData, in context: NSManagedObjectContext) throws
}

public extension ModelCoreData {
    public func save(into context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("save model into core data error: ", error.localizedDescription)
        }
    }
    
    public func removeAllCoreData(by entityName: String
                           , into context: NSManagedObjectContext
                           , completion: @escaping (Result<Bool, Error>) -> Void
    ) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let result = try! context.fetch(fetchRequest)
            for obj in result {
                guard let objData = obj as? NSManagedObject else { continue }
                
                removeItem(by: objData, into: context)
            }
            completion(.success(true))
        } catch {
            print("Remove All core data for: ", entityName)
            completion(.failure(error))
        }
    }
    
    public func removeItem(by obj: NSManagedObject
                    , into context: NSManagedObjectContext) {
        context.delete(obj)
        save(into: context)
    }
    
    public func removeItem(into context: NSManagedObjectContext, complete: @escaping ( Result<Bool, Error>) -> Void) {
        
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        backgroundContext.perform {
            do {
                try self.checkExists(in: backgroundContext) {
                    check, objs in
                    if check {
                        if objs.count <= 0 {
                            complete(.success(true))
                            return
                        }
                        removeItem(by: objs[0] as! NSManagedObject, into: backgroundContext)
                        
                        self.save(into: backgroundContext)
                        self.save(into: context)
                        
                        complete(.success(true))
                    } else {
                        complete(.success(true))
                    }
                }
            } catch {
                
            }
        }
        
        
    }
    
    public func add(into context: NSManagedObjectContext
             , completion: @escaping (Result<Bool, Error>) -> Void) {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        backgroundContext.parent = context
        
        backgroundContext.perform {
            do {
                try self.checkExists(in: backgroundContext, complete: { sucess, objs in
                    if sucess {
                        completion(.success(true))
                    } else {
                        _ = try? convertToCoreData(for: backgroundContext)
                        self.save(into: backgroundContext)
                        self.save(into: context)
                        completion(.success(true))
                    }
                })
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func toggleAddAndRemove(for context: NSManagedObjectContext, complete: @escaping (Bool, Bool) -> Void) {
        try? checkExists(in: context, complete: { success, objs in
            if success {
                removeItem(into: context) { result in
                    switch result {
                    case .success(let res):
                        complete(success, res)
                    case .failure(_):
                        complete(success, false)
                    }
                }
            } else {
                add(into: context) { result in
                    switch result {
                    case .success(let res):
                        complete(success, res)
                    case .failure(_):
                        complete(success, false)
                    }
                }
            }
        })
        
    }
    
}

extension ModelCoreData {
    public func updateOrAdd(into context: NSManagedObjectContext, completion: @escaping (Result<Bool, Error>) -> Void) {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        backgroundContext.perform {
            do {
                try self.checkExists(in: backgroundContext) { exists, objs in
                    if exists {
                        if let existingObj = objs.first {
                            do {
                                try self.updateCoreData(existingObj as! Self.objCoreData, in: backgroundContext)
                                self.save(into: backgroundContext)
                                self.save(into: context)
                                completion(.success(true))
                            } catch {
                                completion(.failure(error))
                            }
                        } else {
                            completion(.failure(NSError(domain: "CoreDataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Object not found"])))
                        }
                    } else {
                        do {
                            let newObj = try self.convertToCoreData(for: backgroundContext)
                            self.save(into: backgroundContext)
                            self.save(into: context)
                            completion(.success(true))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}
