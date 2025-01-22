//
//  GeminiAIModel.swift
//  MyLibrary
//
//  Created by Macbook on 22/1/25.
//

import Foundation


// MARK: - Gemini Status
public enum GeminiStatus {
    case NotExistsKey
    case ExistsKey
    case SendReqestFail
    case Success
}

// MARK: - For model
public struct GeminiAIModel: Codable {
    public var itemKey: String
    public var valueItem: String
    
    enum CodingKeys: String, CodingKey {
        case itemKey = "itemKey"
        case valueItem = "valueItem"
    }
    
    public init() {
        self.itemKey = ""
        self.valueItem = ""
    }
    
    public init(itemKey: String, valueItem: String) {
        self.itemKey = itemKey
        self.valueItem = valueItem
    }
}


