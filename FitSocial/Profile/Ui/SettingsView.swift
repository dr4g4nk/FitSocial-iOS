//
//  SettingsView.swift
//  FitSocial
//
//  Created by Dragan Kos on 19. 9. 2025..
//

import SwiftUI

struct SettingsView: View {
    enum Theme: String, CaseIterable, Identifiable {
        case light = "Svetla tema"
        case dark = "Tamna tema"
        case system = "Sistemska tema"
        var id: String { rawValue }
    }
    
    @EnvironmentObject var themeManager: ThemeManager
    var onLogout: ()->Void
    
    @State private var showDialog = false

    var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "paintpalette")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }

                            Text("Tema")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .accessibilityAddTraits(.isHeader)

                            Spacer()
                        }
                        .padding(.vertical, 4)

                        VStack(spacing: 0) {
                            RadioRow(
                                icon: "sun.max.fill",
                                title: "Svetla tema",
                                isSelected: themeManager.appTheme == .light
                            ) {
                                themeManager.appTheme = .light
                            }

                            Divider()

                            RadioRow(
                                icon: "moon.fill",
                                title: "Tamna tema",
                                isSelected: themeManager.appTheme == .dark
                            ) {
                                themeManager.appTheme = .dark
                            }

                            Divider()

                            RadioRow(
                                icon: "iphone",
                                title: "Sistemska tema",
                                isSelected: themeManager.appTheme == .system
                            ) {
                                themeManager.appTheme = .system
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    VStack(spacing: 0) {
                        SettingsRow(
                            iconName: "shield.lefthalf.fill",
                            iconBackground: Color(.systemGray4),
                            title: "Politika privatnosti"
                        ) {
                            // navigate to privacy
                        }

                        Divider()

                        SettingsRow(
                            iconName: "questionmark.circle.fill",
                            iconBackground: Color(.systemPurple).opacity(0.9),
                            title: "Pomoć"
                        ) {
                            // navigate to help
                        }

                        Divider()

                        SettingsRow(
                            iconName: "info.circle",
                            iconBackground: Color(.systemGray3),
                            title: "O aplikaciji"
                        ) {
                            // show about
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        SettingsRow(
                            iconName: "rectangle.portrait.and.arrow.right",
                            iconBackground: Color(.systemRed),
                            title: "Odjavi se",
                            titleColor: Color(.systemRed)
                        ) {
                           showDialog = true
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .alert(
                "Odjava",
                isPresented: $showDialog
            ) {
                Button("Odjavi se", role: .destructive) {
                    onLogout()
                }
                Button("Odustani", role: .cancel){ showDialog = false }
            } message: {
                Text("Da li ste sigurni da se želite odjaviti iz aplikacije?")
            }
            .background(Color(.systemBackground).ignoresSafeArea())
    }
}


struct RadioRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 36, height: 36)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .padding(.trailing, 6)

                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)

                ZStack {
                    Circle()
                        .strokeBorder(Color.secondary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}


struct SettingsRow: View {
    let iconName: String
    let iconBackground: Color
    let title: String
    var titleColor: Color = .primary
    let action: () -> Void

    init(iconName: String, iconBackground: Color, title: String, titleColor: Color = .primary, action: @escaping () -> Void) {
        self.iconName = iconName
        self.iconBackground = iconBackground
        self.title = title
        self.titleColor = titleColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 44, height: 44)
                    Image(systemName: iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.leading, 12)

                Text(title)
                    .foregroundColor(titleColor)
                    .font(.body)
                    .padding(.leading, 8)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .padding(.trailing, 16)
            }
            .frame(height: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView(onLogout: {})
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")

            SettingsView(onLogout: {})
                .preferredColorScheme(.light)
                .previewDisplayName("Light")
        }
    }
}
