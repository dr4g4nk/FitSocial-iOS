//
//  PostLocalStore.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import Foundation
import SwiftData

@MainActor
protocol PostLocalStore {
    func latest(limit: Int, predicate: Predicate<PostEntity>?) async throws -> [Post]
    func upsert(posts: [Post]) async throws
}

@MainActor
final class PostLocalStoreImpl: PostLocalStore {
    private let context: ModelContext
    private let session: UserSession
    init(context: ModelContext, session: UserSession) {
        self.context = context
        self.session = session
    }

    func latest(limit: Int, predicate: Predicate<PostEntity>? = nil) async throws -> [Post] {
        let isLogedIn = try await session.isLoggedIn()

        var desc = FetchDescriptor<PostEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        desc.fetchLimit = limit
        return try context.fetch(desc).map { p in
            var user = User(
                id: p.author.id,
                firstName: p.author.firstName,
                lastName: p.author.lastName,
                avatarUrl: p.author.avatarUrl ?? ""
            )
            if user.avatarUrl == nil || (user.avatarUrl ?? "").isEmpty {
                user.avatarUrl = user.avatarUrl(privateAccess: isLogedIn)
            }
            let activity: Activity? =
                p.activity != nil
                ? Activity(
                    id: p.activity!.id,
                    type: p.activity!.type,
                    startTime: p.activity!.startTime,
                    endTime: p.activity!.endTime,
                    steps: p.activity!.steps,
                    distance: p.activity!.distance
                ) : nil
            let media: [Media] =
                p.media.isEmpty
                ? []
                : p.media.map { m in
                    var media = Media(
                        id: m.id,
                        postId: m.postId,
                        order: m.order,
                        mimeType: m.mimeType
                    )
                    media.url = media.url(isAuthenticated: isLogedIn)
                    return media
                }
            return Post(
                id: p.id,
                author: user,
                content: p.content,
                likeCount: p.likeCount,
                isPublic: p.isPublic,
                createdAt: p.createdAt,
                isLiked: p.isLiked,
                media: media,
                activity: activity
            )
        }
    }

    func upsert(posts: [Post]) async throws {
        let isLogedIn = try await session.isLoggedIn()

        for dto in posts {
            // User
            let user = try upsertUser(
                id: dto.author.id,
                first: dto.author.firstName,
                last: dto.author.lastName,
                avatar: dto.author.avatarUrl
            )

            var activity: ActivityEntity?

            if let a = dto.activity {
                activity = try upsertActivity(
                    id: a.id,
                    type: a.type,
                    startTime: a.startTime,
                    endTime: a.endTime,
                    steps: a.steps,
                    distance: a.distance
                )
            }

            // Post
            let post =
                try find(PostEntity.self, id: dto.id)
                ?? PostEntity(
                    id: dto.id,
                    author: user,
                    content: dto.content,
                    createdAt: dto.createdAt,
                    likeCount: dto.likeCount ?? 0,
                    isPublic: dto.isPublic,
                    isLiked: dto.isLiked ?? false,
                    activity: activity, media: []
                )
            post.content = dto.content
            post.createdAt = dto.createdAt
            post.likeCount = dto.likeCount ?? 0
            post.isLiked = dto.isLiked ?? false
            post.author = user
            post.fetchedAt = Date()

            // Media (jednostavan reset pa insert; možeš i pametniji diff)
            post.media.removeAll()
            for m in dto.media {
                let media =
                    try find(MediaEntity.self, id: m.id)
                    ?? MediaEntity(
                        id: m.id,
                        postId: m.postId,
                        order: m.order,
                        url: m.urlString(isAuthenticated: isLogedIn),
                        mimeType: m.mimeType,
                    )
                media.url = m.urlString(isAuthenticated: isLogedIn)
                media.order = m.order
                post.media.append(media)
            }

            context.insert(post)
        }
        try context.save()
    }

    // Helpers
    private func find<T: PersistentModel & Identifiable>(
        _ type: T.Type,
        id: T.ID
    ) throws -> T? where T.ID == Int {
        var d = FetchDescriptor<T>(
            predicate: #Predicate { $0.id == id }
        )
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    private func upsertUser(
        id: Int,
        first: String,
        last: String,
        avatar: String?
    ) throws -> UserEntity {
        if let u: UserEntity = try find(UserEntity.self, id: id) {
            u.firstName = first
            u.lastName = last
            u.avatarUrl = avatar ?? ""
            return u
        }
        let u = UserEntity(
            id: id,
            firstName: first,
            lastName: last,
            avatarUrl: avatar ?? ""
        )
        context.insert(u)
        return u
    }

    private func upsertActivity(
        id: Int,
        type: String,
        startTime: Date,
        endTime: Date?,
        steps: Int?,
        distance: Double
    ) throws -> ActivityEntity {
        if let a: ActivityEntity = try find(ActivityEntity.self, id: id) {
            a.type = type
            a.startTime = startTime
            a.endTime = endTime
            a.steps = steps
            a.distance = distance
            return a
        }
        let a = ActivityEntity(
            id: id,
            type: type,
            startTime: startTime,
            endTime: endTime,
            steps: steps,
            distance: distance
        )
        context.insert(a)
        return a
    }
}
