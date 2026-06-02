//
//  CaptureDeviceFormatProtocol.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

public import AVFoundation
import CoreMedia

/// Abstraction over `AVCaptureDevice.Format` for the subset of values the
/// torch manager reads while estimating ambient brightness from camera
/// settings.
///
/// Kept narrow on purpose — adding members here forces every mock to grow,
/// so anything that isn't actually consumed by production code should stay
/// out.
public protocol CaptureDeviceFormatProtocol {
    var minISO: Float { get }
    var maxISO: Float { get }
    var minExposureDuration: CMTime { get }
    var maxExposureDuration: CMTime { get }
}
