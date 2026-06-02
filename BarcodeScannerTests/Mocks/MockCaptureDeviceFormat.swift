//
//  MockCaptureDeviceFormat.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

import AVFoundation
import CoreMedia
import BarcodeScanner

/// Test double for `AVCaptureDevice.Format`.
///
/// Exposes the four properties consumed by `TorchManager`'s brightness
/// estimator with sensible iPhone-class defaults, so most tests can
/// instantiate it with no arguments and only override the value they care
/// about.
final class MockCaptureDeviceFormat: CaptureDeviceFormatProtocol {
    var minISO: Float
    var maxISO: Float
    var minExposureDuration: CMTime
    var maxExposureDuration: CMTime

    init(
        minISO: Float = 29.0,
        maxISO: Float = 2000.0,
        minExposureDuration: CMTime = CMTime(seconds: 0.0001, preferredTimescale: 1000),
        maxExposureDuration: CMTime = CMTime(seconds: 0.5, preferredTimescale: 1000)
    ) {
        self.minISO = minISO
        self.maxISO = maxISO
        self.minExposureDuration = minExposureDuration
        self.maxExposureDuration = maxExposureDuration
    }
}
