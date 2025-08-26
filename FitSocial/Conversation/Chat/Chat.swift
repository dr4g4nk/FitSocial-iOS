//
//  Chat.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import Foundation

public struct Chat : Identifiable, Codable, Copyable{
    public let id: Int
    public let subject: String
    public let text: String?
    public let lastMessageTime: Date
    public let users: [User]
    
    init(id: Int, subject: String = "", text: String? = "", lastMessageTime: Date = .now, users: [User] = []) {
        self.id = id
        self.subject = subject
        self.text = text
        self.lastMessageTime = lastMessageTime
        self.users = users
    }
}

public struct ChatDto : Identifiable, Codable, Copyable{
    public let id: Int
    public let subject: String
    public let userIds: [Int]
}
