//
//  ProfileViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 19. 8. 2025..
//
import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel : PostsViewModel {
    var user: User

    init(user: User, repo: any PostRepository) {
        self.user = user
        super.init(repo: repo)
    }
    
    override func getPosts(page: Int, size: Int) async throws -> Page<Post> {
        return try await repo.getAllByUserId(userId: user.id, page: page, size: size)
    }
    
    override func getLocalPosts(size: Int) async throws -> [Post] {
        return try await repo.getLocalPost(userId: user.id, limit: size)
    }
}
