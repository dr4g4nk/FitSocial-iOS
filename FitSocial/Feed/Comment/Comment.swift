//
//  Comment.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 8. 2025..
//

import Foundation

public struct Comment : Identifiable, Equatable, Codable, Copyable {
    public let id: Int
    public var postId: Int
    public var content: String
    public var user: User?
    public var createdAt: Date
    
    init(id: Int, postId: Int = -1, content: String, user: User? = nil, createdAt: Date = Date.now) {
        self.id = id
        self.postId = postId
        self.content = content
        self.user = user
        self.createdAt = createdAt
    }
}
