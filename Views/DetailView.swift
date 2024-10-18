import SwiftUI
import MapKit

struct DetailView: View {
    var vehicle: Vehicle
    @State private var region: MKCoordinateRegion

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: vehicle.latitude, longitude: vehicle.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let imageData = vehicle.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            }

            Form {
                Section(header: Text("License Plate")) {
                    Text("Plate Number: \(vehicle.plateNumber)")
                    Text("State: \(vehicle.state)")
                }

                Section(header: Text("Vehicle Details")) {
                    Text("Make: \(vehicle.make)")
                    Text("Model: \(vehicle.model)")
                    Text("Year: \(vehicle.year)")
                    Text("Color: \(vehicle.color)")
                }

                Section(header: Text("Date & Time")) {
                    Text("\(vehicle.date, formatter: itemFormatter)")
                }
            }

            Map(coordinateRegion: $region, annotationItems: [vehicle]) { vehicle in
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: vehicle.latitude, longitude: vehicle.longitude), tint: .red)
            }
            .frame(height: 300)
        }
        .navigationTitle("Vehicle Details")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short
    return formatter
}()
