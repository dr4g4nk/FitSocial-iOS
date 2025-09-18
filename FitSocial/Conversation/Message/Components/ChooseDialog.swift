//
//  ChooseDialog.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 9. 2025..
//

import SwiftUI

struct ChooseDialog : View {
    
    let onChoosePhoto: () -> Void
    let onChooseDocument: () -> Void
    
    var body : some View {
        VStack(spacing: 12) {
            Capsule().fill(.tertiary)
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            VStack(spacing: 8) {
                Button(
                    "Odaberi fotografije",
                    systemImage: "photo",
                    action: onChoosePhoto
                )

                Button(
                    "Odaberi dokumente",
                    systemImage: "doc.text",
                    action: onChooseDocument
                )
            }
            .padding(.vertical, 8)

            Spacer(minLength: 0)

            Button("Zatvori", role: .cancel) {}
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .padding(.bottom, 12)
        }
    }
}
