//
//  ActivityType.swift
//  FitSocial
//
//  Created by Dragan Kos on 2. 9. 2025..
//


import CoreLocation
import MapKit
import Observation
import SwiftUI

enum ActivityType: String, CaseIterable {
    case walking = "Šetnja"
    case running = "Trčanje"
    case cycling = "Biciklizam"

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        }
    }

    var color: Color {
        switch self {
        case .walking: return .green
        case .running: return .orange
        case .cycling: return .blue
        }
    }

    var backgroundGradient: LinearGradient {
        switch self {
        case .walking:
            return LinearGradient(
                colors: [.green.opacity(0.8), .green.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .running:
            return LinearGradient(
                colors: [.orange.opacity(0.8), .orange.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cycling:
            return LinearGradient(
                colors: [.blue.opacity(0.8), .blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    
    }
}

extension ActivityType {
    init?(from string: String) {
        self.init(rawValue: string)
    }
}
