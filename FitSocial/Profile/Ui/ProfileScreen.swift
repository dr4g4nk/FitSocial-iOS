//
//  ProfileScreen.swift
//  FitSocial
//
//  Created by Dragan Kos on 19. 8. 2025..
//

import SwiftUI

@MainActor
struct ProfileScreen: View {
    private let container: ProfileContainer
    @Environment(AuthManager.self) private var auth: AuthManager
    
    let onEditPost: (Post) -> Void

    init(container: ProfileContainer, onEditPost: @escaping (Post) -> Void) {
        self.container = container
        self.onEditPost = onEditPost
    }

    var body: some View {
        if let user = auth.user {
           ProfileGateView(container: container, user: user, onEditPost: onEditPost)
        }
    }
}

struct ProfileGateView: View {
    private let container: ProfileContainer
    
    private struct ActivePost: Identifiable{
        var id: Int
    }
    
    @State private var activePost: ActivePost? = nil
    @State private var profileViewModel: ProfileViewModel
    @State private var commentsViewModel: CommentsViewModel? = nil
    
    let onEditPost: (Post) -> Void
    
    init(container: ProfileContainer, user: User, onEditPost: @escaping (Post) -> Void) {
        self.container = container
        self.profileViewModel = container.makeProfileViewModel(user: user)
        self.onEditPost = onEditPost
    }
    
    var body: some View{
        ProfileView(
            vm: profileViewModel,
            onComment: {  postId in
                activePost = ActivePost(id: postId)
            },
            onEditPost: { post in
                onEditPost(post)
            }
        ).sheet(
            item: $activePost,
            onDismiss: {
                activePost = nil
            }
        ) { post in
            CommentsView(vm: container.makeCommentViewModel(postId: post.id))
        }
    }
}
