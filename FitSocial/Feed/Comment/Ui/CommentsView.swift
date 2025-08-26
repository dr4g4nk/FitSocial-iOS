//
//  CommentView.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import SwiftUI

struct CommentsView: View {
    @Bindable private var vm: CommentsViewModel
    @State private var draft = ""
    
    @Environment(AuthManager.self) private var auth: AuthManager

    init(vm: CommentsViewModel) {
        self.vm = vm
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Capsule().frame(width: 36, height: 4).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Text("Komentari")
                .font(.headline)
                .padding(.vertical, 6)

            Divider()

            // Lista komentara
            List {
                ForEach(vm.comments) { c in
                    CommentRow(comment: c)
                        .onAppear {
                            Task { await vm.loadNextPageIfNeeded(current: c) }
                        }
                }
                if vm.isLoading && vm.comments.isEmpty {
                    Section { ProgressView().frame(maxWidth: .infinity) }
                } else if vm.isLoading {
                    Section { HStack { Spacer(); ProgressView(); Spacer() } }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await vm.refresh()
            }

            if(auth.isLoggedIn){
                // Input
                CommentInputBar(text: $draft, isSending: vm.isSending) {
                    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    Task {
                        try? await vm.send(text: text)
                        draft = ""
                    }
                }
            }
           /* .keyboardToolbarSend { // vidi ekstenziju ispod
                let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                Task {
                    try? await vm.send(text: text)
                    draft = ""
                }
            }*/
        }
        .task {
            if vm.comments.isEmpty { await vm.refresh() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
