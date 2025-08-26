//
//  AuthRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 13. 8. 2025..
//

import Foundation

public struct AuthResult: Decodable {
    public let token: String
    public let refreshToken: String?
    public let user: User?
}

public protocol AuthRepository {
    func loginReturningTokens(email: String, password: String) async throws -> AuthResult

    func login(email: String, password: String) async throws

    func register(firstName: String, lastName: String, email: String, password: String) async throws -> ApiResponse<User?>

    func logout() async
}
