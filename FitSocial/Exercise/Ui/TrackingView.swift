//
//  TrackingView.swift
//  FitSocial
//
//  Created by Dragan Kos on 2. 9. 2025..
//

import CoreLocation
import MapKit
import Observation
import SwiftData
import SwiftUI

struct TrackingViewParam {
    let activityType: ActivityType
    let isTracking: Bool
    let coordinates: [CLLocationCoordinate2D]
    let currentLocation: CLLocation?
    let distance: Double
    let duration: TimeInterval
    let speed: Double?
    let steps: Int?

    let onResume: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    let onDismiss: () -> Void
}

struct LiveTrackingView: View {
    @Environment(LocationManager.self) var locationManager
    @State private var vm: TrackingViewModel
    let startNewSession: Bool
    let onDismiss: () -> Void

    init(
        container: ModelContainer,
        selectedActivity: ActivityType,
        startNewSession: Bool,
        onDismiss: @escaping () -> Void,
        showingPermissionView: Bool = false
    ) {
        self.vm = TrackingViewModel(modelContainer: container, selectedActivity: selectedActivity)
        self.startNewSession = startNewSession
        self.onDismiss = onDismiss
        self.showingPermissionView = showingPermissionView
    }
    @State private var showingPermissionView = false

    var body: some View {
        VStack {
            if showingPermissionView {
                PermissionFlowView(
                    locationManager: locationManager,
                    healtStoreManager: vm.stepCounterManager,
                    selectedActivity: vm.selectedActivity,
                    onPermissionsGranted: {
                        showingPermissionView = false
                        // Počni praćenje nakon što su dozvole odobrene
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            locationManager.startTracking(for: vm.selectedActivity)
                            showingPermissionView = false
                        }
                    },
                    onDismiss: onDismiss
                )
            } else {
                TrackingView(
                    param: TrackingViewParam(
                        activityType: startNewSession ? vm.selectedActivity : locationManager.selectedActivity,
                        isTracking: locationManager.isTracking,
                        coordinates: locationManager.routeCoordinates,
                        currentLocation: locationManager.location,
                        distance: locationManager.distance,
                        duration: locationManager.duration,
                        speed: locationManager.speed,
                        steps: vm.steps,
                        onResume: { locationManager.resumeTracking() },
                        onPause: { locationManager.pauseTracking() },
                        onStop: { vm.onStop(locationManager: locationManager) },
                        onDismiss: onDismiss
                    )
                )
            }
        }.onAppear {
            vm.stepCounterManager.checkStepCountAuthorization()
            startActivityFlow()
        }
    }

    private func startActivityFlow() {
        let type = startNewSession ? vm.selectedActivity : locationManager.selectedActivity
        
        if type == .walking {
            switch vm.stepCounterManager.authorizationStatus {
            case .notDetermined, .sharingDenied:
                showingPermissionView = true
                return
            case .sharingAuthorized:
                break
            @unknown default:
                showingPermissionView = true
                return
            }
        }
        // Proveravamo dozvole tek kada korisnik želi pokrenuti praćenje
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            // Imamo sve potrebne dozvole, možemo odmah početi
            if !locationManager.isTracking {
                locationManager.startTracking(for: vm.selectedActivity)
            }
            
            if type == .walking, let from = locationManager.startTime  {
                vm.startTrackingSteps(from: from)
            }

            showingPermissionView = false
        case .authorizedWhenInUse:
            // Imamo osnovnu dozvolu, ali trebamo "Always" za pozadinsko praćenje
            showingPermissionView = true
        case .notDetermined, .denied, .restricted:
            // Trebamo da tražimo dozvole
            showingPermissionView = true
        @unknown default:
            showingPermissionView = true
        }
    }
}

struct TrackingView: View {
    let param: TrackingViewParam

    @State private var isPaused = false
    @State private var showingStopAlert = false

