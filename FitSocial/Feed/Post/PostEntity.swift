//
//  PostEntity.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import Foundation
import SwiftData

@Model
final class PostEntity : Identifiable {
    @Attribute(.unique) var id: Int
    var author: UserEntity
    var content: String
    var likeCount: Int
    var isPublic: Bool
    var createdAt: Date
    var isLiked: Bool
    var activity: ActivityEntity?
    @Relationship(deleteRule: .cascade) var media: [MediaEntity]

    var fetchedAt: Date

    init(
        id: Int,
        author: UserEntity,
        content: String,
        createdAt: Date,
        likeCount: Int = 0,
        isPublic: Bool = false,
        isLiked: Bool,
        activity: ActivityEntity? = nil,
        media: [MediaEntity] = []
    ) {
        self.id = id
        self.author = author
        self.content = content
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.isPublic = isPublic
        self.isLiked = isLiked
        self.activity = activity
        self.media = media
        self.fetchedAt = Date()
    }
}

@Model
final class ActivityEntity : Identifiable {
    @Attribute(.unique) var id: Int
    var type: String
        var startTime: Date
        var endTime: Date?
        var steps: Int?
        var distance: Double
    
    
    init(id: Int, type: String, startTime: Date, endTime: Date? = nil, steps: Int? = nil, distance: Double = 0.0) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.steps = steps
        self.distance = distance
    }
}
