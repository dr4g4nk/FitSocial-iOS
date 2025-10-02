//
//  WorkoutReminderViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 4. 9. 2025..
//

import SwiftData
import UIKit
import UserNotifications

@MainActor
@Observable
class WorkoutReminderViewModel {
    private let remindersStore: WorkoutReminderLocalStore
    private(set) var reminders: [WorkoutReminder] = []

    let notificationManager = NotificationManager.shared

    var workoutTitle: String = ""
    var workoutType: String = ActivityType.walking.rawValue
    var selectedDate: Date = Date()
    var reminderTime: Date = Date()

    var alertMessage: String = ""
    var showingAlert = false

    var showScheduleForm = false

    var errorMessage: String?

    init(modelContainder: ModelContainer) {
        self.remindersStore = WorkoutReminderLocalStore(
            container: modelContainder
        )
    }

    func scheduleReminder() {
        guard !workoutTitle.isEmpty else {
            alertMessage = "Molimo unesite naziv vežbe"
            showingAlert = true
            return
        }

        checkAuthorization { granted, error in
            guard granted else { return }

            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents(
                [.year, .month, .day],
                from: self.selectedDate
            )
            let timeComponents = calendar.dateComponents(
                [.hour, .minute],
                from: self.reminderTime
            )

            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute

            guard let scheduledDate = calendar.date(from: dateComponents) else {
                return
            }

            // Korišćenje UNUserNotificationCenter za kreiranje notifikacije
            let identifier = UUID().uuidString
            let content = UNMutableNotificationContent()
            content.title = "Vreme za vežbanje!"
            content.body = "\(self.workoutTitle) - \(self.workoutType)"
            content.sound = UNNotificationSound.default
            content.interruptionLevel = .timeSensitive
            content.categoryIdentifier = "exercise_reminder"

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            // Dodavanje notifikacije
            self.notificationManager.current.add(request) { error in
                DispatchQueue.main.async { [self] in
                    if let error = error {
                        alertMessage =
                            "Greška pri zakazivanju: \(error.localizedDescription)"
                        showingAlert = true
                    } else {
                        let newReminder = WorkoutReminderEntity(
                            id: identifier,
                            title: self.workoutTitle,
                            workoutType: self.workoutType,
                            scheduledDate: scheduledDate
                        )
                        self.reminders.append(newReminder.toDomain())
                        self.saveReminders(newReminder)

                        // Reset forme
                        self.workoutTitle = ""
                        self.selectedDate = Date()
                        self.reminderTime = Date()
                    }
                }
            }
        }
    }

    func deleteReminder(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let reminder = reminders[index]
                let id = reminder.id
                do {
                    try await remindersStore.deleteAll(
                        predicate: #Predicate { w in
                            w.id == id
                        }
                    )
                    notificationManager.current
                        .removePendingNotificationRequests(withIdentifiers: [
                            reminder.id
                        ])

                    reminders.remove(at: index)
                } catch {
                    errorMessage = "Greska pri brisanju!"
                }
            }
        }
    }

    func loadReminders() {
        Task {
            do {
                reminders = try await remindersStore.fetch(
                    sortBy: [
                        .init(\.scheduledDate, order: .forward)
                    ],
                    transform: { w in w.toDomain() }
                )
            } catch {
                errorMessage =
                    "Greska pri ucitavanju podjetnika. Pokusajte ponovo"
            }
        }
    }

    func saveReminders(_ new: WorkoutReminderEntity) {
        Task {
            do {
                try await remindersStore.create(new)
            } catch {
                errorMessage = "Greska pri cuvanju podjetnika. Pokusajte ponovo"
            }
        }
    }

    public func checkAuthorization(
        _ completionHandler: @escaping (Bool, (any Error)?) -> Void = {
            bool,
            error in
        }
    ) {
        notificationManager.checkAuthorization { granted, error in
            if let granted = granted {
                self.showPermissionAlert = !granted
                if !granted {
                    self.unauthorizeMesssage =
                        "Obavještenja su potrebna kako bismo vas podsjetili na zakazane aktivnosti. Možete ih uključiti u Podešavanjima."
                }

                completionHandler(granted, error)
            }
        }
    }

    public private(set) var unauthorizeMesssage: String?

    public var showPermissionAlert: Bool = false
}
