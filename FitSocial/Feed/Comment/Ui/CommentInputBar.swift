//
//  CommentInputBar.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftUI

struct CommentInputBar: View {
    @Binding var text: String
    let isSending: Bool
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            TextField("Napiši komentar…", text: $text, axis: .vertical)
                .foregroundStyle(.primary)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )
                .lineLimit(1...5)
                .focused(isFocused)
                .accessibilityLabel("Napiši komentar…")
                .onSubmit {
                    if !isSending
                        && !text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    {
                        onSend()
                    }
                }

            Button(action: onSend) {
                if isSending {
                    ProgressView()
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .disabled(
                isSending
                    || text.trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.thickMaterial)
    }
}
