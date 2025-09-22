//
//  ThemeManager.swift
//  FitSocial
//
//  Created by Dragan Kos on 19. 9. 2025..
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case light, dark, system
}

final class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var appTheme: AppTheme = .system {
        willSet { objectWillChange.send() }
    }
}
