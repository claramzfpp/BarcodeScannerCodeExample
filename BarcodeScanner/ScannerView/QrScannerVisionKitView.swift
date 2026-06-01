//
//  QrScannerVisionKitView.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import SwiftUI
internal import VisionKit
internal import AVFoundation
internal import Vision

/// A SwiftUI view that provides QR code scanning functionality using VisionKit.
///
/// This view wraps the native DataScannerViewController and provides:
/// - QR code and barcode detection
/// - Automatic torch control based on environment luminosity
/// - Camera permission handling
/// - Scan result binding
///
/// Note: Use `GenericQRCodeScannerView` when you need automatic selection between
/// VisionKit and AVFoundation scanner implementations.
@MainActor
struct QrScannerVisionKitView: UIViewControllerRepresentable {
    @Binding var result: ScanResult?
    
    var scannerViewController: DataScannerViewController
    
    /// Checks if the device supports and has access to the data scanner
    static var scannerAvailable: Bool {
        DataScannerViewController.isSupported &&
        DataScannerViewController.isAvailable
    }
    
    init(_ result: Binding<ScanResult?>) {
        self._result = result
        self.scannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr, .dataMatrix, .code39, .code128])],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        scannerViewController.delegate = context.coordinator
        
        requestCameraPermission {
            context.coordinator.startScanningIfPermitted()
        }
        
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }
    
    func makeCoordinator() -> QrScannerVisionKitCoordinator {
        return QrScannerVisionKitCoordinator(parent: self)
    }
    
    /// Requests camera access permission from the user.
    ///
    /// This method checks the current camera authorization status and requests
    /// permission if needed. The completion handler is called on the main thread.
    private func requestCameraPermission(completion: @escaping () -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    completion()
                }
            }
        }
    }
}
