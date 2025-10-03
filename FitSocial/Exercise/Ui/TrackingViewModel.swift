//
//  TrackingViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import Foundation
import Observation
import SwiftData
import CoreLocation

@MainActor
@Observable
class TrackingViewModel{
    private let exerciseLocalStore: ExerciseLocalStore
    
    private(set) var stepCounterManager: StepCounterManager
    
    init(modelContainer: ModelContainer, selectedActivity: ActivityType){
        exerciseLocalStore = ExerciseLocalStore(modelContainer: modelContainer)
        self.selectedActivity = selectedActivity
        stepCounterManager = StepCounterManager()
        
    }
    
    let selectedActivity: ActivityType
    var showingTrackingView = false
    var showingPermissionView = false
    
    var hasActiveSession = false
    
    private(set) var steps: Int? = nil
    
    func onStart() {
        hasActiveSession = true
    }
    
    func startTrackingSteps(from: Date){
        stepCounterManager.startLiveStepTracking(from: from) { [self] count in
            steps = count
        }
    }
    
    var errorMessage: String?
    func onStop(locationManager: LocationManager){
        hasActiveSession = false
        locationManager.stopTracking()
        stepCounterManager.stopLiveStepTracking()
        Task {
            let data  = locationManager.getExerciseData()
            if let data = data {
                data.type = selectedActivity.rawValue
                
                if selectedActivity == .walking {
                    let steps = await stepCounterManager.getStepCount(from: data.startTime, to: data.endTime ?? Date.now)
                    data.steps = steps
                    self.steps = steps
                }
                do{
                    try await exerciseLocalStore.create(data)
                } catch{
                    errorMessage = "Greska pri cuvanju podataka"
                }
            }
        }
    }
}
