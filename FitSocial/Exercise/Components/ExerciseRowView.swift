//
//  ExerciseRowView.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import SwiftUI

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack {
            // Icon za tip vježbe
            Image(
                systemName: exercise.activityType?.icon ?? "figure.mixed.cardio"
            )
            .frame(width: 50, height: 50)
            .background((exercise.activityType?.color ?? Color(.systemOrange)).opacity(0.1))
            .foregroundColor(exercise.activityType?.color ?? Color(.systemOrange))
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // Tip vježbe
                Text(exercise.type)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Datum i vrijeme
                Text(formatDate(exercise.startTime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Dodatne informacije
                HStack(spacing: 16) {
                    if let duration = exerciseDuration {
                        Label(duration, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label(
                        formatDistance(exercise.distance),
                        systemImage: "location"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let steps = exercise.steps {
                        Label("\(steps)", systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var exerciseDuration: String? {
        guard let endTime = exercise.endTime else { return nil }
        let duration = endTime.timeIntervalSince(exercise.startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "hr_HR")
        return formatter.string(from: date)
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
}
