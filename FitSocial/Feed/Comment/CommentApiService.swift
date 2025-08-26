//
//  CommentApiService.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 8. 2025..
//

import Foundation

public protocol CommentApiService: APIService<Int, Comment, Comment, Comment> {
    func getByPostId(
        _ postId: Int,
        page: Int?,
        size: Int?,
        sort: String?,
        extraQuery: [URLQueryItem]
    ) async throws -> ApiResponse<Page<Comment>>
}

public class CommentApiServiceImpl: CommentApiService {
    public let basePath: String
    public var api: APIClient
    public let session: UserSession

    init(api: APIClient, session: UserSession, basePath: String = "api/comment")
    {
        self.basePath = basePath
        self.session = session
        self.api = api
    }

    public func getByPostId(
        _ postId: Int,
        page: Int? = 0,
        size: Int? = 20,
        sort: String? = nil,
        extraQuery: [URLQueryItem] = [],
    ) async throws -> ApiResponse<Page<Comment>> {
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
        
        let isLoggedIn = try await session.isLoggedIn()
        
        var response: ApiResponse<Page<Comment>> = try await api.get(
            isLoggedIn ? "\(basePath)/post/\(postId)" : "public/post/\(postId)/comment",
            query: query,
            requiresAuth: isLoggedIn
        )
        
        response.result.content = response.result.content.map { comment in
            comment.copy{ c in
                if(c.user != nil){
                    c.user!.avatarUrl = c.user!.avatarUrl(privateAccess: isLoggedIn)
                }
            }
        }
        
        return response
    }
    
    public func _create(_ body: Comment, requiresAuth: Bool) async throws -> ApiResponse<Comment> {
        let isLoggedIn = try await session.isLoggedIn()
        var response: ApiResponse<Comment> = try await api.post(basePath, body: body, requiresAuth: true)
        response.result = response.result.copy({ c in
            if(c.user != nil){
                c.user!.avatarUrl = c.user!.avatarUrl(privateAccess: isLoggedIn)
            }
        })
        return response
    }
}
