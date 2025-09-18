//
//  Untitled.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 9. 2025..
//

import SwiftData

actor ExerciseLocalStore: SwiftDataCRUDManager{
    typealias T = Exercise
    
   let modelContext: ModelContext
    
    init(container: ModelContainer){
        self.modelContext = ModelContext(container)
    }
}
