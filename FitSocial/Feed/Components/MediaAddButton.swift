//
//  MediaAddButton.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import SwiftUI
import PhotosUI

struct MediaAddButton: View {
    let remainingSlots: Int
    var onPick: ([PhotosPickerItem]) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mediji").font(.headline)

            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: remainingSlots,
                matching: .any(of: [.images, .videos])
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill").imageScale(.large)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dodaj slike ili videe")
                        Text("Preostalo: \(remainingSlots)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
            }
            .onChange(of: pickerItems) { _, newValue in
                if !newValue.isEmpty { onPick(newValue) }
                pickerItems.removeAll()
            }
        }
    }
}
