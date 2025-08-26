//
//  AuthRepositoryImpl.swift
//  FitSocial
//
//  Created by Dragan Kos on 13. 8. 2025..
//

import Foundation

public final class AuthRepositoryImpl: AuthRepository {
    private let api: APIClient
    private let session: UserSession

    private let loginPath: String
    private let registerPath: String

    public init(
        api: APIClient,
        session: UserSession,
        loginPath: String = "auth/login",
        registerPath: String = "auth/register"
    ) {
        self.api = api
        self.session = session
        self.loginPath = loginPath
        self.registerPath = registerPath
    }

    public func loginReturningTokens(email: String, password: String)
        async throws -> AuthResult
    {
        struct Credentials: Encodable {
            let email: String
            let password: String
        }
        // requiresAuth: false -> bez Bearer-a, bez refresh pokušaja
        return try await api.post(
            loginPath,
            body: Credentials(email: email, password: password),
            requiresAuth: false
        )
    }

    public func login(email: String, password: String) async throws {
        let res = try await loginReturningTokens(
            email: email,
            password: password
        )
        try await session.saveTokens(
            access: res.token,
            refresh: res.refreshToken,
            user: res.user
        )
    }

    public func register(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async throws -> ApiResponse<User?> {
        struct Body: Encodable {
            let firstName: String
            let lastName: String
            let email: String
            let password: String
        }
        
        return try await api.post(
            registerPath,
            body: Body(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            ),
            requiresAuth: false
        )
    }

    public func logout() async {
        try? await session.logout()
    }
}
