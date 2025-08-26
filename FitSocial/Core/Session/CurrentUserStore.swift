//
//  CurrentUserStore.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//

import Foundation
import SwiftData


public protocol CurrentUserStore {
    func currentUser() throws -> UserData?

    func setCurrentUser(id: Int) throws

    func upsertUser(
        id: Int,
        firstName: String,
        lastName: String,
        avatarUrl: String?
    ) throws -> UserData

    func setTheme(_ theme: ThemePreference) throws

    func logoutAndClearLocal() throws
}


public final class CurrentUserStoreImpl: CurrentUserStore {
    private let context: ModelContext
    private let defaults: UserDefaults
    private let currentUserKey = "current_user_id"

    public init(container: ModelContainer,
                defaults: UserDefaults = .standard)
    {
        self.context = ModelContext(container)
        self.defaults = defaults
        context.autosaveEnabled = true
    }


    private func fetchUser(by id: Int) throws -> UserDataEntity? {
        let fd = FetchDescriptor<UserDataEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(fd).first
    }

    private func fetchAllUsers() throws -> [UserDataEntity] {
        try context.fetch(FetchDescriptor<UserDataEntity>())
    }

    private func _currentUser() throws -> UserDataEntity? {
        guard let id = defaults.object(forKey: currentUserKey) as? Int else { return nil }
        return try fetchUser(by: id)
    }

    public func currentUser() throws -> UserData? {
        return try _currentUser()?.mapToUserData()
    }

    public func setCurrentUser(id: Int) throws {
        defaults.set(id, forKey: currentUserKey)
    }


    @discardableResult
    public func upsertUser(
        id: Int,
        firstName: String,
        lastName: String,
        avatarUrl: String?
    ) throws -> UserData {
        if let existing = try fetchUser(by: id) {
            existing.firstName = firstName
            existing.lastName  = lastName
            existing.avatarUrl = avatarUrl
            existing.lastSyncedAt = .now
            try context.save()
            return existing.mapToUserData()
        } else {
            let u = UserDataEntity(
                id: id,
                firstName: firstName,
                lastName: lastName,
                avatarUrl: avatarUrl,
                selectedTheme: .system,
                lastSyncedAt: .now
            )
            context.insert(u)
            try context.save()
            return u.mapToUserData()
        }
    }


    public func setTheme(_ theme: ThemePreference) throws {
        guard let u = try _currentUser() else { return }
        u.selectedTheme = theme
        try context.save()
    }


    public func logoutAndClearLocal() throws {
        defaults.removeObject(forKey: currentUserKey)
        for u in try fetchAllUsers() {
            context.delete(u)
        }
        try context.save()
    }
}
