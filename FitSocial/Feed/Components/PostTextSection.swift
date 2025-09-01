//
//  PostTextSection.swift
//  FitSocial
//
//  Created by Dragan Kos on 21. 8. 2025..
//


import SwiftUI

struct PostTextSection: View {
    @Binding var text: String
    let maxLength: Int
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tekst")
                .font(.headline)
                .accessibilityHidden(true)

            TextField("Podijelite što vam je na umu…", text: $text, axis: .vertical)
                .focused($focused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Zatvori tastaturu") { focused = false }
                    }
                }
                .lineLimit(8)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Tekst objave")

            HStack {
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(.footnote)
                    .foregroundStyle(text.count > maxLength ? .red : .secondary)
            }
        }
    }
}
