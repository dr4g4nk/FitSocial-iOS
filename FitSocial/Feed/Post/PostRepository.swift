//
//  PostRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

protocol PostRepository: Repository<Int, Post, Post, Post> where Service: PostApiService {
    func likePost(postId: Int) async throws
    func getAllByUserId(userId: Int, page: Int?, size: Int?) async throws
        -> Page<Post>
    func create(post: PostDto, media: [MediaUi]) async throws -> ApiResponse<
        Post?
    >
    func update(
        id: Int,
        post: PostDto,
        newMediaOrder: [Int],
        newMedia: [MediaUi]
    ) async throws -> ApiResponse<Post?>

    func getLocalPost(userId: Int, limit: Int?) async throws
        -> [Post]
    func getLocalPost(limit: Int?) async throws
        -> [Post]
}

class PostRepositoryImpl<Service: PostApiService>: PostRepository {
    public var apiService: Service
    private let session: UserSession
    private let localStore: PostLocalStore

    init(_ apiService: Service, sesson: UserSession, localStore: PostLocalStore)
    {
        self.apiService = apiService
        self.session = sesson
        self.localStore = localStore
    }

    func likePost(postId: Int) async throws {
        let _ = try await apiService.likePost(postId)
    }

    func _getAll(page: Int?, size: Int?, sort: String?, query: [URLQueryItem]) async throws -> Page<Post>{
        let resultPage = try await apiService.getAll(page: page, size: size, sort: sort, extraQuery: query)
        if page == 0 && resultPage.success {
            Task {
                do {
                    try await localStore.upsert(
                        posts: resultPage.result.content
                    )
                } catch {
                    print(error.localizedDescription)
                }
            }
        }

        return resultPage.result
    }

    func getAllByUserId(userId: Int, page: Int?, size: Int?) async throws
        -> Page<Post>
    {
        let resultPage = try await apiService.getAllByUserId(
            userId: userId,
            page: page,
            size: size
        )

        if page == 0 && resultPage.success {
            Task {
                do {
                    try await localStore.upsert(
                        posts: resultPage.result.content
                    )
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        return resultPage.result
    }

    func create(post: PostDto, media: [MediaUi]) async throws
        -> ApiResponse<Post?>
    {
        let response = try await apiService.create(
            fields: [.init(name: "post", value: post)],
            files: media.compactMap { m -> UploadFile? in
                switch m.kind {
                case .video(let url, _):
                    return UploadFile(
                        name: "mediaFiles",
                        fileURL: url,
                        filename: m.filename,
                        mimeType: m.mimeType!
                    )
                case .image(_, let url):
                    return UploadFile(
                        name: "mediaFiles",
                        fileURL: url,
                        filename: m.filename,
                        mimeType: m.mimeType!,
                    )
                default: return nil
                }
            }
        )
        
        if response.success, let post = response.result {
            Task{
                do{
                    try await localStore.upsert(posts: [post])
                } catch{}
            }
        }

        return response
    }

    func update(
        id: Int,
        post: PostDto,
        newMediaOrder: [Int],
        newMedia: [MediaUi]
    ) async throws -> ApiResponse<Post?> {
        let response = try await apiService.update(
            id: post.id,
            fields: [
                .init(name: "post", value: post),
                .init(name: "mediaOrder", value: newMediaOrder),
            ],
            files: newMedia.compactMap { m -> UploadFile? in
                switch m.kind {
                case .video(let url, _):
                    return UploadFile(
                        name: "mediaFiles",
                        fileURL: url,
                        filename: m.filename,
                        mimeType: m.mimeType!
                    )
                case .image(_, let url):
                    return UploadFile(
                        name: "mediaFiles",
                        fileURL: url,
                        filename: m.filename,
                        mimeType: m.mimeType!,
                    )
                default: return nil
                }
            }
        )
        
        if response.success, let post = response.result {
            Task{
                do{
                    try await localStore.upsert(posts: [post])
                } catch{}
            }
        }
        
        return response
    }

    let limit = 20
    func getLocalPost(userId: Int, limit: Int?) async throws -> [Post] {
        let isAuthenticated = try await session.isLoggedIn()

        var predicate: Predicate<PostEntity>?
        if isAuthenticated {
            predicate = #Predicate { p in
                p.author.id == userId
            }
        } else {
            predicate = #Predicate { p in
                p.isPublic == true && p.author.id == userId
            }
        }

        return try await localStore.latest(
            limit: limit ?? self.limit,
            predicate: predicate
        )
    }

    func getLocalPost(limit: Int?) async throws -> [Post] {
        let isAuthenticated = try await session.isLoggedIn()

        if !isAuthenticated {
            let predicate: Predicate<PostEntity>? = #Predicate { p in
                p.isPublic == true
            }
            return try await localStore.latest(
                limit: limit ?? self.limit,
                predicate: predicate
            )
        } else {
            return try await localStore.latest(
                limit: limit ?? self.limit,
                predicate: nil
            )
        }

    }
}
