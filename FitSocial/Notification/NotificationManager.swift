//
//  NotificationManager.swift
//  FitSocial
//
//  Created by Dragan Kos on 4. 9. 2025..
//

import Foundation
import UserNotifications


public class NotificationManager{
    
    public static let shared = NotificationManager()
    
    public private(set) var isAuthorized = false
    public private(set) var error: (any Error)? = nil
    
    public var current: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    public func setupNotificationCategories() {
        
        let replyActionIcon = UNNotificationActionIcon(systemImageName: "paperplane.fill")
        let reply = UNTextInputNotificationAction(
            identifier: "reply_action",
            title: "Odgovori",
            options: [.authenticationRequired],
            icon: replyActionIcon,
            textInputButtonTitle: "Pošalji",
            textInputPlaceholder: "Napiši poruku…"
        )

        let chatCategory = UNNotificationCategory(
            identifier: "chat_messages",
            actions: [reply],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let exerciseReminderCategory = UNNotificationCategory(identifier: "exercise_reminder", actions: [], intentIdentifiers: [])
        let exerciesTrackingCategory = UNNotificationCategory(identifier: "exercise_tracking", actions: [], intentIdentifiers: [])

        UNUserNotificationCenter.current().setNotificationCategories([chatCategory, exerciseReminderCategory, exerciesTrackingCategory])
    }
    
    public func requestAuthorization(_ completionHandler: @escaping (Bool, (any Error)?) -> Void = { bool, error in }){
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .badge, .sound,
        ]){ granted, error in
            self.isAuthorized = granted
            self.error = error
            completionHandler(granted, error)
        }
    }
    
    public func checkAuthorization(_ completionHandler: @escaping (Bool?, (any Error)?) -> Void  = { bool, error in }, request: Bool = true){
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                print("Nije još traženo")
                if request {
                    self.requestAuthorization { granted, error in
                        completionHandler(granted, error)
                    }
                }
                else {
                    completionHandler(nil, nil)
                }
            case .denied:
                print("Odbijeno – korisnik mora ići u podešavanja")
                self.isAuthorized = false
                completionHandler(self.isAuthorized, nil)
            case .authorized, .provisional, .ephemeral:
                print("Dozvoljeno")
                self.isAuthorized = true
                completionHandler(self.isAuthorized, nil)
            @unknown default:
                break
            }
        }
    }
}

extension Notification.Name {
    static let openChat = Notification.Name("openChat")
    static let exercise = Notification.Name("exercise")
}
