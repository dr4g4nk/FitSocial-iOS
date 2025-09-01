//
//  ChatRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol ChatRepository: Repository<Int, Chat, Chat, Chat> where Service : ChatApiService {

    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<Entity>
    func create(chat: ChatDto, attachment: AttachmentDto?,onProgress: @escaping (Int64, Int64, Double) -> Void) async throws -> ApiResponse<Chat?>
}

class ChatRepositoryImpl<Service: ChatApiService> : ChatRepository {
    var apiService: Service
    
    init(apiService: Service) {
        self.apiService = apiService
    }
    
    func getAllFiltered(page: Int?, size: Int?, sort: String?, filterValue: String?) async throws -> Page<Chat> {
        return try await apiService.getAllFiltered(page: page, size: size, sort: sort, filterValue: filterValue).result
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
}
