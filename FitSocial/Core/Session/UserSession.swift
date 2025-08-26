//
//  UserSession.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Foundation

public actor UserSession {
    private let store: TokenStore
    private let currentUserStore: CurrentUserStore
    
    public private(set) var user: User?

    public init(tokenStore: TokenStore, currentUserStore: CurrentUserStore) {
        self.store = tokenStore
        self.currentUserStore = currentUserStore
        
        if let userData = try? currentUserStore.currentUser(){
            self.user = User(id: userData.id, firstName: userData.firstName, lastName: userData.lastName, avatarUrl: userData.avatarUrl)
        }
    }

    public func saveTokens(access: String, refresh: String?, user: User? = nil) throws {
        try store.save(access: access, refresh: refresh)
        if let user = user {
            let userData = try currentUserStore.upsertUser(id: user.id, firstName: user.firstName, lastName: user.lastName, avatarUrl: user.avatarUrl(privateAccess: true))
            try currentUserStore.setCurrentUser(id: userData.id)
            self.user = User(id: userData.id, firstName: userData.firstName, lastName: userData.lastName, avatarUrl: userData.avatarUrl)
        }
        
    }

    public func readAccessToken() throws -> String? {
        try store.readAccess()
    }

    public func readRefreshToken() throws -> String? {
        try store.readRefresh()
    }

    public func logout() throws {
        try store.clear()
        try currentUserStore.logoutAndClearLocal()
        self.user = nil
    }

    /// Pomoćna – da znaš da li je user prijavljen (na bazi access tokena)
    public func isLoggedIn() throws -> Bool {
        try store.readAccess() != nil
    }
}
