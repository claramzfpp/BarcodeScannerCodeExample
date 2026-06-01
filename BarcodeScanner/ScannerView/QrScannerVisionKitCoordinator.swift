//
//  QrScannerVisionKitCoordinator.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 01/06/26.
//

internal import SwiftUI
internal import VisionKit
internal import AVFoundation
internal import Vision

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
        
        let codeType = CodeType(symbology: code.observation.symbology)
        let scanResult = ScanResult(value: payload, type: codeType)
        
        DispatchQueue.main.async {
            self.parent?.result = scanResult
            self.stopScanning()
        }
    }
}
