//
//  AuthManager.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthManager {
    private(set) var isLoggedIn: Bool = false
    private let session: UserSession
    
    private(set) var user : User?

    init(session: UserSession) {
        self.session = session
        Task {
            await refresh()
        }
    }

    func refresh() async {
        isLoggedIn = (try? await session.isLoggedIn()) ?? false
        user = await session.user
    }

    func didLogin(access: String, refresh: String?, user: User?) async throws {
        try await session.saveTokens(access: access, refresh: refresh, user: user)
        await self.refresh()
    }

    func logout() async {
        try? await session.logout()
        await refresh()
    }
}
