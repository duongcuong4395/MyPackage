//
//  PredicateBuilder.swift
//  MyLibrary
//
//  Created by Macbook on 3/11/25.
//

import CoreData

// MARK: - Safe PredicateBuilder (No force unwrap)

public struct SafePredicateBuilder {
    
    public static func equals(_ key: String, value: CVarArg) -> NSPredicate {
        return NSPredicate(format: "%K == %@", key, value)
    }
    
    public static func equals(_ key: String, uuid: UUID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", key, uuid as CVarArg)
    }
    
    public static func equals(_ key: String, int: Int) -> NSPredicate {
        return NSPredicate(format: "%K == %d", key, int)
    }
    
    public static func contains(_ key: String, value: String, options: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive]) -> NSPredicate {
        return NSPredicate(format: "%K CONTAINS[cd] %@", key, value)
    }
    
    public static func and(_ predicates: NSPredicate...) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    public static func or(_ predicates: NSPredicate...) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
}
