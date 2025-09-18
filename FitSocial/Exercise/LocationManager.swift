//
//  LocationManager.swift
//  FitSocial
//
//  Created by Dragan Kos on 2. 9. 2025..
//

import CoreLocation
import MapKit
import Observation
import SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isTracking = false
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var distance: Double = 0
    var duration: TimeInterval = 0
    var speed: Double = 0
    var needsAlwaysPermission = false
    
    var selectedActivity: ActivityType = .walking
    
    var updateTick: Int = 0

    private(set) var exerciseDataAvailable = false

    private let manager = CLLocationManager()
    private(set) var startTime: Date?
    private var lastLocation: CLLocation?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness

        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = false

        loadSession()
    }

    func setDistanceFilter(distanceFilter: CLLocationDistance) {
        manager.distanceFilter = distanceFilter
    }

    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // For background tracking, we need "Always" permission
            needsAlwaysPermission = true
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func startTracking(for activitiType: ActivityType) {
        guard authorizationStatus == .authorizedAlways else {
            if authorizationStatus == .authorizedWhenInUse {
                needsAlwaysPermission = true
            }
            return
        }
        exerciseDataAvailable = false

        isTracking = true
        startTime = Date()
        distance = 0
        duration = 0
        routeCoordinates = []
        lastLocation = nil
        selectedActivity = activitiType

        // Enable background location updates
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true

        // Start background task
        startBackgroundTask()

        // Start location updates
        manager.startUpdatingLocation()

        // Save session
        saveSession()

        // Schedule local notification for when app is backgrounded
        scheduleBackgroundNotification()
    }

    private var data: Exercise?
    func getExerciseData() -> Exercise? {
        guard exerciseDataAvailable else { return nil }

        return data
    }

    func stopTracking() {
        isTracking = false

        // Disable background location updates
        manager.allowsBackgroundLocationUpdates = false
        manager.stopUpdatingLocation()

        // End background task
        endBackgroundTask()

        let data = Exercise(
            type: "",
            startTime: startTime!,
            endTime: Date.now,
            distance: distance
        )

        data.routeCoordinates = routeCoordinates.enumerated().map({ it in
            LocationPoint(coordinate: it.element, sortIndex: it.offset)
        })

        self.data = data
        exerciseDataAvailable = true

        startTime = nil

        // Clear saved session
        clearSession()

        // Cancel background notifications
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }

    func pauseTracking() {
        manager.stopUpdatingLocation()
        endBackgroundTask()
    }

    func resumeTracking() {
        guard isTracking else { return }
        startBackgroundTask()
        manager.startUpdatingLocation()
    }

    private func startBackgroundTask() {
        endBackgroundTask()  // End any existing task

        backgroundTaskID = UIApplication.shared.beginBackgroundTask(
            withName: "LocationTracking"
        ) { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    private func saveSession() {
        guard isTracking else { return }

        let sessionData: [String: Any] = [
            "isTracking": isTracking,
            "type": selectedActivity.rawValue,
            "startTime": startTime?.timeIntervalSince1970 ?? 0,
            "distance": distance,
            "coordinates": routeCoordinates.map {
                ["lat": $0.latitude, "lon": $0.longitude]
            },
        ]

        UserDefaults.standard.set(sessionData, forKey: "TrackingSession")
    }

    private func loadSession() {
        guard
            let sessionData = UserDefaults.standard.dictionary(
                forKey: "TrackingSession"
            ),
            let wasTracking = sessionData["isTracking"] as? Bool,
            wasTracking
        else { return }
        
        if let type = sessionData["type"] as? String {
            selectedActivity = .init(rawValue: type) ?? .walking
        }

        if let startTimeInterval = sessionData["startTime"] as? TimeInterval,
            startTimeInterval > 0
        {
            startTime = Date(timeIntervalSince1970: startTimeInterval)
        }

        distance = sessionData["distance"] as? Double ?? 0

        if let coordsArray = sessionData["coordinates"] as? [[String: Double]] {
            routeCoordinates = coordsArray.compactMap { coord in
                guard let lat = coord["lat"], let lon = coord["lon"] else {
                    return nil
                }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }

        isTracking = true

        // Resume tracking if we have proper permissions
        if authorizationStatus == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
        }
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "TrackingSession")
    }

    private func scheduleBackgroundNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Praćenje aktivnosti"
        content.body = "Vaša aktivnost će se prati i u pozadini"
        content.categoryIdentifier = "exercise_tracking"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "background_tracking",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let newLocation = locations.last else { return }

        Task{
            location = newLocation
            
            if isTracking {
                routeCoordinates.append(newLocation.coordinate)
                
                if let lastLoc = lastLocation {
                    let distanceIncrement = newLocation.distance(from: lastLoc)
                    distance += distanceIncrement
                }
                
                lastLocation = newLocation
                
                if let startTime = startTime {
                    duration = Date().timeIntervalSince(startTime)
                }
                
                speed = newLocation.speed > 0 ? newLocation.speed : 0
                
                // Save session after each location update
                saveSession()
                
                updateTick &+= 1
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        authorizationStatus = status

        // Handle permission changes
        switch status {
        case .authorizedAlways:
            needsAlwaysPermission = false
        case .authorizedWhenInUse:
            needsAlwaysPermission = true
        case .denied, .restricted:
            if isTracking {
                stopTracking()
            }
        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print(
            "Location manager failed with error: \(error.localizedDescription)"
        )
    }
}
