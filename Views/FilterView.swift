import SwiftUI

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MainListViewModel

    @State private var plateNumber: String = ""
    @State private var selectedState: String = "All"
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: String = ""
    @State private var color: String = ""
    @State private var dateFrom: Date = Date().addingTimeInterval(-86400 * 7) // One week ago
    @State private var dateTo: Date = Date()

    let states = ["All"] + ["AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN",
                           "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
                           "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD",
                           "TN","TX","UT","VT","VA","WA","WV","WI","WY"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Plate Number")) {
                    TextField("Enter Plate Number", text: $plateNumber)
                }

                Section(header: Text("State")) {
                    Picker("Select State", selection: $selectedState) {
                        ForEach(states, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                }

                Section(header: Text("Make & Model")) {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                }

                Section(header: Text("Year")) {
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Color")) {
                    TextField("Color", text: $color)
                }

                Section(header: Text("Date Range")) {
                    DatePicker("From", selection: $dateFrom, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("To", selection: $dateTo, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Filter")
            .navigationBarItems(leading: Button("Clear") {
                viewModel.clearFilters()
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Apply") {
                viewModel.applyFilters(plateNumber: plateNumber,
                                       state: selectedState == "All" ? nil : selectedState,
                                       make: make,
                                       model: model,
                                       year: Int16(year) ?? 0,
                                       color: color,
                                       dateFrom: dateFrom,
                                       dateTo: dateTo)
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
