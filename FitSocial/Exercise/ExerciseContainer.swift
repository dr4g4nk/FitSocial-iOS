//
//  ExedrciseContainer.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import Foundation
import SwiftData

@MainActor 
class ExerciseContainer {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func makeExerciseListViewModel() -> ExerciseListViewModel {
        ExerciseListViewModel(modelContainer: modelContainer)
    }
    
    func makeWorkoutReminderViewModel() -> WorkoutReminderViewModel{
        WorkoutReminderViewModel(modelContainder: modelContainer)
    }
}
