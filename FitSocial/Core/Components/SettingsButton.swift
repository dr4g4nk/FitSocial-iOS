//
//  SettingsButton.swift
//  FitSocial
//
//  Created by Dragan Kos on 16. 9. 2025..
//

import SwiftUI

public struct SettingsButton: View {
    @Environment(\.openURL) private var openURL

    var url: URL?
    var action: () -> Void = {}
    init(url: URL? = URL(string: UIApplication.openSettingsURLString) ,action: @escaping () -> Void = {}) {
        self.url = url
        self.action = action
    }

    public var body: some View {
        Button("Otvori podešavanja") {
            if let url = url {
                openURL(url)
            }

            action()
        }
    }
}

#Preview {
    SettingsButton()
}
