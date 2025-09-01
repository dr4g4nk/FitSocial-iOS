//
//  ChatsScreen.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import SwiftUI

struct ConversationScreen: View {

    private let conversationContainer: ConversationContainer
    @State private var chatsViewModel: ChatsViewModel

    @State private var chatUserListViewModel: ChatUserListViewModel

    @State private var navPath = NavigationPath()
    @State private var isCreating = false

    init(conversationContainer: ConversationContainer) {
        self.conversationContainer = conversationContainer
        self.chatsViewModel = conversationContainer.makeChatsViewModel()
        self.chatUserListViewModel =
            conversationContainer.makeChatUserLIstViewModel()
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            ChatsView(
                viewModel: chatsViewModel,
                onOpenChat: { chat in
                    navPath.append(chat)
                }
            )
            .navigationTitle("Poruke")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isCreating = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Novi chat")
                }
            }
            .navigationDestination(for: Chat.self) { chat in
                let vm = conversationContainer.makeChatDetailViewModel(
                    chat: chat
                )
                ChatDetailView(
                    vm: vm
                )
                .navigationTitle(chat.display)
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $isCreating, onDismiss: {chatUserListViewModel.clear()}) {
                NavigationStack {
                    ChatUserListView(
                        vm: chatUserListViewModel,
                        onNext: { users in
                            let chat: Chat = .init(id: -1, users: users)
                            navPath.append(chat)
                            isCreating = false
                        }
                    )
                    .navigationTitle("Korisnici")
                    .navigationBarTitleDisplayMode(.large)
                }
            }
            .navigationBarTitleDisplayMode(.large)
        }.toolbar(navPath.isEmpty ? .visible : .hidden, for: .tabBar)
    }
}
