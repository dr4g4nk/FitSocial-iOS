//
//  Untitled.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation

protocol Repository<Id, Entity, CreateDTO, UpdateDTO> {
    associatedtype Id
    associatedtype Entity: Decodable
    associatedtype CreateDTO: Encodable
    associatedtype UpdateDTO: Encodable
    associatedtype Service: APIService<Id, Entity, CreateDTO, UpdateDTO>

    var apiService: Service { get }


    func getById(_ id: Id) async throws -> Entity
    func getAll(page: Int?, size: Int?, sort: String?, query: [URLQueryItem]) async throws -> Page<Entity>
    func create(_ data: CreateDTO) async throws -> Entity
    func update(_ id: Id, with data: UpdateDTO) async throws -> Entity
    func delete(_ id: Id) async throws
    
    func _getById(_ id: Id) async throws -> Entity
    func _getAll(page: Int?, size: Int?, sort: String?, query: [URLQueryItem]) async throws -> Page<Entity>
    func _create(_ data: CreateDTO) async throws -> Entity
    func _update(_ id: Id, with data: UpdateDTO) async throws -> Entity
    func _delete(_ id: Id) async throws
}

extension Repository {
    func _getById(_ id: Id) async throws -> Entity {
        try await apiService.getById(id).result
    }
    func getById(_ id: Id) async throws -> Entity {
        try await _getById(id)
    }
    
    func _getAll(page: Int? = nil, size: Int? = nil, sort: String? = nil, query: [URLQueryItem] = []) async throws
        -> Page<Entity>
    {
        let resultPage = try await apiService.getAll(page: page, size: size, sort: sort, extraQuery: query)
        return resultPage.result
    }
    func getAll(page: Int? = nil, size: Int? = nil, sort: String? = nil, query: [URLQueryItem] = []) async throws
        -> Page<Entity>
    {
        try await _getAll(page: page, size: size, sort: sort, query: query)
    }

    func _create(_ data: CreateDTO) async throws -> Entity {
        try await apiService.create(data).result
    }
    func create(_ data: CreateDTO) async throws -> Entity {
        try await _create(data)
    }

    func _update(_ id: Id, with data: UpdateDTO) async throws
        -> Entity
    {
        try await apiService.update(id, with: data).result
    }
    func update(_ id: Id, with data: UpdateDTO) async throws
    -> Entity
{
    try await _update(id, with: data)
}
    
    func _delete(_ id: Id) async throws {
        try await apiService.delete(id)
    }
    func delete(_ id: Id) async throws {
        try await _delete(id)
    }
}
