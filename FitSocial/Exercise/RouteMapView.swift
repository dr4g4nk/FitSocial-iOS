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
        Map(position: $camera) {
            UserAnnotation()

            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(.blue, lineWidth: 4)

                if isTracking, let start = coordinates.first {
                    Annotation("", coordinate: start) {
                        Image(systemName: "flag")
                            .padding(6)
                            .tint(.accentColor)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onChange(of: currentLocation) {
            // centriraj na korisnika pri svakom novom očitanju
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