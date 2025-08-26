//
//  MessageRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol MessageRepository: Repository<Int, Message, MessageDto, MessageDto> where Service : MessageApiService{
    
    func get(chatId: Int, page: Int, size: Int, sort: String?) async throws -> Page<Message>
    func create(message: MessageDto, attachment: Attachment) async throws -> Message?
}


class MessageRepositoryImpl<Service: MessageApiService> : MessageRepository{
    var apiService: Service
    
    init(apiService: Service) {
        self.apiService = apiService
    }
    
    func get(chatId: Int, page: Int, size: Int, sort: String? = nil) async throws -> Page<Message> {
        return try await apiService.get(chatId: chatId, page: page, size: size, sort: sort).result
    }
    
    func create(message: MessageDto, attachment: Attachment) async throws -> Message? {
        return try await apiService.api.post("\(apiService.basePath)/create", fields: [.init(name: "message", value: message)], files: [])
    }
    
    
}
