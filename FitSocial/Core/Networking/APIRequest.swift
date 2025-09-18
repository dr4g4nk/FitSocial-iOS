//
//  HTTPMethod.swift
//  FitSocial
//
//  Created by Dragan Kos on 1. 9. 2025..
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct APIRequest {
    public let path: String
    public let method: HTTPMethod
    public let query: [URLQueryItem]
    public let headers: [String: String]
    public let body: (any Encodable)?
    public let requiresAuth: Bool

    public init(
        path: String,
        method: HTTPMethod = .get,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

public struct ApiMultipartRequest {
    public let path: String
    public let method: HTTPMethod
    public let query: [URLQueryItem]
    public let headers: [String: String]
    public let fields: [UploadField]
    public let files: [UploadFile]
    public let onProgress:
        (_ sent: Int64, _ total: Int64, _ fraction: Double) -> Void
    public let requiresAuth: Bool

    init(
        path: String,
        method: HTTPMethod = .post,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        fields: [UploadField],
        files: [UploadFile],
        onProgress: @escaping (_: Int64, _: Int64, _: Double) -> Void = {
            _,
            _,
            _ in
        },
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.fields = fields
        self.files = files
        self.onProgress = onProgress
        self.requiresAuth = requiresAuth
    }
}
