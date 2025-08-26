//
//  FeedView.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import SwiftUI

@MainActor
struct FeedView: View {
    @Bindable var vm: FeedViewModel
    @Environment(AuthManager.self) private var auth: AuthManager

    let onComment: (_ postId: Int) -> Void
    let onViewProfile: (User) -> Void
    let onEditPost: (Post) -> Void

    var body: some View {
        if vm.isLoading && vm.posts.isEmpty {
            ProgressView("Učitavanje…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = vm.errorMessage, vm.posts.isEmpty {
            VStack(spacing: 12) {
                Text("Greška").font(.headline)
                Text(err).font(.subheadline).multilineTextAlignment(.center)
                Button("Pokušaj ponovo") { Task { vm.refresh() } }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach($vm.posts) { $post in
                        PostCard(
                            post: $post,
                            onShare: {},
                            onComment: { onComment(post.id) },
                            onLikeToggle: { [postId = post.id] in
                                if auth.isLoggedIn {
                                    vm.toggleLike(postId: postId)
                                }
                            },
                            onViewProfile: onViewProfile,
                            onOpenMenu: { post in
                                if auth.isLoggedIn {
                                    vm.selectedPost = post
                                    vm.showActionMenu = true
                                }
                            },
                            onPlay: { id in vm.userTappedPlay(id: id) },
                            onPause: { id in vm.userTappedPause() },
                            onToggleMute: { id, mute in
                                vm.setMuted(mute)
                            },
                            onVisibleChange: { id, f in
                                vm.visibleChanged(id: id, fraction: f)
                            },
                            onVideoAppear: { id, url, proxy in
                                vm.register(id: id, url: url, proxy: proxy)
                            },
                            onVideoDisappear: { id in
                                vm.unregister(id: id)
                            }
                        ).confirmationDialog(
                            "Akcije",
                            isPresented: $vm.showActionMenu,
                            titleVisibility: .automatic
                        ) {
                            if vm.selectedPost?.author.id == auth.user?.id {
                                Button("Izmijeni objavu", systemImage: "pencil")
                                { onEditPost(vm.selectedPost!)  }
                                Button(
                                    "Obriši objavu",
                                    systemImage: "trash",
                                    role: .destructive
                                ) { vm.deletePost(postId: vm.selectedPost?.id ?? -1)  }
                            }
                            Button(
                                "Prijavi objavu",
                                systemImage: "exclamationmark.bubble"
                            ) { /* ... */  }
                        }
                    }
                    if vm.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        if !vm.reachedEnd {
                            Color.clear
                                .frame(height: 1)
                                .task {
                                    vm.loadNextPageIfNeeded(
                                        currentItemId: vm.posts.last?.id
                                    )
                                }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: auth.isLoggedIn) { oldValue, newValue in
                if oldValue != newValue { vm.refresh() }
            }
            .refreshable { vm.refresh() }
            .overlay(alignment: .bottom) {
                if vm.errorMessage != nil && !vm.isLoading {
                    VStack(spacing: 12) {
                        Text("Došlo je do greške")
                            .font(.body)
                            .padding(.vertical, 6)
                        Button("Pokušaj ponovo") { Task { vm.retry() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.background.opacity(0.8))
                }
            }
        }
    }
}
