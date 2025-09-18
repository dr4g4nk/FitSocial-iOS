//
//  SwiftDataCRUDManager.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import Foundation
import SwiftData

protocol SwiftDataCRUDManager: Actor {
    associatedtype T: PersistentModel

    var modelContext: ModelContext { get }

    func _create(_ item: T) throws
    func _createBatch(_ items: [T]) throws
    func _fetch<R>(
        predicate: Predicate<T>?,
        sortBy: [SortDescriptor<T>],
        limit: Int?,
        transform: (T) -> R
    ) throws -> [R] where R: Sendable
    func _fetchFirst<R>(
        predicate: Predicate<T>?,
        sortBy: [SortDescriptor<T>],
        transform: (T) -> R
    ) throws -> R? where R: Sendable
    func _fetchById<R>(_ id: PersistentIdentifier, transform: (T) -> R) -> R?
    where R: Sendable
    func _count(predicate: Predicate<T>?) throws -> Int
    func _update(_ item: T, changes: (T) -> Void) throws
    func _updateBatch(_ items: [T], changes: (T) -> Void) throws
    func _updateBatch(predicate: Predicate<T>, changes: (T) -> Void) throws
    func _delete(_ item: T) throws
    func _deleteBatch(_ items: [T]) throws
    func _deleteAll(predicate: Predicate<T>?) throws
    func _exists(predicate: Predicate<T>) throws -> Bool
    func _fetchPaginated<R>(
        offset: Int,
        limit: Int,
        predicate: Predicate<T>?,
        sortBy: [SortDescriptor<T>],
        transform: (T) -> R
    ) throws -> [R] where R: Sendable
}

extension SwiftDataCRUDManager {

    func _create(_ item: T) throws {
        modelContext.insert(item)
        try save()
    }
    func create(_ item: T) throws {
        try _create(item)
    }

    func _createBatch(_ items: [T]) throws {
        for item in items {
            modelContext.insert(item)
        }
        try save()
    }
    func createBatch(_ items: [T]) throws {
        try _createBatch(items)
    }

    func _fetch<R>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        limit: Int? = nil,
        transform: (T) -> R
    ) throws -> [R] {
        var fetchDescriptor = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: sortBy
        )

        if let limit = limit {
            fetchDescriptor.fetchLimit = limit
        }

        return try modelContext.fetch(fetchDescriptor).map(transform)
    }
    func fetch<R>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        limit: Int? = nil,
        transform: (T) -> R
    ) throws -> [R] {
        try _fetch(
            predicate: predicate,
            sortBy: sortBy,
            limit: limit,
            transform: transform
        )
    }

    func _fetchFirst<R>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        transform: (T) -> R
    ) throws -> R? {
        let results = try fetch(
            predicate: predicate,
            sortBy: sortBy,
            limit: 1,
            transform: transform
        )
        return results.first
    }
    func fetchFirst<R>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        transform: (T) -> R
    ) throws -> R? {
        try _fetchFirst(
            predicate: predicate,
            sortBy: sortBy,
            transform: transform
        )
    }

    func _fetchById<R>(
        _ id: PersistentIdentifier,
        transform: (T) -> R
    ) -> R? {
        let result = modelContext.model(for: id) as? T
        guard let result = result else { return nil }
        return [result].map(transform).first
    }
    func fetchById<R>(
        _ id: PersistentIdentifier,
        transform: (T) -> R
    ) -> R? {
        _fetchById(id, transform: transform)
    }

    func _count(predicate: Predicate<T>? = nil) throws -> Int {
        let fetchDescriptor = FetchDescriptor<T>(predicate: predicate)
        return try modelContext.fetchCount(fetchDescriptor)
    }
    func count(predicate: Predicate<T>? = nil) throws -> Int {
        try _count(predicate: predicate)
    }

    func _update(_ item: T, changes: (T) -> Void) throws {
        changes(item)
        try save()
    }
    func update(_ item: T, changes: (T) -> Void) throws {
        try _update(item, changes: changes)
    }

    func _updateBatch(_ items: [T], changes: (T) -> Void) throws {
        for item in items {
            changes(item)
        }
        try save()
    }
    func updateBatch(_ items: [T], changes: (T) -> Void) throws {
        try _updateBatch(items, changes: changes)
    }
    
    func _updateBatch(predicate: Predicate<T>, changes: (T) -> Void) throws {
        let fetchDescriptor = FetchDescriptor<T>(
            predicate: predicate
        )
        let items = try modelContext.fetch(fetchDescriptor)
        try _updateBatch(items, changes: changes)
    }
    func updateBatch(predicate: Predicate<T>, changes: (T) -> Void) throws{
        try _updateBatch(predicate: predicate, changes: changes)
    }

    func _delete(_ item: T) throws {
        modelContext.delete(item)
        try save()
    }
    func delete(_ item: T) throws {
        try _delete(item)
    }

    func _deleteBatch(_ items: [T]) throws {
        for item in items {
            modelContext.delete(item)
        }
        try save()
    }
    func deleteBatch(_ items: [T]) throws {
        try _deleteBatch(items)
    }

    func _deleteAll(predicate: Predicate<T>? = nil) throws {
        let fetchDescriptor = FetchDescriptor<T>(
            predicate: predicate,
        )
        let items = try modelContext.fetch(fetchDescriptor)
        try deleteBatch(items)
    }
    func deleteAll(predicate: Predicate<T>? = nil) throws {
        try _deleteAll(predicate: predicate)
    }

    func save() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    func refresh() throws {
        modelContext.rollback()
    }

    func performTransaction<Result>(_ operation: () throws -> Result) throws
        -> Result
    {
        let result = try operation()
        try save()
        return result
    }

    func _exists(predicate: Predicate<T>) throws -> Bool {
        return try count(predicate: predicate) > 0
    }
    func exists(predicate: Predicate<T>) throws -> Bool {
        try _exists(predicate: predicate)
    }

    func _fetchPaginated<R>(
        offset: Int,
        limit: Int,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        transform: (T) -> R
    ) throws -> [R] {
        var fetchDescriptor = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: sortBy
        )
        fetchDescriptor.fetchLimit = limit
        fetchDescriptor.fetchOffset = offset

        return try modelContext.fetch(fetchDescriptor).map(transform)
    }
    func fetchPaginated<R>(
        offset: Int,
        limit: Int,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        transform: (T) -> R
    ) throws -> [R] {
        try _fetchPaginated(
            offset: offset,
            limit: limit,
            predicate: predicate,
            sortBy: sortBy,
            transform: transform
        )
    }
}
