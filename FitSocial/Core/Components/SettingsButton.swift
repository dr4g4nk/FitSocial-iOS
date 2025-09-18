//
//  SettingsButton.swift
//  FitSocial
//
//  Created by Dragan Kos on 16. 9. 2025..
//

import SwiftUI

public struct SettingsButton: View {
    @Environment(\.openURL) private var openURL

    var action: () -> Void = {}
    init(action: @escaping () -> Void = {}) {
        self.action = action
    }

    public var body: some View {
        Button("Otvori podešavanja") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }

            action()
        }
    }
}

#Preview {
    SettingsButton()
}
