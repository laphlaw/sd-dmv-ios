// File: Views/VehicleMapView.swift

import SwiftUI
import MapKit

struct VehicleMapView: View {
    var latitude: Double
    var longitude: Double
    
    @State private var region: MKCoordinateRegion
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapMarkerItem(latitude: latitude, longitude: longitude)]) { item in
            MapMarker(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude), tint: .red)
        }
        .edgesIgnoringSafeArea(.all)
        .navigationTitle("Vehicle Location")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MapMarkerItem: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
}
