import CoreLocation
import MapKit
import Observation
import SwiftUI

struct StatsView: View {
    let distance: Double
    let duration: TimeInterval
    let speed: Double
    let activityType: ActivityType

    var body: some View {
        HStack(spacing: 0) {
            StatCard(
                title: "Distanca",
                value: String(format: "%.2f km", distance / 1000),
                color: activityType.color
            )

            Divider()
                .frame(height: 40)

            StatCard(
                title: "Vreme",
                value: formatTime(duration),
                color: activityType.color
            )

            Divider()
                .frame(height: 40)

            StatCard(
                title: "Brzina",
                value: String(format: "%.1f km/h", speed * 3.6),
                color: activityType.color
            )
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}