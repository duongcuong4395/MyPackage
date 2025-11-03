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
    
    // Cập nhật đối tượng Core Data từ đối tượng Model
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
    // Hàm cập nhật hoặc thêm mới đối tượng vào Core Data
    public func updateOrAdd(into context: NSManagedObjectContext, completion: @escaping (Result<Bool, Error>) -> Void) {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        backgroundContext.perform {
            do {
                try self.checkExists(in: backgroundContext) { exists, objs in
                    if exists {
                        // Nếu đã tồn tại, cập nhật đối tượng cũ
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
                        // Nếu chưa tồn tại, tạo mới đối tượng
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

extension NSManagedObjectContext {
    
    public func doesEntityExist<Entity: NSManagedObject>(ofType entityType: Entity.Type, with predicate: NSPredicate?) -> (result: Bool, models: [Entity]) {
        do {
            let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: entityType))
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1 // Chỉ cần một kết quả để kiểm tra
            
            let results = try self.fetch(fetchRequest)
            //print("fetching.success: ", results)
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
                // Xóa tất cả các đối tượng đã lấy được
                for object in results {
                    self.delete(object)
                }
                
                // Lưu lại thay đổi vào context
                try self.save()
                
                return true
            } catch {
                print("Error removing all entities: \(error)")
                return false
            }
        }
}
