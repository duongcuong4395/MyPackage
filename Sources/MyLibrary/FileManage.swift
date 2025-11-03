//
//  FileManage.swift
//  MyLibrary
//
//  Created by Macbook on 2/1/25.
//

import Foundation
import SwiftUI

public protocol FileManaging {
    func load<T: Decodable>(by path: String) -> T?
    func load<T: Decodable>(by path: String, completion: @escaping @Sendable (T?) -> Void)

}

public class FileManage: FileManaging {
    private let fileManager = FileManager.default
    private let trafficDirectory: URL
    
    public init() {
            if let bundlePath = Bundle.main.resourcePath {
                
                trafficDirectory = URL(fileURLWithPath: bundlePath).appendingPathComponent("Resources/Traffic")
            } else {
                fatalError("Resource path not found")
            }
        }
    
    public func load<T: Decodable>(by path: String) -> T? {
        guard let fileURL = Bundle.main.url(forResource: path, withExtension: nil),
               let data = try? Data(contentsOf: fileURL),
               let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
                    return nil
                }
         return decodedData
    }
    
    public func load<T: Decodable>(by path: String, completion: @escaping @Sendable (T?) -> Void) {
        DispatchQueue.global(qos: .background).async {
             guard let fileURL = Bundle.main.url(forResource: path, withExtension: nil),
                   let data = try? Data(contentsOf: fileURL),
                   let decodedData = try? JSONDecoder().decode(T.self, from: data) else {
                 DispatchQueue.main.async {
                     completion(nil)
                 }
                 return
             }
             DispatchQueue.main.async {
                 completion(decodedData)
             }
         }
    }
}


// MARK: - Manage Json File
extension FileManage {
    public func readJSONFile(named fileName: String) -> Data? {
        let fileURL = trafficDirectory.appendingPathComponent("\(fileName).json")
        return try? Data(contentsOf: fileURL)
    }

    public func writeJSONFile(named fileName: String, data: Data) {
        let fileURL = trafficDirectory.appendingPathComponent("\(fileName).json")
        do {
            try data.write(to: fileURL)
        } catch {
            print("Error writing JSON file: \(error)")
        }
    }

    public func deleteJSONFile(named fileName: String) {
        let fileURL = trafficDirectory.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Error deleting JSON file: \(error)")
            }
        }
    }
    
    
    public func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public func getBusDataFilePath(with fileName: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    public func getTrafficDataFilePath(with fileName: String) -> URL {
        let directory = getDocumentsDirectory().appendingPathComponent("Resources/Traffic")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directory: \(error)")
        }
        return directory.appendingPathComponent(fileName)
    }
}
