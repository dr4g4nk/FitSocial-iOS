//
//  ExerciseListViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
class ExerciseListViewModel {
    private(set) var exercises: [Exercise] = []

    private let dataStore: ExerciseLocalStore

    init(modelContainer: ModelContainer) {
        self.dataStore = ExerciseLocalStore(modelContainer: modelContainer)
    }

    var isLoading = false
    private(set) var reachedEnd = false
    private var page: Int = 0
    private let pageSize = 20
    private(set) var errorMessage: String?

    func refresh() {
        guard !isLoading else { return }

        isLoading = true
        reachedEnd = false
        page = 0
        Task {
            do {
                let data = try await dataStore.fetchPaginated(
                    offset: page,
                    limit: pageSize,
                    sortBy: [SortDescriptor(\.startTime, order: .reverse)],
                    transform: {e in e}
                )

                if pageSize > data.count {
                    reachedEnd = true
                }
                exercises = data
                page = page + 1
            } catch {
                errorMessage = "Greska, pokusajte ponovo."
            }

            isLoading = false
        }
    }

    func loadMore() {
        guard !isLoading, !reachedEnd else { return }

        isLoading = true
        Task {
            do {
                let data: [Exercise] = try await dataStore.fetchPaginated(
                    offset: page,
                    limit: pageSize,
                    sortBy: [SortDescriptor(\.startTime, order: .reverse)],
                    transform: {e in e}
                )

                if pageSize > data.count {
                    reachedEnd = true
                }

                exercises.append(contentsOf: data)
                page = page + 1

            } catch {
                errorMessage = "Greska, pokusajte ponovo."
            }
            isLoading = false
        }
    }

    func onDelete(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let exercise = exercises[index]

                do {
                    try await dataStore.delete(exercise)
                    exercises.remove(at: index)
                } catch {
                    errorMessage = "Greska pri brisanju"
                }
            }
        }
    }
}
