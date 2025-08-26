//
//  SwiftUIView.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import SwiftUI

@MainActor
struct FeedScreen: View {
    private let container: FeedContainer
    
    let onComment: (_ postId: Int) -> Void
    let onViewProfile: (User) -> Void
    let onEditPost: (Post) -> Void
    
    @State private var feedViewModel: FeedViewModel
    @State private var commentsViewModel: CommentsViewModel? = nil
    @State private var feedPath = NavigationPath()

    init(container: FeedContainer, onComment: @escaping (_ postId: Int) -> Void, onViewProfile: @escaping (User) -> Void, onEditPost: @escaping (Post) -> Void) {
        self.container = container
        self.feedViewModel = container.makeFeedViewModel()
        self.onComment = onComment
        self.onViewProfile = onViewProfile
        self.onEditPost = onEditPost
    }

    var body: some View {
        FeedView(
            vm: feedViewModel,
            onComment: onComment,
            onViewProfile: onViewProfile,
            onEditPost: {post in onEditPost(post)}
        )
    }
}
