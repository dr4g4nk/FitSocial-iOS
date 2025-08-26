//
//  Post.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

public struct Post: Identifiable, Codable, Hashable, Copyable {
    public static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }

    public let id: Int
    public var author: User
    public var content: String
    public var likeCount: Int?
    public var isPublic: Bool
    public var createdAt: Date
    public var isLiked: Bool?
    public var media: [Media]
    public var activity: Activity?

    public var authorName: String {
        [author.firstName, author.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    init(
        id: Int,
        author: User,
        content: String = "",
        likeCount: Int? = 0,
        isPublic: Bool = false,
        createdAt: Date = Date.now,
        isLiked: Bool? = false,
        media: [Media] = [],
        activity: Activity? = nil
    ) {
        self.id = id
        self.author = author
        self.content = content
        self.likeCount = likeCount
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.media = media
        self.activity = activity
    }
}

public struct PostDto : Identifiable, Codable, Hashable, Copyable {
    public var id: Int = 0
    public var content: String = ""
    public var isPublic: Bool = false
    public var media: [Media] = []
    public var activity: Activity? = nil
}

public struct Activity: Codable, Hashable, Equatable {
    public var id: Int
    public var type: String
    public var startTime: Date
    public var endTime: Date?
    public var steps: Int?
    public var distance: Double

    init(
        id: Int,
        type: String,
        startTime: Date,
        endTime: Date? = nil,
        steps: Int? = nil,
        distance: Double = 0.0
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.steps = steps
        self.distance = distance
    }
}
