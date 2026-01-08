//
//  Protocols.swift
//  MyLibrary
//
//  Created by Macbook on 8/1/26.
//

import Foundation

// MARK: - DataSourceProtocol

/// Protocol for data sources (mockable for testing)
@available(iOS 13.0.0, *)
public protocol DataSourceProtocol<Model>: Sendable {
    associatedtype Model: Sendable
    func fetch() async throws -> [Model]
    func fetch(page: Int, pageSize: Int) async throws -> [Model]
}

// MARK: - PersistenceProtocol

/// Protocol for persistence layer
public protocol PersistenceProtocol<Model>: Sendable {
    associatedtype Model: Codable & Sendable
    func save(_ models: [Model], key: String) throws
    func load(key: String) throws -> [Model]?
}

// MARK: - UserDefaultsPersistence

/// Default UserDefaults persistence
public struct UserDefaultsPersistence<Model: Codable & Sendable>: PersistenceProtocol {
    public init() {}
    
    public func save(_ models: [Model], key: String) throws {
        let data = try JSONEncoder().encode(models)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    public func load(key: String) throws -> [Model]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try JSONDecoder().decode([Model].self, from: data)
    }
}
