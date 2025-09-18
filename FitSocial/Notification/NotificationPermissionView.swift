//
//  NotificationPermissionView.swift
//  FitSocial
//
//  Created by Dragan Kos on 16. 9. 2025..
//

import SwiftUI

struct NotificationPermissionView: View {
    var onRequestPermission: (() -> Void)?
    var onSkip: (() -> Void)?

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(Color(.systemYellow))
                        .accessibilityHidden(true)

                    Circle()
                        .fill(Color(.systemRed))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Text("7")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 8, y: -8)
                        .accessibilityLabel("7 novih obavještenja")
                }
                .padding(.bottom, 18)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(
                            "FitSocial koristi obavještenja da bi te obavijestio o novim porukama i aktivnostima."
                        )
                        .font(.system(.title3, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .accessibilityAddTraits(.isHeader)

                        Text(
                            "Omogućiš obavještenja kako ne bi propustio važne informacije."
                        )
                        .font(.system(.body))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                    }
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.leading)

                    Button(action: {
                        onRequestPermission?()
                    }) {
                        Text("Omogući obavještenja")
                            .font(.system(.body, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(PrimaryButtonBackground())
                            .cornerRadius(28)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("enableNotificationsButton")
                    .accessibilityLabel("Omogući obavještenja")
                    .accessibilityHint("Otvori dijalog za dozvole obavještenja")

                    Button(action: {
                        onSkip?()
                    }) {
                        Text("Preskoči")
                            .font(.system(.body))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 2)
                    .accessibilityIdentifier("skipButton")
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(
                            color: Color(.black).opacity(0.25),
                            radius: 8,
                            x: 0,
                            y: 6
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)

                Spacer()
            }
            .padding(.horizontal)
        }
        .preferredColorScheme(nil)
    }
}

private struct PrimaryButtonBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(
                                    color: Color(.systemIndigo).opacity(0.9),
                                    location: 0.0
                                ),
                                .init(
                                    color: Color(.systemPurple).opacity(0.9),
                                    location: 1.0
                                ),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(
                                    color: Color(.systemBlue).opacity(0.95),
                                    location: 0.0
                                ),
                                .init(
                                    color: Color(.systemIndigo).opacity(0.95),
                                    location: 1.0
                                ),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }
}

struct NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NotificationPermissionView(
                onRequestPermission: { print("Request permission") },
                onSkip: { print("Skip") }
            )
            .environment(\.sizeCategory, .large)
            .previewDisplayName("Light")

            NotificationPermissionView(
                onRequestPermission: {},
                onSkip: {}
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
        }
    }
}
