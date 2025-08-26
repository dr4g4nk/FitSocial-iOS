//
//  MessageApiService.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol MessageApiService: APIService<Int, Message, MessageDto, MessageDto>{
    func get(chatId: Int, page: Int, size: Int, sort: String?) async throws -> ApiResponse<Page<Message>>
}

extension MessageApiService{
    public func get(chatId: Int, page: Int, size: Int, sort: String? = nil) async throws -> ApiResponse<Page<Message>>{
        var query:[URLQueryItem] = []
        query.append(URLQueryItem(name: "page", value: String(page)))
        query.append(URLQueryItem(name: "size", value: String(size)))
        if let sort { query.append(URLQueryItem(name: "sort", value: String(sort)))} else { query.append(URLQueryItem(name: "sort", value: "id,Desc")) }
        return try await api.get("\(basePath)/chat/\(chatId)", query: query, requiresAuth: true)
    }
}

class MessageApiServiceImpl: MessageApiService{
    var basePath: String
    var api: APIClient
    
    init(api: APIClient, basePath: String = "api/message") {
        self.api = api
        self.basePath = basePath
    }
}
