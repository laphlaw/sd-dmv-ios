import SwiftUI
import MapKit

struct MapView: View {
    var vehicles: [Vehicle]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of USA
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: vehicles) { vehicle in
            MapMarker(coordinate: CLLocationCoordinate2D(latitude: vehicle.latitude, longitude: vehicle.longitude), tint: .blue)
        }
        .navigationTitle("Map View")
    }
}
