//
//  ApiService.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

public protocol APIService<Id, Model, CreateBody, UpdateBody> {
    associatedtype Id: Any
    associatedtype Model: Decodable
    associatedtype CreateBody: Encodable
    associatedtype UpdateBody: Encodable
    
    var basePath: String { get }
    var api: APIClient { get }
    
    func getById(_ id: Id, requiresAuth: Bool) async throws -> ApiResponse<Model>
    func getAll(page: Int?, size: Int?, sort: String?, extraQuery: [URLQueryItem], requiresAuth: Bool) async throws -> ApiResponse<Page<Model>>
    func create(_ body: CreateBody, requiresAuth: Bool) async throws -> ApiResponse<Model>
    func update(_ id: Id, with body: UpdateBody, requiresAuth: Bool) async throws -> ApiResponse<Model>
    func delete(_ id: Id, requiresAuth: Bool) async throws
    
    func _getById(_ id: Id, requiresAuth: Bool) async throws -> ApiResponse<Model>
    func _getAll(page: Int?, size: Int?, sort: String?, extraQuery: [URLQueryItem], requiresAuth: Bool) async throws -> ApiResponse<Page<Model>>
    func _create(_ body: CreateBody, requiresAuth: Bool) async throws -> ApiResponse<Model>
    func _update(_ id: Id, with body: UpdateBody, requiresAuth: Bool) async throws -> ApiResponse<Model>
    func _delete(_ id: Id, requiresAuth: Bool) async throws
}


public extension APIService {
    @discardableResult
    func _getById(_ id: Id, requiresAuth: Bool = true) async throws -> ApiResponse<Model> {
        try await api.get("\(basePath)/\(id)", requiresAuth: requiresAuth)
    }
    @discardableResult
    func getById(_ id: Id, requiresAuth: Bool = true) async throws -> ApiResponse<Model> {
       try await _getById(id, requiresAuth: requiresAuth)
    }
    
    @discardableResult
    func _getAll(
        page: Int? = nil,
        size: Int? = nil,
        sort: String? = nil,
        extraQuery: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> ApiResponse<Page<Model>> {
        var query = extraQuery
        if let page { query.append(URLQueryItem(name: "page", value: String(page))) }
        if let size { query.append(URLQueryItem(name: "size", value: String(size))) }
        if let sort { query.append(URLQueryItem(name: "sort", value: String(sort)))}
        return try await api.get("\(basePath)", query: query, requiresAuth: requiresAuth)
    }
    
    @discardableResult
    func getAll(
        page: Int? = nil,
        size: Int? = nil,
        sort: String? = nil,
        extraQuery: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> ApiResponse<Page<Model>> {
        return try await _getAll(page: page, size: size, sort: sort, extraQuery: extraQuery, requiresAuth: requiresAuth)
    }
    
    @discardableResult
    func _create(_ body: CreateBody, requiresAuth: Bool = true) async throws -> ApiResponse<Model> {
        try await api.post("\(basePath)", body: body, requiresAuth: requiresAuth)
    }
    @discardableResult
    func create(_ body: CreateBody, requiresAuth: Bool = true) async throws -> ApiResponse<Model> {
        try await _create(body, requiresAuth: requiresAuth)
    }
    
    @discardableResult
    func _update(_ id: Id, with body: UpdateBody, requiresAuth: Bool = true) async throws -> ApiResponse<Model> {
        try await api.put("\(basePath)/\(id)", body: body)
    }
    
    @discardableResult
    func update(_ id: Id, with body: UpdateBody, requiresAuth: Bool = true) async throws -> ApiResponse<Model> {
        try await _update(id, with: body, requiresAuth: requiresAuth)
    }
    
    func _delete(_ id: Id, requiresAuth: Bool = true) async throws {
        _ = try await api.delete( "\(basePath)/\(id)" ) as EmptyResponse
    }

    func delete(_ id: Id, requiresAuth: Bool = true) async throws {
        _ = try await _delete(id, requiresAuth: requiresAuth)
    }
}
