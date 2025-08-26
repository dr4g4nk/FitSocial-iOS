//
//  PostActionsSheet.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import SwiftUI

/// Donja lista akcija za objavu (sheet)
struct PostActionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let isOwner: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Capsule().fill(.tertiary)
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            VStack(spacing: 8) {
                if isOwner {
                    ActionRow(
                        title: "Izmijeni objavu",
                        systemImage: "pencil",
                        action: {
                            onEdit()
                            dismiss()
                        }
                    )

                    ActionRow(
                        title: "Obriši objavu",
                        systemImage: "trash",
                        action: {
                            onDelete()
                            dismiss()
                        }
                    )
                }

                ActionRow(
                    title: "Prijavi objavu",
                    systemImage: "exclamationmark.bubble",
                    action: {
                        onReport()
                        dismiss()
                    }
                )
            }
            .padding(.vertical, 8)

            Spacer(minLength: 0)

            Button("Zatvori") {
                dismiss()
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
        .presentationDetents([.fraction(0.35), .medium]) // iOS 16+
        .presentationDragIndicator(.hidden)
    }
}

/// Jedan red sa akcijom (ikonica + naslov), podržava destructive stil
private struct ActionRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .imageScale(.large)
                Text(title)
                    .font(.body)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}
