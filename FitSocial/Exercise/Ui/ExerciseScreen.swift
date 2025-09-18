//
//  ExerciseScreen.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import SwiftUI
import CoreLocation
import SwiftData

struct ExerciseScreen: View {

    
    @State private var exerciseListViewModel: ExerciseListViewModel
    @State private var workoutReminderViewModel: WorkoutReminderViewModel
    
    @State private var showSavedExercises = false
    @State private var showReminders = false
    
    private let container: ModelContainer

    init(container: FitSocialContainer) {
        self.container = container.modelContainer
        self.exerciseListViewModel =
        ExerciseListViewModel(modelContainer: container.modelContainer)
        self.workoutReminderViewModel = WorkoutReminderViewModel(modelContainder: container.modelContainer)
    }
    var body: some View {
        NavigationStack {
            ActivitySelectionView(container: container)
                .navigationTitle("Aktivnosti")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSavedExercises = true
                        } label: {
                            Label(
                                "Prethodne aktivnosti",
                                systemImage: "clock.arrow.circlepath"
                            )
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showReminders = true
                        } label: {
                            Label(
                                "Podsjetnik",
                                systemImage: "calendar.badge.plus"
                            )
                        }
                        .accessibilityLabel("Zakazivanje podsjetnika")
                    }
                }
                .navigationDestination(isPresented: $showSavedExercises) {
                        ExerciseListView(vm: exerciseListViewModel)
                        .navigationTitle("Prethodne aktivnosti")
                        .navigationBarTitleDisplayMode(.large)
                        
                }
                .navigationDestination(isPresented: $showReminders) {
                    WorkoutReminderView(vm: workoutReminderViewModel)
                }
        }
    }
}
