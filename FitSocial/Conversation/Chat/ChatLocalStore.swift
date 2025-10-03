//
//  ChatLocalStore.swift
//  FitSocial
//
//  Created by Dragan Kos on 16. 9. 2025..
//

import SwiftData

@ModelActor
actor ChatLocalStore: SwiftDataCRUDManager {
    typealias T = ChatEntity
    
   
     func _createBatch(_ items: [ChatEntity]) throws {
            for item in items {
                item.users = try item.users.map({ u in
                    try upsertUser(u)
                })
                modelContext.insert(item)
            }
            try save()
    }
}
