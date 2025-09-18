//
//  MessageEntity.swift
//  FitSocial
//
//  Created by Dragan Kos on 8. 9. 2025..
//

import Foundation
import SwiftData

@Model
final class MessageEntity: Identifiable, Hashable {
    @Attribute(.unique)
    private(set) var id: String
    var serverId: Int
    var chatId: Int
    var user: UserEntity?
    var content: String?
    var label: String?
    var createdAt: Date
    var updatedAt: Date
    var my: Bool
    var attachment: AttachmentEntity?
    var status: String // sending, sent, failed
    var error: String?
    var progress: Double?

    init(
        serverId: Int? = nil,
        chatId: Int,
        user: UserEntity? = nil,
        content: String? = "",
        label: String?,
        createdAt: Date,
        updatedAt: Date,
        my: Bool,
        attachment: AttachmentEntity?,
        status: String = "sent",
        error: String? = nil,
        progress: Double? = nil
    ) {
        self.id = serverId != nil ? String(serverId!) : UUID().uuidString
        self.serverId = serverId ?? -1
        self.chatId = chatId
        self.user = user
        self.content = content
        self.label = label
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.my = my
        self.attachment = attachment
        self.status = status
        self.error = error
        self.progress = progress
    }
}

extension MessageEntity {
    func toDomain() -> Message {
        Message(
            id: serverId,
            chatId: chatId,
            user: user?.toDomain(),
            content: content ?? "",
            label: label,
            createdAt: createdAt,
            updatedAt: updatedAt,
            my: my,
            attachment: attachment != nil ? attachment?.toDomain() : nil
        )
    }

    static func fromDomain(from: Message) -> MessageEntity {
        var user :UserEntity?
        
        if let usr = from.user {
           user = UserEntity.fromDomain(
            from: usr.copy({ u in
                    u.avatarUrl = u.avatarUrl(privateAccess: true)
                })
            )
        }
        
        return MessageEntity(
            serverId: from.id,
            chatId: from.chatId,
            user: user,
            content: from.content,
            label: from.label,
            createdAt: from.createdAt,
            updatedAt: from.updatedAt,
            my: from.my,
            attachment: from.attachment != nil
                ? AttachmentEntity.fromDomain(from: from.attachment!) : nil,
            status: "sent"
        )
    }
}


@Model
final class AttachmentEntity {
    @Attribute(.unique)
    var id: String
    var serverId: Int  // za remote image/video
    var kind: String  // "document" | "remoteImage" | "remoteVideo" | "image" | "video"
    var urlString: String?  // glavna lokacija (document/image/video)
    var thumbnailURLString: String?  // za video thumbnail
    var filename: String
    var contentType: String

    init(
        id: Int? = nil,
        kind: String,
        urlString: String? = nil,
        thumbnailURLString: String? = nil,
        filename: String,
        contentType: String
    ) {
        self.id = id != nil ? String(id!) : UUID().uuidString
        self.serverId = id ?? -1
        self.kind = kind
        self.urlString = urlString
        self.thumbnailURLString = thumbnailURLString
        self.filename = filename
        self.contentType = contentType
    }
}

extension AttachmentEntity {
    func toDomain() -> Attachment {
        Attachment(id: serverId, fileName: filename, contentType: contentType)
    }

    static func fromDomain(from: Attachment) -> AttachmentEntity {
        var kind: String
        if from.contentType.starts(with: "image") {
            kind = "remoteImage"
        } else if from.contentType.starts(with: "video") {
            kind = "remoteVideo"
        } else {
            kind = "document"
        }

        return AttachmentEntity(
            id: from.id,
            kind: kind,
            urlString: from.getUrlString(),
            thumbnailURLString: from.isVideo ? from.getImageUrlString() : nil,
            filename: from.fileName,
            contentType: from.contentType
        )
    }
}
