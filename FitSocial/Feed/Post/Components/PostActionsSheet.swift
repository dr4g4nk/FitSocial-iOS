//
//  PostActionsSheet.swift
//  FitSocial
//
//  Created by Dragan Kos on 26. 8. 2025..
//

import SwiftUI

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
                    Button(
                        "Izmijeni objavu",
                        systemImage: "pencil",
                        action: {
                            onEdit()
                            dismiss()
                        }
                    )

                    Button(
                        "Obriši objavu",
                        systemImage: "trash",
                        role: .destructive,
                        action: {
                            onDelete()
                            dismiss()
                        }
                    )
                }

                Button(
                    "Prijavi objavu",
                    systemImage: "exclamationmark.bubble",
                    action: {
                        onReport()
                        dismiss()
                    }
                )
            }
            .padding(.vertical, 8)

            Spacer(minLength: 0)

            Button("Zatvori", role: .cancel) {
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
        .presentationDetents([.fraction(0.35), .medium])  // iOS 16+
        .presentationDragIndicator(.hidden)
        
    }
}
