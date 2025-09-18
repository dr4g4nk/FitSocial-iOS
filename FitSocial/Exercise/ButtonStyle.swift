//
//  PrimaryButtonStyle.swift
//  FitSocial
//
//  Created by Dragan Kos on 2. 9. 2025..
//


import CoreLocation
import MapKit
import Observation
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(
                .easeInOut(duration: 0.1),
                value: configuration.isPressed
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(color)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(backgroundColor))
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(
                .easeInOut(duration: 0.1),
                value: configuration.isPressed
            )
    }
}
