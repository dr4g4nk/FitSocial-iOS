//
//  FeedViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 14. 8. 2025..
//

import Foundation
import Observation

@MainActor
@Observable
final class FeedViewModel: PostsViewModel {
    override func getPosts(page: Int, size: Int) async throws -> Page<Post> {
        return try await repo.getAll(page: page, size: size)
    }
}
