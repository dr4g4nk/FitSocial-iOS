//
//  WorkoutReminderLocalStore.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 9. 2025..
//

import SwiftData

actor WorkoutReminderLocalStore: SwiftDataCRUDManager{
    typealias T = WorkoutReminderEntity
    
    let modelContext: ModelContext
    
    init(container: ModelContainer){
        self.modelContext = ModelContext(container)
    }
}