    var body: some View {
        VStack(spacing: 0) {
            RouteMapView(
                coordinates: param.coordinates,
                currentLocation: param.currentLocation,
                isTracking: param.isTracking
            )

            // Stats and Controls Overlay
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    // Activity Header
                    HStack {
                        Image(systemName: param.activityType.icon)
                            .font(.title2)
                            .foregroundColor(param.activityType.color)

                        Text(param.activityType.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Spacer()

                        if param.isTracking {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isPaused ? .orange : .green)
                                    .frame(width: 8, height: 8)

                                Text(isPaused ? "Pauzirano" : "Aktivno")
                                    .font(.caption)
                                    .foregroundColor(
                                        isPaused ? .orange : .green
                                    )
                            }
                        }
                    }

                    // Stats
                    StatsView(
                        distance: param.distance,
                        duration: param.duration,
                        speed: param.speed,
                        steps: param.steps,
                        activityType: param.activityType
                    )

                    // Controls
                    HStack(spacing: 16) {
                        if param.isTracking {
                            Button("Završi") {
                                showingStopAlert = true
                            }
                            .buttonStyle(PrimaryButtonStyle(color: .red))
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 34)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .alert("Završi aktivnost?", isPresented: $showingStopAlert) {
            Button("Završi", role: .destructive) {
                param.onStop()
                isPaused = false
            }
            Button("Otkaži", role: .cancel) {}
        } message: {
            Text("Da li ste sigurni da želite da završite ovu aktivnost?")
        }

    }
}

struct PermissionFlowView: View {
    @Bindable var locationManager: LocationManager
    @Bindable var healtStoreManager: StepCounterManager
    let selectedActivity: ActivityType
    let onPermissionsGranted: () -> Void
    let onDismiss: () -> Void

    @State private var currentStep = 0
    @State private var showingSettingsAlert = false

    private var totalSteps: Int {
        var count = 0
        if selectedActivity == .walking{
            switch healtStoreManager.authorizationStatus {
            case .sharingAuthorized:
                count = 0
            default:
                count = 1
            }
        }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            count = count + 2
        // When In Use + Always
        case .authorizedWhenInUse:
            count = count + 1  // Samo Always
        case .denied, .restricted:
            count = count + 1  // Settings redirect
        case .authorizedAlways:
            return 0
        @unknown default:
            count = count + 2
        }
        return count
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: selectedActivity.icon)
                        .font(.system(size: 80))
                        .foregroundColor(selectedActivity.color)

                    Text(selectedActivity.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)

