//
//  QRScannerCoordinator.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

public import SwiftUI
public import AVFoundation

/// QRScannerCoordinator manages the data output from the QRScannerController
/// This is where the scan result is updated
public class QRScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    @Binding var scanResult: ScanResult?
    
    private var lastScannedValue: String?
    private var lastScanTime: Date?
    private let debounceInterval: TimeInterval = 0.1
    
    init(_ scanResult: Binding<ScanResult?>) {
        self._scanResult = scanResult
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        
        if metadataObjects.isEmpty {
            print("No QR code detected")
            return
        }
        guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObj.stringValue else {
            return
        }
        
        let now = Date()
        if lastScannedValue == stringValue,
           let lastTime = lastScanTime,
           now.timeIntervalSince(lastTime) < debounceInterval {
            return
        }
        
        lastScannedValue = stringValue
        lastScanTime = now

        processMetadata(metadataObj)
    }
    
    private func processMetadata(_ metadataObj: AVMetadataMachineReadableCodeObject) {
        guard let result = metadataObj.stringValue else { return }
        switch metadataObj.type {
        case AVMetadataObject.ObjectType.dataMatrix:
            scanResult = ScanResult(value: result, type: .dataMatrix)
            print("Scan result (Data Matrix): \(result)")
            
        case AVMetadataObject.ObjectType.qr:
            scanResult = ScanResult(value: result, type: .qr)
            print("Scan result (QR): \(result)")
            
        case AVMetadataObject.ObjectType.code39:
            scanResult = ScanResult(value: result, type: .code39)
            print("Scan result (Code39): \(result)")
            
        case AVMetadataObject.ObjectType.code128:
            scanResult = ScanResult(value: result, type: .code128)
            print("Scan result (Code128): \(result)")
            
        default:
            break
        }
    }
}
