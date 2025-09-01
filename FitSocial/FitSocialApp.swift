//
//  FitSocialApp.swift
//  FitSocial
//
//  Created by Dragan Kos on 12. 8. 2025..
//

import FirebaseCore
import SwiftUI

#if DEBUG
    import Atlantis
#endif

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,

        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        FirebaseApp.configure()

        return true

    }

}

@main
struct FitSocialApp: App {

    init() {
        // 2. Connect to your Macbook
        #if DEBUG
            Atlantis.start(hostName: "dragans-macbook-pro.local.")

        // 3. (Optional)
        // If you have many Macbooks on the same WiFi Network, you can specify your Macbook's name
        // Find your Macbook's name by opening Proxyman App -> Certificate Menu -> Install Certificate for iOS -> With Atlantis ->
        // Click on "How to start Atlantis" -> Select "SwiftUI" Tab
        // Atlantis.start("Your's Macbook Pro")
        #endif
    }

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State var container = FitSocialContainer()

    var body: some Scene {
        WindowGroup {
            FitSocialView(container: container)
                .environment(container.auth)
        }

    }
}
