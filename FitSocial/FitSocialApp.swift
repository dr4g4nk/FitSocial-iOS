//
//  FitSocialApp.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import FirebaseCore
import FirebaseMessaging
import SwiftUI

#if DEBUG
    import Atlantis
#endif

class FitSocialAppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate,
    UNUserNotificationCenterDelegate
{
    var container: FitSocialContainer!
    private let notificationManager = NotificationManager.shared

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        print(URL.applicationSupportDirectory.path(percentEncoded: false))
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        notificationManager.setupNotificationCategories()

        return true

    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (
            UIBackgroundFetchResult
        ) -> Void
    ) {

        print(userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }

    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        Task {
            do {
                let token = try KeychainTokenStore.fitSocial.readFcmToken()
                guard let fcmToken = fcmToken, token != fcmToken else { return }

                try KeychainTokenStore.fitSocial.saveFcmToken(
                    fcmToken: fcmToken
                )

                do {
                    if try await container.session.isLoggedIn() {
                        try await container.fcmRepo.attachFcmToken(
                            token: fcmToken
                        )
                    }
                } catch {
                    print("Error while attaching token to user")
                }

            } catch {
                print(
                    "Error on receiving registration token: \(error.localizedDescription)"
                )
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        let category = notification.request.content.categoryIdentifier
        let userInfo = notification.request.content.userInfo

        if category == "chat_messages" {
            if let chatIdStr = userInfo["chatId"] as? String,
                let chatId = Int(chatIdStr)
            {
                print(chatId)

                if container.contersationNotificationHandler.currentChatId
                    == chatId
                {
                    if let data = userInfo["data"] as? String {
                        container.contersationNotificationHandler.handle(data)
                        completionHandler([])
                        return
                    }
                }
            }
        }

        completionHandler([.banner, .list, .badge])
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {

    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let category = response.notification.request.content.categoryIdentifier
        let userInfo = response.notification.request.content.userInfo

        if category == "chat_messages" {
            if response.actionIdentifier == "reply_action",
                let textResponse = response as? UNTextInputNotificationResponse
            {
                let replyText = textResponse.userText

                if let chatIdString = userInfo["chatId"] as? String,
                    let chatId = Int(chatIdString)
                {
                    Task {
                        try? await container.messageRepo.create(
                            MessageDto(chatId: chatId, content: replyText)
                        )
                    }
                }
            } else if response.actionIdentifier == "open_chat"
                || response.actionIdentifier
                    == "com.apple.UNNotificationDefaultActionIdentifier",
                let chatIdStr = userInfo["chatId"] as? String,
                let chatId = Int(chatIdStr)
            {
                NotificationCenter.default.post(
                    name: .openChat,
                    object: nil,
                    userInfo: ["chatId": chatId]
                )
            }
        } else if category == "exercise_tracking"
            || category == "exercise_reminder"
        {
            NotificationCenter.default.post(
                name: .exercise,
                object: nil,
                userInfo: nil
            )
        }

        completionHandler()

    }
}

private func loadRocketSimConnect() {
    #if DEBUG
        guard
            Bundle(
                path:
                    "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework"
            )?.load() == true
        else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
    #endif
}

@main
struct FitSocialApp: App {
    @UIApplicationDelegateAdaptor(FitSocialAppDelegate.self) var delegate
    @State var container = FitSocialContainer()

    init() {
        delegate.container = container
        #if DEBUG
            loadRocketSimConnect()
            Atlantis.start(hostName: "dragans-macbook-pro.local.")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            FitSocialView(container: container)
                .environment(container.auth)
                .environment(LocationManager.shared)
                .modelContainer(container.modelContainer)
                .environment(container.contersationNotificationHandler)
                .onOpenURL { url in
                    DeepLinkRouter.shared.handle(url: url)
                }
        }
    }
}
