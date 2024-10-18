// File: Views/ScanView.swift

import SwiftUI
import Vision

struct ScanView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ScanViewModel()

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    CameraPreview(session: viewModel.captureSession, textObservations: $viewModel.textObservations)
                        .frame(height: 300)
                        .onAppear {
                            viewModel.setupCamera()
                        }
                        .onDisappear {
                            viewModel.stopCaptureTimer()
                            viewModel.captureSession.stopRunning()
                        }

                    // Overlay Instructions
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Align License Plate Within the Frame")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding()
                        }
                    }
                }

                if viewModel.isProcessing {
                    ProgressView("Processing...")
                        .padding()
                }

                Form {
                    Section(header: Text("License Plate")) {
                        TextField("Plate Number", text: $viewModel.plateNumber)
                            .disabled(true)
                        Picker("State", selection: $viewModel.state) {
                            ForEach(viewModel.states, id: \.self) { state in
                                Text(state).tag(state)
                            }
                        }
                    }

                    if viewModel.apiSuccess {
                        Section(header: Text("Vehicle Details")) {
                            Text("Make: \(viewModel.make)")
                            Text("Model: \(viewModel.model)")
                            Text("Year: \(viewModel.year)")
                            Text("Color: \(viewModel.color)")
                        }
                    }
                }

                Spacer()

                HStack {
                    // Optional: Keep the "Capture" button for manual captures
                    Button(action: { viewModel.captureImage() }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Capture")
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Spacer()

                    if viewModel.apiSuccess {
                        Button(action: {
                            viewModel.saveVehicle()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Save")
                            }
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Scan License Plate")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            // Handle permission denied alerts
            .alert(isPresented: $viewModel.permissionDenied) {
                Alert(
                    title: Text("Camera Access Denied"),
                    message: Text("Please enable camera access in Settings to scan license plates."),
                    primaryButton: .default(Text("Open Settings")) {
                        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(appSettings)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
