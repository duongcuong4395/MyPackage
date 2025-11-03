//
//  CoreDataLogger.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

import CoreData
import OSLog

// MARK: - Logging System

/// Unified logging for CoreData operations
@available(iOS 16.0, *)
public struct CoreDataLogger {
    private static let logger = Logger(subsystem: "com.app.coredata", category: "operations")
    
    public enum LogLevel {
        case debug, info, warning, error
    }
    
    public static func log(_ message: String, level: LogLevel = .info, metadata: [String: Any] = [:]) {
        let metadataStr = metadata.isEmpty ? "" : " | \(metadata)"
        
        switch level {
        case .debug:
            logger.debug("\(message)\(metadataStr)")
        case .info:
            logger.info("\(message)\(metadataStr)")
        case .warning:
            logger.warning("\(message)\(metadataStr)")
        case .error:
            logger.error("\(message)\(metadataStr)")
        }
    }
}
