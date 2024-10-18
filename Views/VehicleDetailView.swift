// File: Views/VehicleDetailView.swift

import SwiftUI
import MapKit

struct VehicleDetailView: View {
    var vehicle: Vehicle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Display Vehicle Image
            if let imageData = vehicle.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
            
            // Display Vehicle Details
            VStack(alignment: .leading, spacing: 5) {
                Text("Year: \(vehicle.year == 0 ? "Unknown" : "\(vehicle.year)")")
                Text("Make: \(vehicle.make ?? "Unknown")")
                Text("Model: \(vehicle.model ?? "Unknown")")
                Text("License Plate: \(vehicle.plateNumber)")
                Text("State: \(vehicle.state)")
                Text("Date/Time: \(vehicle.date, formatter: dateFormatter)")
                Text("Latitude: \(vehicle.latitude)")
                Text("Longitude: \(vehicle.longitude)")
            }
            .font(.headline)
            
            // Show Map Link
            NavigationLink(destination: VehicleMapView(latitude: vehicle.latitude, longitude: vehicle.longitude)) {
                Text("Show Map")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .underline()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Vehicle Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

