//
//  MessageRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public protocol MessageRepository: Repository<
    Int, Message, MessageDto, MessageDto
>
where Service: MessageApiService {

    func get(chatId: Int, page: Int, size: Int, sort: String?) async throws
        -> Page<Message>
    func create(
        message: MessageDto,
        attachment: AttachmentDto?,
        onProgress: @escaping (Int64, Int64, Double) -> Void
    ) async throws
        -> Message?
}

class MessageRepositoryImpl<Service: MessageApiService>: MessageRepository {
    var apiService: Service

    init(apiService: Service) {
        self.apiService = apiService
    }

    func get(chatId: Int, page: Int, size: Int, sort: String? = nil)
        async throws -> Page<Message>
    {
        return try await apiService.get(
            chatId: chatId,
            page: page,
            size: size,
            sort: sort
        ).result
    }

    func create(
        message: MessageDto,
        attachment: AttachmentDto? = nil,
        onProgress:  @escaping (Int64, Int64, Double) -> Void = { sent, total, fraction in }
    ) async throws
        -> Message?
    {
        var file: UploadFile? = nil
        
        if attachment != nil {
            switch attachment?.kind {
            case .image(_, let url), .video(let url, _), .document(let url):
                file = .init(name: "attachment", fileURL: url, filename: attachment!.filename, mimeType:  attachment!.contentType ?? "")
            default: file = nil
            }
        }
        
        let response: ApiResponse<Message?> = try await apiService.api.post(
            "\(apiService.basePath)/create",
            fields: [.init(name: "message", value: message)],
            files: file != nil ? [file!] : []
        ) { sent, total, fraction in
            onProgress(sent, total, fraction)
        }

        return response.result
    }

}
