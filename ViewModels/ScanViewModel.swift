// File: ViewModels/ScanViewModel.swift

import Foundation
import SwiftUI
import AVFoundation
import Vision
import CoreData
import UIKit
import CoreLocation
import AudioToolbox
import MapKit

class ScanViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
    @Published var plateNumber: String = ""
    @Published var state: String = "Unknown"
    @Published var states = ["Unknown"] + ["AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN",
                            "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
                            "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD",
                            "TN","TX","UT","VT","VA","WA","WV","WI","WY"]
    @Published var make: String = ""
    @Published var model: String = ""
    @Published var year: String = ""       // Changed from Int16 to String
    @Published var color: String = ""
    @Published var apiSuccess: Bool = false
    @Published var isProcessing: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var textObservations: [VNRecognizedTextObservation] = []
    
    @Published var currentLatitude: Double = 0.0      // Added for GPS
    @Published var currentLongitude: Double = 0.0     // Added for GPS
    
    let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    private var locationManager: CLLocationManager = CLLocationManager()
    private var captureTimer: Timer?
    private var capturedImage: UIImage? = nil          // To store the captured image
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func setupCamera() {
        // Request camera access
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.configureSession()
                }
            } else {
                DispatchQueue.main.async {
                    self.permissionDenied = true
                }
            }
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
    
        // Set the session preset
        captureSession.sessionPreset = .photo
    
        // Select the back camera
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            print("Unable to access the camera.")
            captureSession.commitConfiguration()
            return
        }
    
        captureSession.addInput(videoInput)
    
        // Set up photo output
        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            print("Could not add photo output.")
            captureSession.commitConfiguration()
            return
        }
    
        captureSession.commitConfiguration()
        captureSession.startRunning()
    
        startCaptureTimer()
    }
    
    private func startCaptureTimer() {
        DispatchQueue.main.async {
            self.captureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if !self.isProcessing && !self.apiSuccess {    // Prevent capturing after success
                    self.captureImage()
                }
            }
        }
    }
    
    func stopCaptureTimer() {
        DispatchQueue.main.async {
            self.captureTimer?.invalidate()
            self.captureTimer = nil
        }
    }
    
    func captureImage() {
        guard photoOutput != nil else {
            print("Photo output is not configured.")
            return
        }
    
        if isProcessing {
            print("Still processing, skipping capture.")
            return
        }
    
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    // AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
    
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else { return }
    
        let fixedImage = uiImage.fixOrientation()
        self.capturedImage = fixedImage   // Store the captured image
    
        DispatchQueue.main.async {
            self.performOCR(on: fixedImage)
        }
    }
    
    private func performOCR(on image: UIImage) {
        isProcessing = true
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
    
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("OCR Error: \(error)")
                self.isProcessing = false
                return
            }
    
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.isProcessing = false
                return
            }
    
            DispatchQueue.main.async {
                // Filter observations based on regex and capitalization
                self.textObservations = observations.filter { observation in
                    guard let candidate = observation.topCandidates(1).first else { return false }
                    let text = candidate.string
                    let isAllUppercase = text == text.uppercased()
                    let platePattern = "^[A-Z0-9]{6,7}$" // Adjust based on expected plate formats
                    let plateRegex = try? NSRegularExpression(pattern: platePattern, options: .caseInsensitive)
                    let range = NSRange(location: 0, length: text.utf16.count)
                    let match = plateRegex?.firstMatch(in: text, options: [], range: range)
                    return isAllUppercase && (match != nil)
                }
    
                // Extract plate number from filtered observations
                self.extractPlateNumber(from: self.textObservations)
    
                self.isProcessing = false
            }
        }
    
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
    
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func extractPlateNumber(from observations: [VNRecognizedTextObservation]) {
        var foundPlate = ""
        var highestConfidence: VNConfidence = 0.0
    
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
    
            // Define a precise regex pattern for license plates
            let platePattern = "^[A-Z0-9]{6,7}$" // Adjust based on expected plate formats
            let plateRegex = try? NSRegularExpression(pattern: platePattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: candidate.string.utf16.count)
    
            if let match = plateRegex?.firstMatch(in: candidate.string, options: [], range: range) {
                if candidate.confidence > highestConfidence {
                    if let swiftRange = Range(match.range, in: candidate.string) {
                        foundPlate = String(candidate.string[swiftRange]).uppercased()
                        highestConfidence = candidate.confidence
                    }
                }
            }
        }
    
        if !foundPlate.isEmpty {
            self.plateNumber = foundPlate
            self.determineState(from: foundPlate)
            self.fetchVehicleDetails()
        }
    }
    
    private func determineState(from plate: String) {
        // Placeholder logic: In reality, you might use an API or a more sophisticated method
        // For now, set to "Unknown" and allow manual selection
        self.state = "CA"
    }
    
    private func fetchVehicleDetails() {
        guard !plateNumber.isEmpty else { return }
        // Make a request to KBB API
        KBBService.lookup(plate: plateNumber, state: state) { result in
            switch result {
            case .success(let vehicleDetails):
                DispatchQueue.main.async {
                    // Check if year, make, and model are present
                    if let make = vehicleDetails.make,
                       let model = vehicleDetails.model,
                       let year = vehicleDetails.year,
                       !make.isEmpty,
                       !model.isEmpty,
                       !year.isEmpty {
                        
                        self.make = make
                        self.model = model
                        self.year = year
                        self.color = "Unknown" // Since 'color' isn't provided by KBB API
                        self.apiSuccess = true
                        self.triggerVibration()
                        
                        // Request current location after successful KBB response
                        self.requestCurrentLocation()
                        
                        // Auto-save to database
                        self.autoSaveVehicle()
                        
                        // Stop auto capturing after successful KBB response
                        self.stopCaptureTimer()
                        self.captureSession.stopRunning()
                        
                        // Wait for 3 seconds before allowing new captures
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.apiSuccess = false
                            self.make = ""
                            self.model = ""
                            self.year = ""
                            self.color = ""
                            self.plateNumber = ""
                            self.textObservations = []
                            self.startCaptureTimer()
                            self.captureSession.startRunning()
                        }
                    } else {
                        // Handle incomplete KBB response if needed
                        print("Incomplete KBB response: Missing year, make, or model.")
                        self.apiSuccess = false
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("KBB API Error: \(error)")
                    self.apiSuccess = false
                }
            }
        }
    }
    
    private func triggerVibration() {
        // Vibrate the device on successful plate detection from KBB
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func requestCurrentLocation() {
        locationManager.requestLocation()
    }
    
    private func autoSaveVehicle() {
        guard let image = capturedImage else {
            print("No image to save.")
            return
        }
        
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data.")
            return
        }
        
        let newVehicle = Vehicle(context: viewContext)
        newVehicle.plateNumber = plateNumber
        newVehicle.state = state
        newVehicle.make = make
        newVehicle.model = model
        newVehicle.year = Int16(year) ?? 0 // Convert String to Int16 if possible
        newVehicle.color = color
        newVehicle.date = Date()
        newVehicle.latitude = currentLatitude      // Assign captured latitude
        newVehicle.longitude = currentLongitude    // Assign captured longitude
        newVehicle.imageData = imageData           // Assign captured image data
    
        do {
            try viewContext.save()
            print("Vehicle saved successfully.")
        } catch {
            print("Error saving vehicle: \(error)")
        }
    }
    
    func saveVehicle() {
        guard let image = capturedImage else {
            print("No image to save.")
            return
        }
        
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data.")
            return
        }
        
        let newVehicle = Vehicle(context: viewContext)
        newVehicle.plateNumber = plateNumber
        newVehicle.state = state
        newVehicle.make = make
        newVehicle.model = model
        newVehicle.year = Int16(self.year) ?? 0 // Convert String to Int16 if possible
        newVehicle.color = color
        newVehicle.date = Date()
        newVehicle.latitude = currentLatitude      // Assign captured latitude
        newVehicle.longitude = currentLongitude    // Assign captured longitude
        newVehicle.imageData = imageData           // Assign captured image data
    
        do {
            try viewContext.save()
            print("Vehicle saved successfully.")
        } catch {
            print("Error saving vehicle: \(error)")
        }
    }
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.currentLatitude = location.coordinate.latitude
            self.currentLongitude = location.coordinate.longitude
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error)")
    }
}

// UIImage extension to fix orientation
extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
