//
//  StatCard.swift
//  FitSocial
//
//  Created by Dragan Kos on 2. 9. 2025..
//


import CoreLocation
import MapKit
import Observation
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}