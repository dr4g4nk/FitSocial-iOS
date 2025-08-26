//
//  UserPref.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//

import Foundation
import SwiftData

// Preferenca teme koju je korisnik izabrao u app-u
public enum ThemePreference: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

@Model
public final class UserDataEntity {
    @Attribute(.unique)
    public var id: Int

    public var firstName: String
    public var lastName: String
    public var avatarUrl: String?

    public var selectedTheme: ThemePreference

    public var lastSyncedAt: Date

    public init(
        id: Int,
        firstName: String,
        lastName: String,
        avatarUrl: String? = nil,
        selectedTheme: ThemePreference = .system,
        lastSyncedAt: Date = .now
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl
        self.selectedTheme = selectedTheme
        self.lastSyncedAt = lastSyncedAt
    }
}

extension UserDataEntity {
    public func mapToUserData() -> UserData {
        UserData(
            id: id,
            firstName: firstName,
            lastName: lastName,
            avatarUrl: avatarUrl
        )
    }
}

public final class UserData: Identifiable, Sendable{
    public let id: Int

    public let firstName: String
    public let lastName: String
    public let avatarUrl: String?
    public let selectedTheme: ThemePreference

    public init(
        id: Int,
        firstName: String,
        lastName: String,
        avatarUrl: String? = nil,
        selectedTheme: ThemePreference = .system,
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl
        self.selectedTheme = selectedTheme
    }

    public var fullName: String { "\(firstName) \(lastName)" }
}
