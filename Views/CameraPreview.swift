// File: Views/CameraPreview.swift

import SwiftUI
import AVFoundation
import Vision

struct CameraPreview: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }

        var textObservations: [VNRecognizedTextObservation] = [] {
            didSet {
                DispatchQueue.main.async {
                    self.setNeedsDisplay()
                }
            }
        }

        private var orientationObserver: NSObjectProtocol?

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupOrientationObserver()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupOrientationObserver()
        }

        deinit {
            if let observer = orientationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        private func setupOrientationObserver() {
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateVideoOrientation()
            }
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            updateVideoOrientation()
        }

        private func updateVideoOrientation() {
            guard let connection = previewLayer.connection else { return }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
                previewLayer.frame = bounds
                setNeedsDisplay()
            }
        }

        private func currentVideoOrientation() -> AVCaptureVideoOrientation {
            switch UIDevice.current.orientation {
            case .portrait:
                return .portrait
            case .landscapeRight:
                return .landscapeLeft
            case .landscapeLeft:
                return .landscapeRight
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                return .portrait
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)
            guard let context = UIGraphicsGetCurrentContext() else { return }

            context.setStrokeColor(UIColor.red.cgColor)
            context.setLineWidth(2.0)

            for observation in textObservations {
                let boundingBox = observation.boundingBox

                // Convert normalized coordinates to view coordinates
                let size = self.bounds.size
                let convertedRect = CGRect(
                    x: boundingBox.origin.x * size.width,
                    y: (1 - boundingBox.origin.y - boundingBox.size.height) * size.height,
                    width: boundingBox.size.width * size.width,
                    height: boundingBox.size.height * size.height
                )

                context.stroke(convertedRect)

                // Draw recognized text above the bounding box
                if let candidate = observation.topCandidates(1).first {
                    let text = candidate.string
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 16),
                        .foregroundColor: UIColor.green
                    ]
                    let attributedText = NSAttributedString(string: text, attributes: attributes)
                    
                    // Calculate text size
                    let textSize = attributedText.size()
                    
                    // Define text drawing position
                    let textRect = CGRect(
                        x: convertedRect.origin.x,
                        y: convertedRect.origin.y - textSize.height - 4,
                        width: convertedRect.width,
                        height: textSize.height
                    )
                    
                    // Draw text background for better visibility
                    context.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
                    context.fill(textRect)
                    
                    // Draw the text
                    attributedText.draw(in: textRect)
                }
            }
        }
    }

    let session: AVCaptureSession
    @Binding var textObservations: [VNRecognizedTextObservation]

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.textObservations = textObservations
    }
}
