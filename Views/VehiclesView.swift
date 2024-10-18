// File: Views/VehiclesView.swift

import SwiftUI
import CoreData
import MapKit

struct VehiclesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.date, ascending: false)],
        animation: .default)
    private var vehicles: FetchedResults<Vehicle>
    
    var body: some View {
        NavigationView {
            ScrollView([.horizontal, .vertical]) {
                VStack {
                    Table(vehicles) {
                        TableColumn("Year") { vehicle in
                            Text(vehicle.year == 0 ? "Unknown" : "\(vehicle.year)")
                                .frame(width: 60, alignment: .leading)
                        }
                        TableColumn("Make") { vehicle in
                            Text(vehicle.make ?? "Unknown")
                                .frame(width: 100, alignment: .leading)
                        }
                        TableColumn("Model") { vehicle in
                            Text(vehicle.model ?? "Unknown")
                                .frame(width: 120, alignment: .leading)
                        }
                        TableColumn("License Plate") { vehicle in
                            Text(vehicle.plateNumber)
                                .frame(width: 100, alignment: .leading)
                        }
                        TableColumn("State") { vehicle in
                            Text(vehicle.state)
                                .frame(width: 60, alignment: .leading)
                        }
                        TableColumn("Date/Time") { vehicle in
                            VStack(alignment: .leading) {
                                Text(vehicle.date, style: .date)
                                Text(vehicle.date, style: .time)
                            }
                            .frame(width: 150, alignment: .leading)
                        }
                    }
                    .padding()
                    .onTapGesture {
                        // Prevent immediate navigation on horizontal scroll
                    }
                }
                .background(
                    // Overlay NavigationLinks for each vehicle
                    VStack {
                        ForEach(vehicles) { vehicle in
                            NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                EmptyView()
                            }
                            .opacity(0) // Hide the NavigationLink
                        }
                    }
                )
            }
            .navigationTitle("Vehicles")

        }
    }
}
