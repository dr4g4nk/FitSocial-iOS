//
//  MessageListView.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 9. 2025..
//

import SwiftUI

struct MessageListView: View {
    let messages: [MessageEntity]
    let onLoadMoreIfNeed: (_ index: Int) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if messages.isEmpty {
                    ContentUnavailableView("Nema poruka za prikaz", systemImage: "bubble.left.and.text.bubble.right.rtl")
                        .flippedUpsideDown()
                }
                ForEach(Array(messages.enumerated()), id: \.element.id) {
                    index,
                    msg in
                    MessageRow(message: msg)
                        .id(msg.id)
                        .padding(.horizontal, 12)
                        .flippedUpsideDown()
                        .onAppear {
                            onLoadMoreIfNeed(index)
                        }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 8)
        }
        .scrollDismissesKeyboard(.immediately)
        .flippedUpsideDown()
    }
}
