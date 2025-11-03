//
//  CoreDataError.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

import CoreData

// MARK: - Improved Error Types
public enum CoreDataError: LocalizedError {
    case conversionFailed(String)
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case objectNotFound
    case batchOperationFailed(succeeded: Int, failed: Int, errors: [Error])
    case invalidPredicate
    case concurrencyConflict(String)
    case validationFailed([String: String])
    
    public var errorDescription: String? {
        switch self {
        case .conversionFailed(let details):
            return "Conversion failed: \(details)"
        case .fetchFailed(let details):
            return "Fetch failed: \(details)"
        case .saveFailed(let details):
            return "Save failed: \(details)"
        case .deleteFailed(let details):
            return "Delete failed: \(details)"
        case .objectNotFound:
            return "Object not found"
        case .batchOperationFailed(let succeeded, let failed, let errors):
            return "Batch: \(succeeded) OK, \(failed) failed. First error: \(errors.first?.localizedDescription ?? "unknown")"
        case .invalidPredicate:
            return "Invalid predicate"
        case .concurrencyConflict(let details):
            return "Concurrency conflict: \(details)"
        case .validationFailed(let details):
            return "Validation failed: \(details)"
        }
    }
}
