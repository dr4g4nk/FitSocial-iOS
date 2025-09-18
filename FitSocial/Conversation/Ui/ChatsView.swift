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
            onRowTap: onOpenChat,
            onDelete: vm.onDelete
        )
        .refreshable { vm.refresh() }
        .overlay {
            if let message = vm.errorMessage, vm.items.isEmpty {
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
    let onDelete: (Chat) -> Void
    
    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("Nema poruka za prikaz", systemImage: "bubble.left.and.text.bubble.right.rtl")
            }
            ForEach(items) { chat in
                ChatRowLink(chat: chat, onTap: onRowTap)
                    .listRowSeparator(.automatic)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDelete(chat)
                        } label: {
                            Label("Obriši", systemImage: "trash")
                        }
                    }
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
        .listStyle(.plain)
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
