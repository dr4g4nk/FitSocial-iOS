//
//  ChatsView.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import SwiftUI

struct ChatsView: View {
    @Bindable private var vm: ChatsViewModel
    let onOpenChat: (Chat) -> Void

    init(viewModel: ChatsViewModel, onOpenChat: @escaping (Chat) -> Void) {
        vm = viewModel
        self.onOpenChat = onOpenChat
    }

    var body: some View {
        ChatsContentView(
            items: vm.items,
            isLoading: vm.isLoading,
            reachedEnd: vm.reachedEnd,
            loadMore: {
                vm.loadNextPageIfNeeded(
                    currentItemId: vm.items.last?.id
                )
            },
            onRowTap: onOpenChat
        )
        .refreshable { vm.refresh() }
        .overlay {
            if vm.isLoading && vm.items.isEmpty {
                ProgressView("Učitavam…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = vm.errorMessage, vm.items.isEmpty {
                VStack(spacing: 12) {
                    Text("Greška").font(.headline)
                    Text(message).font(.subheadline)
                        .multilineTextAlignment(
                            .center
                        )
                    Button("Pokušaj ponovo") { vm.refresh() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            if vm.errorMessage != nil && !vm.isLoading {
                IOErrorOverlayView(onRetry: { vm.retry() })
            }
        }
        .searchable(
            text: $vm.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Pretraga"
        )
        .onChange(of: vm.searchText) { _, new in
            vm.onSearchTextChanged(new)
        }
        .onAppear(perform: { vm.loadInitial() })
    }
}

struct ChatsContentView: View {
    let items: [Chat]
    let isLoading: Bool
    let reachedEnd: Bool
    let loadMore: () -> Void
    let onRowTap: (Chat) -> Void

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(items) { chat in
                    ChatRowLink(chat: chat, onTap: onRowTap)
                        .listRowSeparator(.automatic)
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if !reachedEnd {
                    PagingTrigger(onVisible: loadMore)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ChatRowLink: View {
    let chat: Chat
    let onTap: (Chat) -> Void

    var accessibility: String {
        let lastMessage = chat.text ?? ""
        let time = formattedTime(chat.lastMessageTime)
        return "\(chat.display), \(lastMessage), \(time)"
    }

    var body: some View {
        ChatRow(chat: chat)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibility)
            .onTapGesture {
                onTap(chat)
            }
    }
}
