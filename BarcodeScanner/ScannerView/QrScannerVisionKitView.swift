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

class QrScannerVisionKitCoordinator: NSObject, DataScannerViewControllerDelegate {
    
    var parent: QrScannerVisionKitView?
    private var lastDetectedCode: String = ""
    private var lastDetectionTime: Date = Date()
    private var hasDetectedCode = false
    
    private var luminosityCheckTimer: Timer?
    private let torchManager = TorchManager()
    
    /// Interval in seconds for luminosity checks
    private let luminosityCheckInterval: TimeInterval = 1.0
    
    /// Delay before starting luminosity monitoring after scanner initialization
    private let scannerInitDelay: TimeInterval = 0.1
    
    /// Initializes the QR scanner coordinator.
    /// - Parameter parent: The parent QrScannerVisionKitView instance
    init(parent: QrScannerVisionKitView) {
        super.init()
        self.parent = parent
    }
    
    /// Starts the QR code scanning process and initiates luminosity monitoring.
    func startScanningIfPermitted() {
        guard let scannerViewController = parent?.scannerViewController else {
            return
        }
        
        do {
            try scannerViewController.startScanning()
            
            // Wait for camera to initialize before monitoring luminosity
            DispatchQueue.main.asyncAfter(deadline: .now() + scannerInitDelay) {
                self.startMonitoringLuminosity()
            }
        } catch {
            debugPrint("Failed to start VisionKit scanning: \(error.localizedDescription)")
        }
    }
    
    /// Stops the QR code scanning process and halts luminosity monitoring.
    func stopScanning() {
        stopMonitoringLuminosity()
        torchManager.reset()
        parent?.scannerViewController.stopScanning()
    }
    
    /// Starts periodic monitoring of environment luminosity.
    private func startMonitoringLuminosity() {
        luminosityCheckTimer = Timer.scheduledTimer(
            withTimeInterval: luminosityCheckInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAndAdjustTorch()
            }
        }
    }
    
    /// Stops the luminosity monitoring timer and turns off the torch.
    private func stopMonitoringLuminosity() {
        luminosityCheckTimer?.invalidate()
        luminosityCheckTimer = nil
        
        // Ensure torch is turned off
        torchManager.disableTorch()
    }
    
    /// Checks current luminosity and adjusts torch state accordingly.
    /// Uses a "sticky" approach: once torch is on, it stays on until VERY bright light is detected.
    private func checkAndAdjustTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        torchManager.updateTorch(device: device)
    }
    
    // MARK: - DataScannerViewControllerDelegate
    
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didAdd addedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        processAddedItems(items: addedItems)
    }
    
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didRemove removedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        lastDetectedCode = ""
    }
    
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didUpdate updatedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        processAddedItems(items: updatedItems)
    }
    
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didTapOn item: RecognizedItem
    ) {
        processItem(item: item)
    }
    
    /// Processes a collection of recognized items.
    private func processAddedItems(items: [RecognizedItem]) {
        for item in items {
            processItem(item: item)
        }
    }
    
    /// Processes a single recognized item and extracts barcode data if applicable.
    private func processItem(item: RecognizedItem) {
        guard !hasDetectedCode else {
            return
        }
        
        switch item {
        case .barcode(let code):
            handleBarcodeDetection(code: code)
        case .text(_):
            // Text recognition not handled in this scanner
            break
        @unknown default:
            break
        }
    }
    
    /// Handles the detection and processing of a barcode.
    private func handleBarcodeDetection(code: RecognizedItem.Barcode) {
        guard let payload = code.payloadStringValue, !payload.isEmpty else {
            return
        }
        
        let currentTime = Date()        
        let codeType = CodeType(symbology: code.observation.symbology)
        let scanResult = ScanResult(value: payload, type: codeType)
        
        DispatchQueue.main.async {
            self.parent?.result = scanResult
            self.stopScanning()
        }
    }
}
