//
//  ChatUserListViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 30. 8. 2025..
//

import Foundation
import Observation

@MainActor
@Observable
class ChatUserListViewModel {

    private let userRepo: any UserRepository

    init(userRepo: any UserRepository) {
        self.userRepo = userRepo
    }

    private var page = 0
    private var size = 20
    private var isLoading = false
    private(set) var errorMessage: String? = nil
    private(set) var reachedEnd = false

    var users: [User] = []

    private(set) var selectedUsers: [User] = []

    var searchValue: String = ""
    
    private var oldSearchValue: String = ""

    private var loadTask: Task<Void, Never>? = nil
    func loadMore() {
        guard !reachedEnd else { return }
        guard !isLoading else { return }
        loadTask = Task {
            do {
                let data = try await userRepo.getAllFiltered(
                    page: page,
                    size: size,
                    sort: nil,
                    filterValue: searchValue
                )
                if oldSearchValue == searchValue {
                    users.append(contentsOf: data.content)
                }
                else {
                    oldSearchValue = searchValue
                    users = data.content
                }
                reachedEnd = data.content.count < size
            } catch {
                errorMessage = "Desila se grska, probajte ponovo kasnije"
            }
        }
    }

    func onSearchChange() {
        loadTask?.cancel()
        isLoading = false
        reachedEnd = false
        page = 0
        loadMore()
    }

    func onSelectUser(user: User) {
        if selectedUsers.contains(user) {
            selectedUsers.removeAll { usr in
                usr.id == user.id
            }
        } else {
            selectedUsers.append(user)
        }
    }
    
    func clear(){
        searchValue = ""
        selectedUsers = []
    }

}
