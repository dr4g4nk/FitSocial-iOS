//
//  Activity.swift
//  FitSocial
//
//  Created by Dragan Kos on 3. 9. 2025..
//

import Foundation
import MapKit
import SwiftData

@Model
final class Exercise: Identifiable, Hashable, @unchecked Sendable {
    @Attribute(.unique)
    var id: UUID
    var type: String
    var startTime: Date
    var endTime: Date?
    var steps: Int?
    var distance: Double

    var activityType: ActivityType? { ActivityType(rawValue: type) }

    @Relationship(deleteRule: .cascade, inverse: \LocationPoint.exercise)
    private var route: [LocationPoint] = []
    
    var routeCoordinates: [LocationPoint] {
        get {
            route.sorted{$0.sortIndex < $1.sortIndex}
        }
        set {
            route = newValue
        }
    }

    init(
        id: UUID = UUID(),
        type: String,
        startTime: Date,
        endTime: Date? = nil,
        steps: Int? = nil,
        distance: Double
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.steps = steps
        self.distance = distance
    }
}

@Model
final class LocationPoint: Hashable {
    @Attribute(.unique)
    var id: UUID
    var latitude: Double
    var longitude: Double
    var sortIndex: Int

    var exercise: Exercise?

    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D, sortIndex: Int, exercise: Exercise? = nil) {
        self.id = id
        self.exercise = exercise
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.sortIndex = sortIndex
    }

    init(id: UUID = UUID(), latitude: Double, longitude: Double, sortIndex: Int, exercise: Exercise? = nil) {
        self.id = id
        self.exercise = exercise
        self.latitude = latitude
        self.longitude = longitude
        self.sortIndex = sortIndex
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
