//
//  PostsViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 19. 8. 2025..
//

import Foundation
import Observation

@MainActor
@Observable
public class PostsViewModel {
    let repo: any PostRepository

    // UI state
    var posts: [Post] = []
    var isLoading = false
    private(set) var reachedEnd = false
    var errorMessage: String?
    var showComments: Bool = false
    var showActionMenu: Bool = false
    var showDeleteAlert = false
    var selectedPost: Post? = nil

    // paginacija
    fileprivate var nextPage: Int? = 0
    fileprivate let pageSize = 20

    init(repo: any PostRepository) {
        self.repo = repo
    }

    
    private var lastFailedAction: Action?

    func getPosts(page: Int, size: Int) async throws -> Page<Post> {
        fatalError("Subclasses must override")
    }

    public func loadFirstPage() {
        if fetchTask != nil { return }
        fetchTask = Task {
            guard !isLoading else { return }
            isLoading = true
            errorMessage = nil
            defer {
                isLoading = false
                fetchTask = nil
            }

            do {
                let page = try await getPosts(page: 0, size: pageSize)
                posts = page.content
                nextPage = page.number + 1
            } catch {
                self.errorMessage = error.localizedDescription
                lastFailedAction = .refresh
            }
        }
    }

    private var fetchTask: Task<Void, Never>? = nil

    public func loadNextPageIfNeeded(currentItemId: Int?) {
        guard posts.last?.id == currentItemId else { return }
        loadNextPage()
    }

    private func loadNextPage() {
        if fetchTask != nil { return }
        fetchTask = Task {
            guard !reachedEnd else { return }
            guard let next = nextPage, !isLoading else { return }
            isLoading = true
            defer {
                isLoading = false
                fetchTask = nil
            }

            do {
                let page = try await getPosts(page: next, size: pageSize)
                posts.append(contentsOf: page.content)
                nextPage = page.number + 1
                if page.content.count < pageSize { reachedEnd = true }
            } catch {
                self.errorMessage = error.localizedDescription
                lastFailedAction = .loadMore
            }
        }
    }

    public func retry() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch lastFailedAction {
        case .refresh:
            refresh()
        case .loadMore:
            loadNextPage()
        case .none: break
        }
    }

    public func refresh() {
        loadFirstPage()
    }

    public func toggleLike(postId: Int) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            return
        }

        posts[index].isLiked?.toggle()

        Task {
            do {
                try await repo.likePost(postId: postId)
            } catch {
                // Ako API padne, revertuj lokalni state
                posts[index].isLiked?.toggle()
            }
        }
    }

    private var deleteTask: Task<Void, Never>? = nil
    public func deletePost(postId: Int) {
        if deleteTask != nil { return }

        deleteTask = Task {
            do {
                try await repo.delete(postId)

                posts.removeAll { post in
                    post.id == postId
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            deleteTask = nil
        }
    }

    private let coordinator = PlaybackCoordinator(maxPreloads: 4)

    private struct Candidate {
        weak var proxy: VideoPlayerProxy?
        var url: URL
        var fraction: CGFloat
    }

    private var items: [String: Candidate] = [:]  // id -> candidate
    private(set) var activeId: String?
    private var reevaluateWork: DispatchWorkItem?

    // API iz View-a
    public func register(id: String, url: URL, proxy: VideoPlayerProxy) {
        items[id] = Candidate(proxy: proxy, url: url, fraction: 0)
        coordinator.prepare(url)
    }

    public func unregister(id: String) {
        if activeId == id, let proxy = items[id]?.proxy {
            coordinator.detach(from: proxy)
            activeId = nil
            coordinator.pause()
        }
        items.removeValue(forKey: id)
    }

    public func visibleChanged(id: String, fraction: CGFloat) {
        guard var c = items[id] else { return }
        c.fraction = fraction
        items[id] = c
        scheduleReevaluate()
    }

    public func userTappedPlay(id: String) {
        guard let c = items[id], let proxy = c.proxy else { return }
        activate(id: id, candidate: c, proxy: proxy)
        coordinator.play()
    }

    public func userTappedPause() { coordinator.pause() }

    public func setMuted(_ muted: Bool) { coordinator.setMuted(muted) }
    public var isMuted: Bool { coordinator.isMuted }

    // MARK: - Selection

    private func scheduleReevaluate() {
        reevaluateWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reevaluate() }
        reevaluateWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: work)  // debounce ~180ms
    }

    private func reevaluate() {
        guard
            let best = items.filter({ (key: String, value: Candidate) in
                value.fraction > 0
            }).max(by: { $0.value.fraction < $1.value.fraction })
        else {
            if activeId != nil {
                coordinator.pause()
                activeId = nil
            }
            return
        }
        if let activeId, activeId == best.key { return }

        let currentFrac = activeId.flatMap { items[$0]?.fraction } ?? 0
        // prebacuj tek ako je > 0.25 vidljiviji
        guard best.value.fraction - currentFrac > 0.25 else { return }

        if let proxy = best.value.proxy {
            activate(id: best.key, candidate: best.value, proxy: proxy)
            coordinator.play()
        }
    }

    private func activate(
        id: String,
        candidate: Candidate,
        proxy: VideoPlayerProxy
    ) {
        if let activeId, let oldProxy = items[activeId]?.proxy,
            oldProxy !== proxy
        {
            coordinator.detach(from: oldProxy)
        }
        coordinator.attach(to: proxy, url: candidate.url)
        activeId = id
    }
}
