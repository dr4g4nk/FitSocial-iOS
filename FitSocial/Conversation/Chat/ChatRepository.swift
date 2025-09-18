//
//  ChatRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation
import SwiftData

protocol ChatRepository: Repository<Int, Chat, Chat, Chat> where Service : ChatApiService {
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<Chat>
    func create(chat: ChatDto, attachment: AttachmentDto?,onProgress: @escaping (Int64, Int64, Double) -> Void) async throws -> ApiResponse<Chat?>
    func createLocal(chat: Chat) throws
    
    func getLocalLatest(size: Int) async throws -> [Chat]
}

class ChatRepositoryImpl<Service: ChatApiService> : ChatRepository {
    var apiService: Service
    private let chatLocalStore: ChatLocalStore
    
    init(apiService: Service, modelContainer: ModelContainer) {
        self.apiService = apiService
        chatLocalStore = ChatLocalStore(container: modelContainer)
    }
    
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<Chat> {
        return try await apiService.getAllFiltered(page: page, size: size, sort: sort, filterValue: filterValue).result
    }
    
    func _getAll(page: Int?, size: Int?, sort: String?, query: [URLQueryItem]) async throws -> Page<Chat>
    {
        let resultPage = try await apiService.getAll(page: page, size: size, sort: sort, extraQuery: query)
        
        if page == 0 && resultPage.success {
            Task{
                do{
                    let chats = resultPage.result.content.map { c in
                        ChatEntity.fromDomain(from: c)
                    }
                    try await chatLocalStore.createBatch(chats)
                } catch{
                    print(error.localizedDescription)
                }
            }
        }
        
        return resultPage.result
    }
    
    
    func create(chat: ChatDto, attachment: AttachmentDto? = nil, onProgress:  @escaping (Int64, Int64, Double) -> Void = { sent, total, fraction in }) async throws -> ApiResponse<Chat?>{
        var file: UploadFile? = nil
        
        if attachment != nil {
            switch attachment?.kind {
            case .image(_, let url), .video(let url, _), .document(let url):
                file = .init(name: "attachment", fileURL: url, filename: attachment!.filename, mimeType:  attachment!.contentType ?? "")
            default: file = nil
            }
        }
        
        return try await apiService.api.post("\(apiService.basePath)/create", fields: [.init(name: "chat", value: chat)], files: file != nil ? [file!] : []
        ) { sent, total, fraction in
            onProgress(sent, total, fraction)
        }
    }
    
    func createLocal(chat: Chat) throws {
        Task{
            let chatEntity = ChatEntity.fromDomain(from: chat)
            try await chatLocalStore.create(chatEntity)
        }
    }
    
    func getLocalLatest(size: Int) async throws -> [Chat] {
        return try await chatLocalStore.fetchPaginated(offset: 0, limit: size, sortBy: [SortDescriptor(\ChatEntity.lastMessageTime, order: .reverse)]){ c in
            c.toDomain()
        }
    }
}
