//
//  AttachmentLocalStore.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 9. 2025..
//

import SwiftData

actor AttachmentLocalStore: SwiftDataCRUDManager{
    typealias T = AttachmentEntity
    
    let modelContext: ModelContext

    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
    }

}
