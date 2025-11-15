//
//  AIStorageProtocol.swift
//  MyLibrary
//
//  Created by Macbook on 15/11/25.
//

import Foundation

@available(iOS 13.0, *)
// MARK: - Storage Protocol
public protocol AIStorageProtocol: Sendable {
    func saveKey(_ key: String) async throws
    func getKey() async throws -> String?
    func deleteKey() async throws
    func keyExists() async -> Bool
}

@available(iOS 13.0, *)
// MARK: - Keychain Storage (Recommended for production)
public actor KeychainAIStorage: AIStorageProtocol {
    private let service: String
    private let account: String
    
    public init(service: String = "com.aimanagekit.apikey", account: String = "gemini") {
        self.service = service
        self.account = account
    }
    
    public func saveKey(_ key: String) async throws {
        guard let data = key.data(using: .utf8) else {
            throw AIError.storageError("Failed to encode key")
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw AIError.storageError("Keychain save failed: \(status)")
        }
    }
    
    public func getKey() async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw AIError.storageError("Keychain fetch failed: \(status)")
        }
        
        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw AIError.storageError("Failed to decode key")
        }
        
        return key
    }
    
    public func deleteKey() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AIError.storageError("Keychain delete failed: \(status)")
        }
    }
    
    public func keyExists() async -> Bool {
        return (try? await getKey()) != nil
    }
}

@available(iOS 13.0, *)
// MARK: - UserDefaults Storage (For testing/development only)
public actor UserDefaultsAIStorage: AIStorageProtocol {
    private let key: String
    private let userDefaults: UserDefaults
    
    public init(key: String = "ai_api_key", userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults
    }
    
    public func saveKey(_ key: String) async throws {
        userDefaults.set(key, forKey: self.key)
    }
    
    public func getKey() async throws -> String? {
        userDefaults.string(forKey: key)
    }
    
    public func deleteKey() async throws {
        userDefaults.removeObject(forKey: key)
    }
    
    public func keyExists() async -> Bool {
        return (try? await getKey()) != nil
    }
}

@available(iOS 13.0, *)
// MARK: - Mock Storage (For testing)
public actor MockAIStorage: AIStorageProtocol {
    private var storedKey: String?
    
    public init(initialKey: String? = nil) {
        self.storedKey = initialKey
    }
    
    public func saveKey(_ key: String) async throws {
        storedKey = key
    }
    
    public func getKey() async throws -> String? {
        storedKey
    }
    
    public func deleteKey() async throws {
        storedKey = nil
    }
    
    public func keyExists() async -> Bool {
        storedKey != nil
    }
}
