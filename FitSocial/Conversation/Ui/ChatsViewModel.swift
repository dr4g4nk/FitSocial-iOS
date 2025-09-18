//
//  ChatsViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 27. 8. 2025..
//

import Observation
import SwiftUI

@MainActor
@Observable
final class ChatsViewModel {
    private let repo: any ChatRepository

    // UI state
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var items: [Chat] = []
    var searchText: String = ""

    var showUsersForNewChat = false

    private(set) var reachedEnd = false

    private var searchTask: Task<Void, Never>? = nil

    init(repo: any ChatRepository) {
        self.repo = repo
        
        Task{
            do{
                let data = try await repo.getLocalLatest(size: size)
                if items.isEmpty {
                    items = data
                }
            } catch{
                print(error.localizedDescription)
            }
        }
    }

    private var loadTask: Task<Void, Never>? = nil

    func loadInitial() {
        guard items.isEmpty else { return }
        refresh()
    }

    private var page: Int = 0
    private var size: Int = 30
    private var sort: String? = "lastMessageTime,Desc"

    private var lastAction: Action?
    private var fetchTask: Task<Void, Never>? = nil

    public func loadNextPageIfNeeded(currentItemId: Int?) {
        guard items.last?.id == currentItemId else { return }
        lastAction = .loadMore
        loadNextPage { [self] array in
            items.append(contentsOf: array)
        }
    }

    private func checkReachedEnd(count: Int) {
        if count < size { reachedEnd = true }
    }

    private func loadNextPage(onDataLoaded: @escaping ([Chat]) -> Void) {
        if fetchTask != nil { return }
        fetchTask = Task {
            guard !reachedEnd else { return }
            guard !isLoading else { return }
            isLoading = true
            defer {
                isLoading = false
                fetchTask = nil
            }

            do {
                var data: Page<Chat>
                if searchText.isEmpty {
                    data = try await repo.getAll(
                        page: page,
                        size: size,
                        sort: sort
                    )
                } else {
                    data = try await repo.getAllFiltered(
                        page: page,
                        size: size,
                        sort: sort,
                        filterValue: searchText
                    )
                }
                page = data.number + 1
                onDataLoaded(data.content)
                checkReachedEnd(count: data.content.count)
            } catch {
                self.errorMessage =
                    "Greška pri učitavanju: \(error.localizedDescription)"
            }
        }
    }

    func refresh() {
        lastAction = .refresh
        page = 0
        loadNextPage(onDataLoaded: { [self] array in
            items = array
        })
    }

    public func retry() {
        errorMessage = nil

        switch lastAction {
        case .refresh:
            refresh()
        case .loadMore:
            loadNextPage { [self] array in
                items.append(contentsOf: array)
            }
        case .none: break
        }
    }

    func onSearchTextChanged(_ newValue: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            // Debounce ~300ms radi HIG fluidnosti i performansi
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let self else { return }
            fetchTask?.cancel()
            fetchTask = nil
            isLoading = false
            reachedEnd = false
            refresh()
        }
    }

    private func normalizedQuery(_ q: String) -> String? {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func create(users: [User], onSuccess: @escaping (Chat) -> Void) {
        Task {
            let data = try await repo.create(
                chat: .init(
                    id: -1,
                    content: "",
                    userIds: users.map({ usr in
                        usr.id
                    })
                ),
                attachment: nil
            ) { sent, total, fraction in }

            if data.success {
                let chat = data.result!.copy({ _ in })
                items.insert(chat, at: 0)
                onSuccess(chat)
            } else {
                errorMessage = data.message
            }
        }
    }

    func onDelete(chat: Chat) {
        Task {
            try await repo.delete(chat.id)
            items.removeAll { c in
                c.id == chat.id
            }
        }
    }
}
