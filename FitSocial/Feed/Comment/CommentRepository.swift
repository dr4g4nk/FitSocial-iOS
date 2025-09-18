//
//  CommentRepository.swift
//  FitSocial
//
//  Created by Dragan Kos on 15. 8. 2025..
//

import Foundation

protocol CommentRepository: Repository<Int, Comment, Comment, Comment> where Service: CommentApiService{
    
    func getAllByPostId(postId: Int, page: Int, size: Int, sort: String) async throws -> Page<Comment>
}


class CommentRepositoryImpl<Service: CommentApiService>: CommentRepository{
    var apiService: Service
    private let session: UserSession
    
    init(apiService: Service, session: UserSession) {
        self.apiService = apiService
        self.session = session
    }
    
    func getAllByPostId(postId: Int, page: Int, size: Int, sort: String) async throws -> Page<Comment> {
        return try await apiService.getByPostId(postId, page: page, size: size, sort: sort, extraQuery: []).result
    }
}
