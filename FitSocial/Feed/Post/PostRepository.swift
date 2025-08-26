//
//  PostRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

public protocol PostRepository: Repository<Int, Post, Post, Post>
where Service: PostApiService {

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
}

public class PostRepositoryImpl<Service: PostApiService>: PostRepository {
    public var apiService: Service
    private let session: UserSession
    private let localStore: PostLocalStore

    init(_ apiService: Service, sesson: UserSession, localStore: PostLocalStore)
    {
        self.apiService = apiService
        self.session = sesson
        self.localStore = localStore
    }

    public func likePost(postId: Int) async throws {
        let _ = try await apiService.likePost(postId)
    }

    public func getAll(page: Int?, size: Int?) async throws -> Page<Post> {
        do {
            let resultPage = try await apiService.getAll(page: page, size: size)
            return resultPage.result
        } catch {
            if let page = page, page != 0 {
                return Page(
                    content: [],
                    number: page,
                    size: size!,
                    totalElements: 0,
                    totalPages: page
                )
            }
            let data = try await localStore.latest(limit: 30)
            return Page(
                content: data,
                number: 0,
                size: 30,
                totalElements: 30,
                totalPages: 1
            )
        }
    }

    public func getAllByUserId(userId: Int, page: Int?, size: Int?) async throws
        -> Page<Post>
    {
        let resultPage = try await apiService.getAllByUserId(
            userId: userId,
            page: page,
            size: size
        )
        return resultPage.result
    }

    public func create(post: PostDto, media: [MediaUi]) async throws
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
                        filename: m.id.uuidString,
                        mimeType: m.mimeType!
                    )
                case .image(let data):
                    return UploadFile(
                        name: "mediaFiles",
                        filename: m.id.uuidString,
                        mimeType: m.mimeType!,
                        data: data
                    )
                default: return nil
                }
            }
        )

        return response
    }

    public func update(
        id: Int,
        post: PostDto,
        newMediaOrder: [Int],
        newMedia: [MediaUi]
    ) async throws -> ApiResponse<Post?> {
        return try await apiService.update(
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
                        filename: m.id.uuidString,
                        mimeType: m.mimeType!
                    )
                case .image(let data):
                    return UploadFile(
                        name: "mediaFiles",
                        filename: m.id.uuidString,
                        mimeType: m.mimeType!,
                        data: data
                    )
                default: return nil
                }
            }
        )
    }
}
