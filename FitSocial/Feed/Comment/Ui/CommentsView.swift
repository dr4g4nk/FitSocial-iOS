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
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth: AuthManager
    @FocusState private var isInputFocused: Bool

    init(vm: CommentsViewModel) {
        self.vm = vm
    }

    var body: some View {
        VStack {
            HStack {
                Capsule().frame(width: 36, height: 4).foregroundStyle(
                    .secondary
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 4)

            HStack{
                Spacer()
                Text("Komentari")
                    .font(.headline)
                    .padding(.vertical, 6)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .font(.system(size: 16))
                        .background(Circle().fill(.thickMaterial).frame(width: 40, height: 40))
                }
                
            }
            .padding(.horizontal, 16)
            
            Divider()

            List {
                ForEach(vm.comments) { c in
                    CommentRow(comment: c)
                        .onAppear {
                            Task { await vm.loadNextPageIfNeeded(current: c) }
                        }
                }
                if vm.comments.isEmpty {
                    ContentUnavailableView("Još nema komentara na ovoj obravi. Budite prvi, ostavite komentar", systemImage: "text.bubble")
                }
                if vm.isLoading && vm.comments.isEmpty {
                    Section { ProgressView().frame(maxWidth: .infinity) }
                } else if vm.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await vm.refresh()
            }

            if auth.isLoggedIn {
                CommentInputBar(
                    text: $draft,
                    isSending: vm.isSending,
                    isFocused: $isInputFocused
                ) {
                    let text = draft.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    guard !text.isEmpty else { return }
                    Task {
                        try? await vm.send(text: text)
                        draft = ""
                    }
                }
            }
        }
        .task {
            if vm.comments.isEmpty { await vm.refresh() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .safeAreaInset(edge: .bottom) {
            if isInputFocused {
                HStack {
                    Spacer()
                    Button("Zatvori tastaturu") { isInputFocused = false }                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.thinMaterial)
            }
        }
    }
}
