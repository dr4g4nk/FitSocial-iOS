//
//  RouteMapView.swift
//  FitSocial
//
//  Created by Dragan Kos on 2. 9. 2025..
//

import CoreLocation
import MapKit
import Observation
import SwiftUI

struct RouteMapView: View {
    @State private var camera: MapCameraPosition = .automatic

    let coordinates: [CLLocationCoordinate2D]
    let currentLocation: CLLocation?
    let isTracking: Bool

    var body: some View {
        Map(position: $camera, interactionModes: .all) {
            MapPolyline(coordinates: coordinates)
                .stroke(.blue, lineWidth: 4)
            if isTracking {
                UserAnnotation()
            } else {
                if let first = coordinates.first {
                    Annotation("", coordinate: first) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title)
                            .shadow(radius: 3)
                    }
                }
                if let last = coordinates.last {
                    Annotation("", coordinate: last) {
                        Image(systemName: "flag.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title)
                            .shadow(radius: 3)
                    }
                }
            }

        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onChange(of: currentLocation) {
            if let loc = currentLocation {
                camera = .region(
                    MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: 0.005,
                            longitudeDelta: 0.005
                        )
                    )
                )
            }
        }
    }
}
