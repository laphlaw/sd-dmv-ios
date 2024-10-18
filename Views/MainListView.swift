import SwiftUI
import CoreData

struct MainListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = MainListViewModel()
    @State private var showingFilter = false
    @State private var showingMap = false
    @State private var showingScan = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredVehicles) { vehicle in
                    NavigationLink(destination: DetailView(vehicle: vehicle)) {
                        VStack(alignment: .leading) {
                            Text("\(vehicle.make) \(vehicle.model) (\(vehicle.year))")
                                .font(.headline)
                            Text("Plate: \(vehicle.plateNumber) - \(vehicle.state)")
                                .font(.subheadline)
                            Text("Color: \(vehicle.color)")
                                .font(.subheadline)
                            Text("Date: \(vehicle.date, formatter: itemFormatter)")
                                .font(.caption)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteVehicles)
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilter.toggle() }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingMap.toggle() }) {
                            Image(systemName: "map")
                        }
                        Button(action: { showingScan.toggle() }) {
                            Image(systemName: "camera")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingMap) {
                MapView(vehicles: viewModel.filteredVehicles)
            }
            .sheet(isPresented: $showingScan) {
                ScanView()
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
