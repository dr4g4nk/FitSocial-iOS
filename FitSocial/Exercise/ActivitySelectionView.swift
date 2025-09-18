import CoreLocation
import MapKit
import Observation
import SwiftUI

struct ActivitySelectionView: View {
    @State private var locationManager = LocationManager()
    @State private var selectedActivity: ActivityType = .walking
    @State private var showingTrackingView = false
    @State private var showingPermissionAlert = false

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

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    selectedActivity.backgroundGradient
                                )

                            VStack(spacing: 8) {
                                Text("Fitnes Tracker")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)

                                Text(
                                    "Pratite svoje aktivnosti gde god da idete"
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 40)

                        // Permission Status
                        if locationManager.authorizationStatus == .notDetermined
                        {
                            PermissionCard(
                                icon: "location.circle",
                                title: "Potreban je pristup lokaciji",
                                description:
                                    "Da biste pratili svoje aktivnosti i u pozadini, potrebno je da dozvolite pristup vašoj lokaciji.",
                                buttonText: "Dozvoli pristup",
                                buttonColor: .blue
                            ) {
                                locationManager.requestLocationPermission()
                            }
                        } else if locationManager.authorizationStatus == .denied
                        {
                            PermissionCard(
                                icon: "location.slash",
                                title: "Pristup lokaciji je odbačen",
                                description:
                                    "Molimo idite u Podešavanja i dozvolite pristup lokaciji za ovu aplikaciju.",
                                buttonText: "Otvori Podešavanja",
                                buttonColor: .red
                            ) {
                                if let settingsUrl = URL(
                                    string: UIApplication.openSettingsURLString
                                ) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                        } else if locationManager.needsAlwaysPermission {
                            PermissionCard(
                                icon: "location.fill.viewfinder",
                                title: "Potrebno je dodatno odobrenje",
                                description:
                                    "Za praćenje u pozadini potrebno je da izaberete 'Uvek' za pristup lokaciji.",
                                buttonText: "Zatraži 'Uvek' dozvolu",
                                buttonColor: .orange
                            ) {
                                locationManager.requestLocationPermission()
                            }
                        } else {
                            // Activity Selection
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    Text("Izaberite aktivnost")
                                        .font(.title2)
                                        .fontWeight(.semibold)

                                    Text(
                                        "Aplikacija će pratiti vašu rutu i statistike"
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }

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

                                // Continue to Active Session if tracking
                                if locationManager.isTracking {
                                    Button("Nastavi aktivnu sesiju") {
                                        showingTrackingView = true
                                    }
                                    .buttonStyle(
                                        PrimaryButtonStyle(color: .green)
                                    )
                                }

                                // Start Button
                                Button(
                                    "Počni "
                                        + selectedActivity.rawValue.lowercased()
                                ) {
                                    if locationManager.authorizationStatus
                                        == .authorizedAlways
                                    {
                                        locationManager.startTracking()
                                        showingTrackingView = true
                                    } else {
                                        showingPermissionAlert = true
                                    }
                                }
                                .buttonStyle(
                                    PrimaryButtonStyle(
                                        color: selectedActivity.color
                                    )
                                )
                                .disabled(locationManager.isTracking)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(isPresented: $showingTrackingView) {
                TrackingView(
                    locationManager: locationManager,
                    activityType: selectedActivity,
                    onDismiss: {
                        showingTrackingView = false
                    }
                )
                .presentationDetents([.large])
                .navigationTitle(selectedActivity.rawValue)

            }
            .alert(
                "Dodatno odobrenje potrebno",
                isPresented: $showingPermissionAlert
            ) {
                Button("Podešavanja") {
                    if let settingsUrl = URL(
                        string: UIApplication.openSettingsURLString
                    ) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Otkaži", role: .cancel) {}
            } message: {
                Text(
                    "Za praćenje u pozadini potrebno je da u Podešavanjima izaberete 'Uvek' za pristup lokaciji."
                )
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [
                .alert, .badge, .sound,
            ]) { _, _ in }
        }
    }
}