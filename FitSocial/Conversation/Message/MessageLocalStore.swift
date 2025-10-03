//
//  MessageLocalStore.swift
//  FitSocial
//
//  Created by Dragan Kos on 9. 9. 2025..
//

import Foundation
import SwiftData

@ModelActor
actor MessageLocalStore: SwiftDataCRUDManager {
    typealias T = MessageEntity


    func _create(_ item: MessageEntity) throws {
        if let usr = item.user {
            let user = try upsertUser(usr)
            item.user = user
        }

        if let attachment = item.attachment {
            let att = try upsertAttachement(attachment)
            item.attachment = att
        }
        modelContext.insert(item)
        try save()
    }

    private func getUsersMap(userIds: Set<Int>) throws -> [Int: UserEntity] {
        let fd = FetchDescriptor<UserEntity>(
            predicate: #Predicate { userIds.contains($0.id) }
        )
        let existing = try modelContext.fetch(fd)
        return Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
    }

    private func getAttachmentsMap(attachmentIds: Set<String>) throws -> [String: AttachmentEntity]
    {
        let fd = FetchDescriptor<AttachmentEntity>(
            predicate: #Predicate { attachmentIds.contains($0.id) }
        )
        let existing = try modelContext.fetch(fd)
        return Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
    }

    func _createBatch(_ items: [MessageEntity]) throws {
        let userIds = Set(items.compactMap { $0.user?.id })
        let attachmentIds = Set(items.compactMap { $0.attachment?.id })

        var userMap = try getUsersMap(userIds: userIds)
        var attMap = try getAttachmentsMap(attachmentIds: attachmentIds)

        for item in items {

            if let user = item.user {
                userMap[user.id] = try upsertUser(user)
            }

            if let att = item.attachment {
                attMap[att.id] = try upsertAttachement(att)
            }

            let m = MessageEntity(
                serverId: item.serverId,
                chatId: item.chatId,
                user: userMap[item.user?.id ?? -1],
                content: item.content,
                label: item.label,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt,
                my: item.my,
                attachment: attMap[item.attachment?.id ?? ""],
                status: item.status,
                error: item.error,
                progress: item.progress
            )
            modelContext.insert(m)
        }

        try modelContext.save()
    }
}

extension SwiftDataCRUDManager {
    func upsertUser(_ user: UserEntity) throws -> UserEntity {
        let id = user.id
        var fd = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == id }
        )
        fd.fetchLimit = 1

        if let existing = try modelContext.fetch(fd).first {
            existing.firstName = user.firstName
            existing.lastName = user.lastName
            existing.avatarUrl = user.avatarUrl
            return existing
        } else {
            modelContext.insert(user)
            return user
        }
    }

    func upsertAttachement(_ att: AttachmentEntity) throws -> AttachmentEntity {
        let id = att.id
        var fd = FetchDescriptor<AttachmentEntity>(
            predicate: #Predicate { $0.id == id }
        )
        fd.fetchLimit = 1

        if let existing = try modelContext.fetch(fd).first {
            existing.contentType = att.contentType
            existing.filename = att.filename
            existing.kind = att.kind
            existing.urlString = att.urlString
            existing.thumbnailURLString = att.thumbnailURLString
            return existing
        } else {
            modelContext.insert(att)
            return att
        }
    }
}
