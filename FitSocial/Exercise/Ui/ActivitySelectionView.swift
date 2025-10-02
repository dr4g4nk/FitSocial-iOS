//
//  ActivitySelectionView.swift
//  FitSocial
//
//  Created by Dragan Kos on 2. 9. 2025..
//

import CoreLocation
import MapKit
import Observation
import SwiftUI
import SwiftData

struct ActivitySelectionView: View {
    private let container: ModelContainer
    
    init(container: ModelContainer) {
        self.container = container
    }

    @State var hasActiveSession = false
    @State var selectedActivity: ActivityType = .walking
    
    @State private var currentActivity: ActivityType?
    @State var showingTrackingView = false
    @State var startNewSession = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGroupedBackground),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Text("Odaberi aktivnost")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(
                                "Pratite svoje aktivnosti gde god da idete"
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        ScrollView {
                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(.flexible()),
                                    count: 1
                                ),
                                spacing: 16
                            ) {
                                ForEach(ActivityType.allCases, id: \.self) {
                                    activity in
                                    ActivitySelectionCard(
                                        activity: activity,
                                        isSelected: selectedActivity
                                            == activity
                                    ) {
                                        selectedActivity = activity
                                    }
                                }
                            }
                            .padding()

                        }

                        Spacer()
                        // Continue to Active Session if tracking
                        if hasActiveSession {
                            VStack(spacing: 16) {
                                HStack {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 12, height: 12)

                                    Text("Aktivna sesija u toku")
                                        .font(.headline)
                                        .foregroundColor(Color(.systemGreen))

                                    Spacer()
                                }

                                Button("Nastavi aktivnu sesiju") {
                                    startNewSession = false
                                    showingTrackingView = true
                                }
                                .buttonStyle(
                                    PrimaryButtonStyle(color: .green)
                                )
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                .green.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }

                        // Start Button
                        Button(
                            "Počni "
                                + selectedActivity.rawValue.lowercased()
                        ) {
                            startNewSession = true
                            showingTrackingView = true
                        }
                        .buttonStyle(
                            PrimaryButtonStyle(
                                color: selectedActivity.color
                            )
                        )
                        .padding(.bottom, 24)
                    }
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showingTrackingView) {
                LiveTrackingView(
                    container: container,
                    selectedActivity: startNewSession ? selectedActivity : (currentActivity ?? selectedActivity),
                    startNewSession: startNewSession,
                    onDismiss: { showingTrackingView = false }
                )
            }
        }
        .onAppear{
            let sessionData = UserDefaults.standard.dictionary(
                forKey: "TrackingSession"
            )
            hasActiveSession = sessionData?["isTracking"] as? Bool ?? false
            currentActivity = .init(rawValue: sessionData?["type"] as? String ?? "")
        }
        .toolbar(!showingTrackingView ? .visible : .hidden, for: .tabBar)
    }
}

struct ActivitySelectionCard: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(activity.backgroundGradient)
                        .frame(width: 60, height: 60)

                    Image(systemName: activity.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(getActivityDescription(activity))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(
                    systemName: isSelected ? "checkmark.circle.fill" : "circle"
                )
                .font(.title2)
                .foregroundColor(isSelected ? activity.color : .secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? activity.color : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getActivityDescription(_ activity: ActivityType) -> String {
        switch activity {
        case .walking:
            return "Lagana šetnja ili hodanje"
        case .running:
            return "Trčanje ili džoging"
        case .cycling:
            return "Vožnja biciklom"
        }
    }
}
