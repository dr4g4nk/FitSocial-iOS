//
//  WorkoutReminder.swift
//  FitSocial
//
//  Created by Dragan Kos on 4. 9. 2025..
//


import Foundation
import SwiftData


struct WorkoutReminder: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var workoutType: String
    var scheduledDate: Date

    init(id: String, title: String, workoutType: String, scheduledDate: Date) {
        self.id = id
        self.title = title
        self.workoutType = workoutType
        self.scheduledDate = scheduledDate
    }
}

@Model
final class WorkoutReminderEntity: Identifiable, Hashable {
    var id: String
    var title: String
    var workoutType: String
    var scheduledDate: Date

    init(id: String, title: String, workoutType: String, scheduledDate: Date) {
        self.id = id
        self.title = title
        self.workoutType = workoutType
        self.scheduledDate = scheduledDate
    }
}

extension WorkoutReminderEntity {
    func toDomain()-> WorkoutReminder{
        WorkoutReminder(id: id, title: title, workoutType: workoutType, scheduledDate: scheduledDate)
    }
    
    static func fromDomain(_ w: WorkoutReminder)-> WorkoutReminderEntity{
        WorkoutReminderEntity(id: w.id, title: w.title, workoutType: w.workoutType, scheduledDate: w.scheduledDate)
    }
}
