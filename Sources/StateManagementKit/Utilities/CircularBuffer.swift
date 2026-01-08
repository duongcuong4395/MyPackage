//
//  CircularBuffer.swift
//  MyLibrary
//
//  Created by Macbook on 8/1/26.
//

import Foundation

/// Circular buffer for undo/redo to prevent memory leaks
internal struct CircularBuffer<T> {
    private var buffer: [T]
    private let capacity: Int
    private var startIndex = 0
    private var count = 0
    
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = []
        self.buffer.reserveCapacity(capacity)
    }
    
    mutating func append(_ element: T) {
        if count < capacity {
            buffer.append(element)
            count += 1
        } else {
            buffer[startIndex] = element
            startIndex = (startIndex + 1) % capacity
        }
    }
    
    mutating func removeLast() -> T? {
        guard count > 0 else { return nil }
        count -= 1
        let index = (startIndex + count) % capacity
        return buffer[index]
    }
    
    mutating func removeAll() {
        buffer.removeAll(keepingCapacity: true)
        count = 0
        startIndex = 0
    }
    
    var isEmpty: Bool { count == 0 }
    var isFull: Bool { count == capacity }
}
