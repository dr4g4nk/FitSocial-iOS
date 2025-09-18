//
//  HealthStoreManager.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
class StepCounterManager {
    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false
    private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined

    func requestStepCountPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit nije dostupan na ovom uređaju")
            return
        }

        guard
            let stepCountType = HKQuantityType.quantityType(
                forIdentifier: .stepCount
            )
        else {
            print("Step count tip nije dostupan")
            return
        }

        Task {
            do {
                try await healthStore.requestAuthorization(
                    toShare: [stepCountType],
                    read: [stepCountType]
                )
                
                authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
                self.isAuthorized = authorizationStatus == .sharingAuthorized
            } catch {
                print("Greška pri zahtevanju dozvole za HealthKit: \(error)")
                
            }
        }
    }

    func checkStepCountAuthorization(){
        guard
            let stepCountType = HKQuantityType.quantityType(
                forIdentifier: .stepCount
            )
        else {
            return
        }

        authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }

    // MARK: - Step Data Retrieval

    func getStepCount(from startDate: Date, to endDate: Date = Date()) async
        -> Int
    {
        guard authorizationStatus == .sharingAuthorized else {
            print("Nema dozvole za čitanje podataka o koracima")
            return 0
        }

        guard
            let stepCountType = HKQuantityType.quantityType(
                forIdentifier: .stepCount
            )
        else {
            return 0
        }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in

                if let error = error {
                    print("Greška pri dohvatanju koraka: \(error)")
                    continuation.resume(returning: 0)
                    return
                }

                let stepCount =
                    result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(stepCount))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Real-time Step Updates (za live praćenje)

    private var timer: Timer?
    func startLiveStepTracking(
        from startDate: Date,
        updateHandler: @escaping (Int) -> Void
    ) {
        guard authorizationStatus == .sharingAuthorized else { return }
        guard
            HKQuantityType.quantityType(
                forIdentifier: .stepCount
            ) != nil
        else { return }

        // Timer za periodično ažuriranje (svake 2 sekunde)
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { timer in
            Task {
                let steps = await self.getStepCount(from: startDate)
                DispatchQueue.main.async {
                    updateHandler(steps)
                }
            }
        }
    }
    
    func stopLiveStepTracking(){
        if let timer = timer {
            timer.invalidate()
        }
        self.timer = nil
    }

    func saveCurrentStepsToUserDefaults(
        steps: Int,
        key: String = "current_activity_steps"
    ) {
        UserDefaults.standard.set(steps, forKey: key)
    }

    func getCurrentStepsFromUserDefaults(key: String = "current_activity_steps")
        -> Int
    {
        return UserDefaults.standard.integer(forKey: key)
    }

    func clearCurrentStepsFromUserDefaults(
        key: String = "current_activity_steps"
    ) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
