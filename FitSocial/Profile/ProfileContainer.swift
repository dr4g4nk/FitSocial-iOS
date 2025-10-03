//
//  ProfileContainer.swift
//  FitSocial
//
//  Created by Dragan Kos on 19. 8. 2025..
//

import Foundation
import SwiftData


@MainActor
final class ProfileContainer {
    private let session: UserSession
    private let modelContainer: ModelContainer
    
    private let postApiService: any PostApiService
    private let postRepo: any PostRepository
    
    private let commentApiService: any CommentApiService
    private let commentRepo: any CommentRepository
    

    init(apiClient: APIClient, session: UserSession, modelContainer: ModelContainer) {
        self.session = session
        self.modelContainer = modelContainer
        let postApiService: PostApiServiceImpl = PostApiServiceImpl(api: apiClient, session: session)
        self.postApiService = postApiService
        
        let localStore: PostLocalStore = PostLocalStoreImpl(modelContainer: modelContainer, session: session)

        self.postRepo = PostRepositoryImpl(postApiService, sesson: session, localStore: localStore)
        
        let commentApiService = CommentApiServiceImpl(api: apiClient, session: session)
        self.commentApiService = commentApiService
        self.commentRepo = CommentRepositoryImpl(apiService: commentApiService, session: session)
    }

    // Factory za VM-ove / UseCase-ove
    func makeProfileViewModel(user: User) -> ProfileViewModel {
        ProfileViewModel(user: user, repo: self.postRepo)
    }
    
    func makeCommentViewModel(postId: Int) -> CommentsViewModel{
        CommentsViewModel(postId: postId, repo: self.commentRepo)
    }

    // Po potrebi i druge factory metode...
}
