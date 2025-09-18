//
//  ChatEntity.swift
//  FitSocial
//
//  Created by Dragan Kos on 8. 9. 2025..
//

import Foundation
import SwiftData

@Model
final class ChatEntity: Identifiable, Hashable {
    @Attribute(.unique)
    var id: Int
    var subject: String?
    var text: String?
    var lastMessageTime: Date?

    @Relationship(deleteRule: .cascade, inverse: \ChatUserEntity.chat)
    private var chatUsers: [ChatUserEntity] = []

    public var users: [UserEntity] {
        get {
            chatUsers.map { cue in
                cue.user
            }
        }
        set {
            chatUsers = newValue.map({ usr in
                ChatUserEntity(chat: self, user: usr)
            })
        }
    }

    init(
        id: Int,
        subject: String?,
        text: String?,
        lastMessageTime: Date?
    ) {
        self.id = id
        self.subject = subject
        self.text = text
        self.lastMessageTime = lastMessageTime
    }
}

extension ChatEntity {
    func toDomain() -> Chat {
        Chat(
            id: id,
            subject: subject,
            text: text,
            lastMessageTime: lastMessageTime,
            users: users.map({ usr in
                usr.toDomain()
            })
        )
    }
    
    static func fromDomain(from: Chat) -> ChatEntity {
       let chat = ChatEntity(id: from.id, subject: from.subject, text: from.text, lastMessageTime: from.lastMessageTime)
        chat.users = from.users.map({ usr in
            let user = usr.copy { u in
                u.avatarUrl = u.avatarUrl(privateAccess: true)
            }
            return UserEntity.fromDomain(from: user)
        })
        return chat
    }
}

@Model
final class ChatUserEntity: Identifiable, Hashable {
    @Attribute(.unique)
    private(set) var id: String
    var chat: ChatEntity?
    var user: UserEntity

    init(chat: ChatEntity? = nil, user: UserEntity) {
        self.id = "chat(\(chat?.id ?? -1))_user(\(user.id))"
        self.chat = chat
        self.user = user
    }
}
