//
//  CaptureDeviceProtocol.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

public import AVFoundation
import CoreMedia

/// Abstraction over `AVCaptureDevice` for the subset of capabilities the
/// scanner needs (torch control + exposure read-out).
///
/// The protocol exists so that `TorchManager` and friends can be exercised
/// in unit tests against a deterministic `MockCaptureDevice`, while still
/// running unmodified against the real `AVCaptureDevice` in production
/// (see `AVCaptureDevice+Conformance`). It follows the Dependency Inversion
/// Principle — high-level logic depends on this abstraction rather than on
/// the concrete AVFoundation type.
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
