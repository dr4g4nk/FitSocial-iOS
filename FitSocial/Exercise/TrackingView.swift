import CoreLocation
import MapKit
import Observation
import SwiftUI

struct TrackingView: View {
    @Bindable var locationManager: LocationManager
    let activityType: ActivityType
    let onDismiss: () -> Void

    @State private var isPaused = false
    @State private var showingStopAlert = false

    var body: some View {
        VStack(spacing: 0) {
            RouteMapView(lm: locationManager)
                .ignoresSafeArea()
                .clipped()

            // Stats and Controls Overlay
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    // Activity Header
                    HStack {
                        Image(systemName: activityType.icon)
                            .font(.title2)
                            .foregroundColor(activityType.color)

                        Text(activityType.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Spacer()

                        if locationManager.isTracking {
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
                        distance: locationManager.distance,
                        duration: locationManager.duration,
                        speed: locationManager.speed,
                        activityType: activityType
                    )

                    // Controls
                    HStack(spacing: 16) {
                        if locationManager.isTracking {
                            Button(isPaused ? "Nastavi" : "Pauziraj") {
                                if isPaused {
                                    locationManager.resumeTracking()
                                    isPaused = false
                                } else {
                                    locationManager.pauseTracking()
                                    isPaused = true
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle(backgroundColor: activityType.color, color: .white))

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
                locationManager.stopTracking()
                isPaused = false
            }
            Button("Otkaži", role: .cancel) {}
        } message: {
            Text("Da li ste sigurni da želite da završite ovu aktivnost?")
        }

    }
}