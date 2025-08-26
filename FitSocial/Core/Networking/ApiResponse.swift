//
//  ApiResponse.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

public struct ApiResponse<T: Decodable>: Decodable {
    public var result: T
    public let success: Bool
    public let message: String?
}

public struct Page<T: Decodable>: Decodable {
    public var content: [T]
    public let number: Int
    public let size: Int
    public let totalElements: Int
    public let totalPages: Int
    
    init(content: [T], number: Int, size: Int, totalElements: Int, totalPages: Int) {
        self.content = content
        self.number = number
        self.size = size
        self.totalElements = totalElements
        self.totalPages = totalPages
    }
}
