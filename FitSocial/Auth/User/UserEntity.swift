//
//  UserEntity.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftData

@Model
final class UserEntity: Identifiable {
    @Attribute(.unique) var id: Int
    var firstName: String
    var lastName: String
    var avatarUrl: String?

    init(id: Int, firstName: String, lastName: String, avatarUrl: String? = "")
    {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl
    }
}

extension UserEntity {
    func toDomain() -> User {
        User(id: id, firstName: firstName, lastName: lastName, avatarUrl: avatarUrl)
    }

    static func fromDomain(from user: User) -> UserEntity {
        UserEntity(
            id: user.id,
            firstName: user.firstName,
            lastName: user.lastName,
            avatarUrl: user.avatarUrl ?? ""
        )
    }
}
