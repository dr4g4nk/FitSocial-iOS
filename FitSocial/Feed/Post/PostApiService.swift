//
//  PostApiService.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

public protocol PostApiService: APIService<Int, Post, Post, Post> {
    var publicPath: String { get }

    func prepareData(posts: [Post], privatePath: Bool) -> [Post]
    func prepareData(post: Post?, privatePath: Bool) -> Post?

    func getPublicById(_ id: Int) async throws -> ApiResponse<Post?>
    func getAllPublic(
        page: Int?,
        size: Int?,
        sort: String?,
        extraQuery: [URLQueryItem]
    )
        async throws -> ApiResponse<Page<Post>>

    func likePost(_ id: Int) async throws -> ApiResponse<Like>

    func getAllByUserId(
        userId: Int,
        page: Int?,
        size: Int?,
        sort: String?,
        extraQuery: [URLQueryItem]
    ) async throws -> ApiResponse<Page<Post>>

    func create(fields: [UploadField], files: [UploadFile]) async throws
        -> ApiResponse<Post?>
    func update(id: Int, fields: [UploadField], files: [UploadFile])
        async throws -> ApiResponse<Post?>
}

extension PostApiService {

    public func prepareData(posts: [Post], privatePath: Bool = true) -> [Post] {
        return posts.map { post in
            post.copy {
                $0.media = post.media.map { media in
                    media.copy { m in
                        m.url = m.url(isAuthenticated: privatePath)
                    }
                }
                $0.author = $0.author.copy({ user in
                    user.avatarUrl = user.avatarUrl(privateAccess: privatePath)
                })

            }
        }
    }
    public func prepareData(post: Post?, privatePath: Bool = true) -> Post? {
        return post?.copy {
            $0.media = $0.media.map { media in
                media.copy { m in
                    m.url = m.url(isAuthenticated: privatePath)
                }
            }
            $0.author = $0.author.copy({ user in
                user.avatarUrl = user.avatarUrl(privateAccess: privatePath)
            })

        }

    }

    @discardableResult
    public func getAllPublic(
        page: Int? = nil,
        size: Int? = nil,
        sort: String? = nil,
        extraQuery: [URLQueryItem] = [],
    ) async throws -> ApiResponse<Page<Post>> {
        var query = extraQuery
        if let page {
            query.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let size {
            query.append(URLQueryItem(name: "size", value: String(size)))
        }
        if let sort {
            query.append(URLQueryItem(name: "sort", value: String(sort)))
        }
        return try await api.get(
            "\(publicPath)",
            query: query,
            requiresAuth: false
        )
    }

    @discardableResult
    public func getPublicById(_ id: Int) async throws -> ApiResponse<Post?> {
        try await api.get("\(publicPath)/\(id)", requiresAuth: false)
    }

    @discardableResult
    public func likePost(_ id: Int) async throws -> ApiResponse<Like> {
        try await api.send(
            APIRequest(
                path: "\(basePath)/\(id)/like",
                method: .post,
                requiresAuth: true
            )
        )
    }

    @discardableResult
    public func getAllByUserId(
        userId: Int,
        page: Int?,
        size: Int?,
        sort: String? = nil,
        extraQuery: [URLQueryItem] = []
    ) async throws -> ApiResponse<Page<Post>> {
        var query = extraQuery
        if let page {
            query.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let size {
            query.append(URLQueryItem(name: "size", value: String(size)))
        }
        if let sort {
            query.append(URLQueryItem(name: "sort", value: String(sort)))
        } else {
            query.append(URLQueryItem(name: "sort", value: "id,Desc"))
        }

        var response: ApiResponse<Page<Post>> = try await api.get(
            "\(basePath)/user/\(userId)",
            query: query
        )
        let data = prepareData(
            posts: response.result.content,
            privatePath: true
        )
        response.result.content = data

        return response
    }

    public func create(fields: [UploadField], files: [UploadFile]) async throws
        -> ApiResponse<Post?>
    {
        var response: ApiResponse<Post?> = try await api.post(
            "\(basePath)/create",
            fields: fields,
            files: files
        )

        response.result = prepareData(post: response.result, privatePath: true)

        return response
    }

    public func update(id: Int, fields: [UploadField], files: [UploadFile])
        async throws -> ApiResponse<Post?>
    {
        var response: ApiResponse<Post?> = try await api.put(
            "\(basePath)/update/\(id)",
            fields: fields,
            files: files
        )

        response.result = prepareData(post: response.result, privatePath: true)

        return response
    }
}

final class PostApiServiceImpl: PostApiService {

    let basePath = "api/post"
    let publicPath = "public/post"
    let api: APIClient
    let session: UserSession

    init(api: APIClient, session: UserSession) {
        self.api = api
        self.session = session
    }

    @discardableResult
    public func _getAll(
        page: Int?,
        size: Int?,
        sort: String?,
        extraQuery: [URLQueryItem],
        requiresAuth: Bool
    ) async throws -> ApiResponse<Page<Model>> {
        let isLoggedIn = try await session.isLoggedIn()

        var query = extraQuery
        if let page {
            query.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let size {
            query.append(URLQueryItem(name: "size", value: String(size)))
        }
        if let sort {
            query.append(URLQueryItem(name: "sort", value: String(sort)))
        } else {
            query.append(URLQueryItem(name: "sort", value: "id,Desc"))
        }
        let path = isLoggedIn ? basePath : publicPath
        var data: ApiResponse<Page<Post>> = try await api.get(
            "\(path)",
            query: query,
            requiresAuth: isLoggedIn
        )
        let content = prepareData(
            posts: data.result.content,
            privatePath: isLoggedIn
        )

        data.result.content = content

        return data
    }

    public func _getById(_ id: Int, requiresAuth: Bool) async throws
        -> ApiResponse<Post?>
    {
        let isLogedIn = try await session.isLoggedIn()

        let path = isLogedIn ? basePath : publicPath
        var response: ApiResponse<Post?> = try await api.get(
            "\(path)/\(id)",
            requiresAuth: isLogedIn
        )
        let data = prepareData(post: response.result, privatePath: isLogedIn)
        response.result = data

        return response
    }

}
