//
//  MutationSystem.swift
//  MyLibrary
//
//  Created by Macbook on 8/1/26.
//

import Foundation

// MARK: - TypeSafeMutation

/// Type-safe mutation that prevents runtime crashes
public struct TypeSafeMutation<Model: Equatable>: @unchecked Sendable {
    private let transform: @Sendable (Model) -> Model
    
    public init(_ transform: @escaping @Sendable (Model) -> Model) {
        self.transform = transform
    }
    
    public func apply(to model: Model) -> Model {
        transform(model)
    }
    
    public func merge(with other: TypeSafeMutation<Model>) -> TypeSafeMutation<Model> {
        TypeSafeMutation { model in
            other.apply(to: self.apply(to: model))
        }
    }
}

// MARK: - UpdateBuilder

/// Type-safe update builder
public struct UpdateBuilder<Model>: Sendable{
    private var mutations: [@Sendable (inout Model) -> Void] = []
    
    public init() {}
    
    public mutating func set<Value>(
        _ keyPath: WritableKeyPath<Model, Value> & Sendable,
        to value: Value
    ) where Value: Sendable {
        mutations.append { model in
            model[keyPath: keyPath] = value
        }
    }
    
    public mutating func apply(_ transform: @escaping @Sendable (inout Model) -> Void) {
        mutations.append(transform)
    }
    
    public func build() -> @Sendable (inout Model) -> Void {
        return { model in
            for mutation in self.mutations {
                mutation(&model)
            }
        }
    }
}
