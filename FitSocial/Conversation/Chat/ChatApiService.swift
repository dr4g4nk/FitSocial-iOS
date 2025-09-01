//
//  ChatApiService.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol ChatApiService: APIService<Int, Chat, Chat, Chat> {
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> ApiResponse<Page<Chat>>
    
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
    
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String? = nil) async throws -> ApiResponse<Page<Chat>>{
        var query: [URLQueryItem] = []
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
        
        if filterValue != nil && !filterValue!.isEmpty {
            query.append(URLQueryItem(name: "value", value: filterValue))
        }
        
        return try await api.get("\(basePath)/filter", query: query, requiresAuth: true)
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
