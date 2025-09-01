//
//  MediaPicker.swift
//  FitSocial
//
//  Created by Dragan Kos on 30. 8. 2025..
//

import SwiftUI
import PhotosUI

public struct MediaPicker: View {
    public let title: String
    public let systemImage: String
    public let maxSelectionCount: Int
    public var onPick: ([PhotosPickerItem]) -> Void
    
    @State private var selection: [PhotosPickerItem] = []
    
    public var body: some View {
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: maxSelectionCount,
            matching: .any(of: [.images, .videos])
        ) {
            Label(title, systemImage: systemImage)
        }
        .onChange(of: selection) { _, newValue in
            if !newValue.isEmpty { onPick(newValue) }
            selection.removeAll()
        }
    }
}
