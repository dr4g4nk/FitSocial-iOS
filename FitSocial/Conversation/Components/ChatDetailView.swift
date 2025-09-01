//
//  ChatDetailView.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//


import SwiftUI

struct ChatDetailView: View {
    let chat: Chat
    var body: some View {
        Text("Chat #\(chat.id)\n\(chat.subject ?? "")")
            .font(.title2)
            .navigationTitle(
                chat.subject
                    ?? chat.users.map({ user in
                        user.displayName
                    }).joined(separator: ", ")
            )
            .navigationBarTitleDisplayMode(.inline)
    }
}