//
//  MediaPickerBar.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//

import SwiftUI
import PhotosUI

struct MediaPickerBar: View {
    let remainingSlots: Int
    var onPick: ([PhotosPickerItem]) -> Void
    var onShowCamera: ()->Void

    var body: some View {
        HStack {
            MediaPicker(title: "Odaberi fotografije", systemImage: "photo", maxSelectionCount: remainingSlots, onPick: onPick)
            Spacer()
            Button {
                onShowCamera()
            } label: {
                Label("Kamera", systemImage: "camera")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(.bar)
    }
}
