//
//  InputBar.swift
//  FitSocial
//
//  Created by Dragan Kos on 28. 8. 2025..
//

import SwiftUI

struct MessageInputBar: View {
    @Binding var text: String
    let showExtras: Bool
    let isSending: Bool
    let onSend: () -> Void
    let onCamera: () -> Void
    let onAttach: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if showExtras {
                Button(action: onCamera) {
                    Image(systemName: "camera")
                        .font(.title3)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Kamera")

                Button(action: onAttach) {
                    Image(systemName: "paperclip")
                        .font(.title3)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dodaj prilog")
            }

            TextField("Poruka...", text: $text, axis: .vertical)
                .padding()
                .lineLimit(1...6)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
                .focused($focused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Zatvori tastaturu") { focused = false }
                    }
                }
                .accessibilityLabel("Poruka...")
                .onSubmit {
                    if !isSending
                        && !text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    {
                        onSend()
                    }
                }

            if !showExtras {
                Button(action: onSend) {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                            .frame(width: 44, height: 44)
                    }
                }
                .disabled(
                    isSending
                        || text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                )
                .accessibilityLabel("Pošalji")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}
