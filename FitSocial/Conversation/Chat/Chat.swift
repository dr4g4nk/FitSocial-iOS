//
//  Chat.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public struct Chat : Identifiable, Hashable, Codable, Copyable{
    public let id: Int
    public let subject: String?
    public let text: String?
    public let lastMessageTime: Date?
    public var users: [User]
    
    init(id: Int, subject: String? = nil, text: String? = nil, lastMessageTime: Date? = nil, users: [User] = []) {
        self.id = id
        self.subject = subject
        self.text = text
        self.lastMessageTime = lastMessageTime
        self.users = users
    }
    
    public var display: String {
        subject ?? users.map({ user in
            user.displayName
        }).joined(separator: ",")
    }
    
    public static func == (lhs: Chat, rhs: Chat) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
}

public struct ChatDto : Identifiable, Codable, Copyable{
    public let id: Int
    public let subject: String?
    public let content: String?
    public let userIds: [Int]
    
    init(id: Int, subject: String? = nil, content: String?, userIds: [Int]) {
        self.id = id
        self.content = content
        self.subject = subject
        self.userIds = userIds
    }
}
