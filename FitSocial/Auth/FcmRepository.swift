//
//  AuthApiClient.swift
//  FitSocial
//
//  Created by Dragan Kos on 1. 9. 2025..
//

import Foundation


public protocol FcmRepository{
    func attachFcmToken(token: String) async throws
    func detachFcmToken(token: String) async throws
}

public class FcmRepositoryImpl : FcmRepository {
    private let apiClient: APIClient
    public init(
        apiClient: APIClient
    ) {
        self.apiClient = apiClient
    }
    
    private struct FCMTokenBody: Codable, Hashable {
        let token: String
    }
    private struct FCMTokenResponse: Codable {}
    
    public func attachFcmToken(token: String) async throws {
        let _: FCMTokenResponse = try await apiClient.post("api/user/fcm", body: FCMTokenBody(token: token))
    }
    
    public func detachFcmToken(token: String) async throws {
        let _: FCMTokenResponse = try await apiClient.post("api/user/fcm/remove", body: FCMTokenBody(token: token))
    }
}
