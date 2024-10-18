import Foundation
import CoreData
import SwiftUI

class MainListViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var filteredVehicles: [Vehicle] = []

    private var viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchVehicles()
    }

    func fetchVehicles() {
        let request: NSFetchRequest<Vehicle> = Vehicle.fetchRequest()
        do {
            vehicles = try viewContext.fetch(request)
            filteredVehicles = vehicles
        } catch {
            print("Error fetching vehicles: \(error)")
        }
    }

    func deleteVehicles(offsets: IndexSet) {
        offsets.map { filteredVehicles[$0] }.forEach(viewContext.delete)
        saveContext()
        fetchVehicles()
    }

    func applyFilters(plateNumber: String?, state: String?, make: String?, model: String?, year: Int16?, color: String?, dateFrom: Date, dateTo: Date) {
        var predicates: [NSPredicate] = []

        if let plate = plateNumber, !plate.isEmpty {
            predicates.append(NSPredicate(format: "plateNumber CONTAINS[c] %@", plate))
        }

        if let state = state, state != "All" {
            predicates.append(NSPredicate(format: "state == %@", state))
        }

        if let make = make, !make.isEmpty {
            predicates.append(NSPredicate(format: "make CONTAINS[c] %@", make))
        }

        if let model = model, !model.isEmpty {
            predicates.append(NSPredicate(format: "model CONTAINS[c] %@", model))
        }

        if let year = year, year != 0 {
            predicates.append(NSPredicate(format: "year == %d", year))
        }

        if let color = color, !color.isEmpty {
            predicates.append(NSPredicate(format: "color CONTAINS[c] %@", color))
        }

        predicates.append(NSPredicate(format: "date >= %@ AND date <= %@", dateFrom as NSDate, dateTo as NSDate))

        let request: NSFetchRequest<Vehicle> = Vehicle.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            filteredVehicles = try viewContext.fetch(request)
        } catch {
            print("Error applying filters: \(error)")
            filteredVehicles = vehicles
        }
    }

    func clearFilters() {
        filteredVehicles = vehicles
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
