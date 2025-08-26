//
//  ChatApiService.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol ChatApiService: APIService<Int, Chat, Chat, Chat> {
}

extension ChatApiService {
    @discardableResult
    func _getAll(
        page: Int? = nil,
        size: Int? = nil,
        sort: String? = nil,
        extraQuery: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> ApiResponse<Page<Model>> {
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
            query.append(
                URLQueryItem(name: "sort", value: "lastMessageTime,Desc")
            )
        }
        return try await api.get(
            "\(basePath)",
            query: query,
            requiresAuth: requiresAuth
        )
    }
}

class ChatApiServiceImpl: ChatApiService {
    var basePath: String
    var api: APIClient

    init(api: APIClient, basePath: String = "api/chat") {
        self.api = api
        self.basePath = basePath
    }
}
