//
//  MessageRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation
import SwiftData

protocol MessageRepository: Repository<
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

    func updateMessageProgress(id: PersistentIdentifier, progress: Double)
        async
        throws
    func updateMessageError(id: PersistentIdentifier, error: String)
        async throws

    func createLocal(message: Message) async throws
    func createLocal(message: MessageEntity) async throws
    func deleteLocal(_ message: MessageEntity) async throws
}

class MessageRepositoryImpl<Service: MessageApiService>: MessageRepository {
    var apiService: Service
    private let messagelocalStore: MessageLocalStore
    private let attachemntLocalStore: AttachmentLocalStore

    init(apiService: Service, modelContainer: ModelContainer) {
        self.apiService = apiService
        self.messagelocalStore = MessageLocalStore(modelContainer: modelContainer)
        self.attachemntLocalStore = AttachmentLocalStore(
            modelContainer: modelContainer
        )
    }

    func get(chatId: Int, page: Int, size: Int, sort: String? = nil)
        async throws -> Page<Message>
    {
        let res = try await apiService.get(
            chatId: chatId,
            page: page,
            size: size,
            sort: sort
        ).result

        Task {
            let messages = res.content.map({ m in
                MessageEntity.fromDomain(from: m)
            })

            try await messagelocalStore.createBatch(messages)
        }

        return res
    }

    func create(
        message: MessageDto,
        attachment: AttachmentDto? = nil,
        onProgress: @escaping (Int64, Int64, Double) -> Void = {
            sent,
            total,
            fraction in
        }
    ) async throws
        -> Message?
    {
        var file: UploadFile? = nil

        if attachment != nil {
            switch attachment?.kind {
            case .image(_, let url), .video(let url, _), .document(let url):
                file = .init(
                    name: "attachment",
                    fileURL: url,
                    filename: attachment!.filename,
                    mimeType: attachment!.contentType ?? ""
                )
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

    func updateMessageProgress(id: PersistentIdentifier, progress: Double)
        async
        throws
    {
        try await messagelocalStore.updateBatch(
            predicate: #Predicate { mess in
                mess.id == id
            },
            changes: { m in
                m.progress = progress
            }
        )
    }

    func updateMessageError(id: PersistentIdentifier, error: String)
        async throws
    {
        try await messagelocalStore.updateBatch(
            predicate: #Predicate { mess in
                mess.id == id
            },
            changes: { m in
                m.status = "failed"
                m.error = error
            }
        )
    }

    func createLocal(message: Message) async throws {
        let newMessage = MessageEntity.fromDomain(from: message)
        try await messagelocalStore.create(newMessage)
    }

    func createLocal(message: MessageEntity) async throws {
        try await messagelocalStore.create(message)
    }

    func deleteLocal(_ message: MessageEntity) async throws {
        let id = message.id
        try await messagelocalStore.deleteAll(
            predicate: #Predicate<MessageEntity> { m in
                m.id == id
            }
        )

        if let attachmentId = message.attachment?.id {
            try await attachemntLocalStore.deleteAll(
                predicate: #Predicate<AttachmentEntity> { att in
                    att.id == attachmentId
                }
            )
        }
    }

}
