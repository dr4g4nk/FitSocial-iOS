//
//  UserEntity.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftData

@Model
final class UserEntity : Identifiable {
    @Attribute(.unique) var id: Int
    var firstName: String
    var lastName: String
    var avatarUrl: String?

    init(id: Int, firstName: String, lastName: String, avatarUrl: String?) {
        self.id = id; self.firstName = firstName; self.lastName = lastName; self.avatarUrl = avatarUrl
    }
}
