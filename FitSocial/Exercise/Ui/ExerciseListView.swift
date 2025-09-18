//
//  ExerciseListView.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import CoreLocation
import SwiftUI

struct ExerciseListView: View {
    @Bindable private var vm: ExerciseListViewModel

    init(vm: ExerciseListViewModel) {
        self.vm = vm
    }

    @State private var exercise: Exercise?
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if vm.exercises.isEmpty {
                        ContentUnavailableView("Još nemaš nijednu vježbu. Vrijeme je da kreneš sa svojom prvom aktivnošću! 💪", systemImage: "figure.run")
                    }
                    ForEach(vm.exercises) { exercise in
                        ExerciseRowView(exercise: exercise)
                            .onTapGesture {
                                self.exercise = exercise
                            }
                            .padding()
                    }.onDelete(perform: vm.onDelete)
                }
                .refreshable {
                    vm.refresh()
                }

                PagingTrigger(onVisible: {
                    vm.loadMore()
                })
            }
            .sheet(item: $exercise) { exercise in
                NavigationStack {
                    TrackingView(
                        param: TrackingViewParam(
                            activityType: exercise.activityType ?? .walking,
                            isTracking: false,
                            coordinates: exercise.routeCoordinates.map({ point in
                                point.coordinate
                            }),
                            currentLocation: nil,
                            distance: exercise.distance,
                            duration: exercise.endTime?.timeIntervalSince(
                                exercise.startTime
                            ) ?? Date.now.timeIntervalSince(exercise.startTime),
                            speed: nil,
                            steps: exercise.steps,
                            onResume: {},
                            onPause: {},
                            onStop: {},
                            onDismiss: {}
                        )
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(action: { self.exercise = nil }) {
                                Image(systemName: "xmark.circle")
                            }
                        }

                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}
