//
//  FeedContainer.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation
import SwiftData

@MainActor
final class FeedContainer {
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
    func makeFeedViewModel() -> FeedViewModel {
        return FeedViewModel(repo: self.postRepo)
    }
    
    func makeCommentViewModel(postId: Int) -> CommentsViewModel {
        return CommentsViewModel(postId: postId, repo: self.commentRepo)
    }

    func makeProfileViewModel(user: User) -> ProfileViewModel {
        return ProfileViewModel(user: user, repo: postRepo)
    }
    
    func makeNewPostViewModel(post: Post? = nil) -> NewPostViewModel {
        if let post = post {
            return NewPostViewModel(mode: .edit(existing: post), repo: self.postRepo)
        }
        else{
            return NewPostViewModel(mode: .create, repo: self.postRepo)
        }
    }
}