                // Permission Cards
                VStack(spacing: 24) {
                    if selectedActivity == .walking
                        && healtStoreManager.authorizationStatus
                            == .notDetermined
                    {
                        PermissionStepCard(
                            icon: "figure.walk.triangle",
                            title: "Pristup brojacu koraka",
                            description:
                                "Potreban je pristup fitnes podacima da bismo mogli prikazati broj koraka koje napravite.",
                            buttonText: "Dozvoli pristup",
                            buttonColor: selectedActivity.color,
                            backgroundColor: .white.opacity(0.2),
                            stepNumber: 1,
                            totalSteps: totalSteps
                        ) {
                            healtStoreManager
                                .requestStepCountPermission()
                        }
                    } else if selectedActivity == .walking
                        && healtStoreManager.authorizationStatus
                            == .sharingDenied
                    {
                        PermissionStepCard(
                            icon: "figure.walk.triangle",
                            title: "Pristup brojacu koraka",
                            description:
                                "Da biste pratili svoju aktivnost, potrebno je da dozvolite pristup brojacu koraka u Podešavanjima.",
                            buttonText: "Otvori Podešavanja",
                            buttonColor: selectedActivity.color,
                            backgroundColor: .white.opacity(0.2)
                        ) {
                            if let settingsUrl = URL(
                                string: UIApplication.openSettingsURLString
                            ) {
                                UIApplication.shared.open(settingsUrl)
                            }
                            showingSettingsAlert = true
                        }

                    } else if locationManager.authorizationStatus == .denied
                        || locationManager.authorizationStatus
                            == .restricted
                    {
                        // Settings redirect
                        PermissionStepCard(
                            icon: "location.slash",
                            title: "Pristup lokaciji je odbačen",
                            description:
                                "Da biste pratili svoju aktivnost, potrebno je da dozvolite pristup lokaciji u Podešavanjima.",
                            buttonText: "Otvori Podešavanja",
                            buttonColor: selectedActivity.color,
                            backgroundColor: .white.opacity(0.2)
                        ) {
                            if let settingsUrl = URL(
                                string: UIApplication.openSettingsURLString
                            ) {
                                UIApplication.shared.open(settingsUrl)
                            }
                            showingSettingsAlert = true
                        }
                    } else if locationManager.authorizationStatus
                        == .notDetermined
                    {
                        // Step 1: When In Use Permission
                        PermissionStepCard(
                            icon: "location.circle",
                            title: "Pristup lokaciji",
                            description:
                                "Potreban je pristup vašoj lokaciji da bismo mogli pratiti vašu aktivnost.",
                            buttonText: "Dozvoli pristup",
                            buttonColor: selectedActivity.color,
                            backgroundColor: .white.opacity(0.2),
                            stepNumber: 1,
                            totalSteps: totalSteps
                        ) {
                            locationManager.requestLocationPermission()
                        }

                        if locationManager.authorizationStatus
                            == .authorizedWhenInUse
                        {
                            // Step 2: Always Permission
                            PermissionStepCard(
                                icon: "location.fill.viewfinder",
                                title: "Praćenje u pozadini",
                                description:
                                    "Da bi praćenje radilo i kada zatvorite aplikaciju, izaberite 'Uvek' u sledećem dijalogu.",
                                buttonText: "Omogući pozadinsko praćenje",
                                buttonColor: selectedActivity.color,
                                backgroundColor: .white.opacity(0.2),
                                stepNumber: 2,
                                totalSteps: totalSteps
                            ) {
                                locationManager.requestLocationPermission()
                            }
                        }
                    } else if locationManager.authorizationStatus
                        == .authorizedWhenInUse
                    {
                        // Samo Always Permission
                        PermissionStepCard(
                            icon: "location.fill.viewfinder",
                            title: "Praćenje u pozadini",
                            description:
                                "Za najbolje iskustvo, izaberite 'Uvek' da bi praćenje radilo i kada zatvorite aplikaciju.",
                            buttonText: "Omogući pozadinsko praćenje",
                            buttonColor: selectedActivity.color,
                            backgroundColor: .white.opacity(0.2)
                        ) {
                            locationManager.requestLocationPermission()
                        }
                    }
                }

                Spacer()

                // Skip button (samo za Always permission)
                if locationManager.authorizationStatus
                    == .authorizedWhenInUse
                {
                    Button("Preskoči (ograničeno praćenje)") {
                        onPermissionsGranted()
                    }
                    .font(.subheadline)
                    .underline()
                }
            }
            .padding(.horizontal, 24)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .authorizedAlways {
                onPermissionsGranted()
            }
        }
        .alert("Podešavanja", isPresented: $showingSettingsAlert) {
            Button("U redu") {
                onDismiss()
            }
        } message: {
            Text(
                "Kada odobrite dozvole u Podešavanjima, vratite se u aplikaciju i pokušajte ponovo."
            )
        }
    }
}

struct PermissionStepCard: View {
    let icon: String
    let title: String
    let description: String
    let buttonText: String
    let buttonColor: Color
    let backgroundColor: Color
    var stepNumber: Int? = nil
    var totalSteps: Int? = nil
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Step indicator
            if let stepNumber = stepNumber, let totalSteps = totalSteps {
                HStack {
                    Text("Korak \(stepNumber) od \(totalSteps)")
                        .font(.caption)
                        .textCase(.uppercase)

                    Spacer()
                }
            }

            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(buttonColor)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                Button(buttonText) {
                    action()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(buttonColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
        )
    }
}
