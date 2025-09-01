//
//  User.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Foundation

public struct User: Identifiable, Codable, Hashable, Copyable {
    public let id: Int
    public let firstName: String
    public let lastName: String
    public var avatarUrl: String?
    
    public init(id: Int, firstName: String, lastName: String, avatarUrl: String? = "") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl
    }
    
    public var displayName: String {
        "\(firstName) \(lastName)"
    }
    
    public func avatarUrl(privateAccess: Bool = true) -> String {
        if privateAccess {
            return "\(AppConfig.baseURL)api/user/\(id)/avatar"
        } else {
            return "\(AppConfig.baseURL)public/user/\(id)/avatar"
        }
    }
}

