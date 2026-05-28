//
//  CaptureDeviceProtocol.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

public import AVFoundation
import CoreMedia

// MARK: - Protocols for Testability

/// Protocol that abstracts AVCaptureDevice for testing
public protocol CaptureDeviceProtocol: AnyObject {
    var hasTorch: Bool { get }
    var torchMode: AVCaptureDevice.TorchMode { get set }
    var iso: Float { get }
    var exposureDuration: CMTime { get }
    var captureFormat: CaptureDeviceFormatProtocol { get }
    
    func lockForConfiguration() throws
    func unlockForConfiguration()
    func setTorchModeOn(level torchLevel: Float) throws
}

/// Protocol that abstracts AVCaptureDevice.Format for testing
public protocol CaptureDeviceFormatProtocol {
    var minISO: Float { get }
    var maxISO: Float { get }
    var minExposureDuration: CMTime { get }
    var maxExposureDuration: CMTime { get }
}

// MARK: - AVCaptureDevice Conformance

extension AVCaptureDevice.Format: CaptureDeviceFormatProtocol {}

extension AVCaptureDevice: CaptureDeviceProtocol {
    public var captureFormat: CaptureDeviceFormatProtocol {
        return activeFormat
    }
}
