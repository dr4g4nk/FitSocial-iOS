//
//  CommentViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 17. 8. 2025..
//

import Observation
import SwiftUI

@MainActor
@Observable
final class CommentsViewModel: ObservableObject {
     var comments: [Comment] = []
     var isLoading = false
     var isSending = false
     var canLoadMore = true
    
    let postId: Int
    private var page = 0
    private let pageSize = 20
    
    private let repo: any CommentRepository

    init(postId: Int, repo: any CommentRepository) {
        self.postId = postId
        self.repo = repo
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        page = 0
        do{
            let res = try await repo.getAllByPostId(postId: postId, page: page, size: pageSize, sort: "id,Desc")
            comments = res.content
            canLoadMore = res.number + 1 < res.totalPages
        } catch{
            
        }
    }

    func loadNextPageIfNeeded(current item: Comment?) async {
        guard let item, canLoadMore, !isLoading else { return }
        let thresholdIndex = comments.index(comments.endIndex, offsetBy: -5, limitedBy: comments.startIndex) ?? comments.startIndex
        if comments.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            await loadMore()
        }
    }

    private func loadMore() async {
        guard !isLoading, canLoadMore else { return }
        isLoading = true
        defer { isLoading = false }
        page += 1
        do{
            let res = try await repo.getAllByPostId(postId: postId, page: page, size: pageSize, sort: "id,Desc")
            let more = res.content
            comments.append(contentsOf: more)
            canLoadMore = res.number + 1 < res.totalPages
        } catch{}
    }

    func send(text: String) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }
        let new = Comment(
            id: 0,
            postId: postId,
            content: text,
        )
        let comment = try await repo.create(new)
        comments.insert(comment, at: 0)
    }
}
