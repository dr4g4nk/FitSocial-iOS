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

    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        HStack {
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: remainingSlots,
                matching: .any(of: [.images, .videos])
            ) {
                Label("Biblioteka", systemImage: "photo")
            }
            .onChange(of: pickerItems) { _, newValue in
                if !newValue.isEmpty { onPick(newValue) }
                pickerItems.removeAll()
            }
            
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
