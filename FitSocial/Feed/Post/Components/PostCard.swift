//
//  PostCardImagesOnly.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import SwiftUI

struct PostCard: View {
    @Environment(AuthManager.self) private var auth: AuthManager
    @Binding var post: Post
    @State private var pageIndex = 0

    @State private var isMostlyVisible = false
    @State private var selectedMediaIndex = 0

    var onShare: () -> Void
    var onComment: () -> Void
    var onLikeToggle: () -> Void
    var onViewProfile: (User) -> Void
    var onOpenMenu: (Post) -> Void

    let onPlay: (String) -> Void
    let onPause: (String) -> Void
    let onToggleMute: (String, Bool) -> Void

    let onVisibleChange: (String, Double) -> Void
    let onVideoAppear: (String, URL, VideoPlayerProxy) -> Void
    let onVideoDisappear: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            mediaPager
            if !post.content.isEmpty {
                Spacer()
                ExpandableText(post.content).font(.body)
            }
            PostActionsView(
                isLiked: post.isLiked ?? false,
                onShare: onShare,
                onComment: onComment,
                onLikeToggle: onLikeToggle
            )
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onLikeToggle()
                    }
                }
        )
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16).fill(
                Color(.secondarySystemBackground)
            )
        )
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 8) {
            if let url = post.author.avatarUrl, !url.isEmpty {
                AvatarImage(
                    url: URL(string: url),
                    width: 40,
                    height: 40
                )
            } else {
                Circle().fill(.gray.opacity(0.3)).frame(width: 40, height: 40)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(post.authorName).font(.headline)
                Text(post.createdAt, style: .relative)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if auth.isLoggedIn {
                Button {
                    onOpenMenu(post)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Više opcija")
            }
        }.onTapGesture {
            onViewProfile(post.author)
        }
    }

    @ViewBuilder
    private var mediaPager: some View {
        if !post.media.isEmpty {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $selectedMediaIndex) {
                    ForEach(Array(post.media.enumerated()), id: \.offset) {
                        idx,
                        m in
                        MediaCellView(
                            media: m,
                            onPlay: onPlay,
                            onPause: onPause,
                            onToggleMute: onToggleMute,
                            onVisibleChange: onVisibleChange,
                            onVideoAppear: onVideoAppear,
                            onVideoDisappear: onVideoDisappear
                        )
                        .tag(idx)
                        .frame(height: 420)
                        .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 420)
            }
        }
    }
}

struct PostActionsView: View {
    var isLiked: Bool
    var onShare: () -> Void
    var onComment: () -> Void
    var onLikeToggle: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button {
                onLikeToggle()
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? Color(.systemRed) : .primary)
                    .imageScale(.large)
            }
            .accessibilityLabel(isLiked ? "Liked" : "Like")

            Spacer()

            Button {
                onComment()
            } label: {
                Image(systemName: "bubble.right")
                    .foregroundColor(.primary)
                    .imageScale(.large)
            }
            .accessibilityLabel("Comment")

            Spacer()

            Button {
                onShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.primary)
                    .imageScale(.large)
            }
            .accessibilityLabel("Share")

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
