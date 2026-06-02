//
//  AVCaptureDevice+Conformance.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

public import AVFoundation

/// Adapts the AVFoundation types onto the app's abstract protocols so the
/// real `AVCaptureDevice` can be passed wherever ``CaptureDeviceProtocol``
/// is expected (Adapter pattern, no runtime cost — the protocol witnesses
/// are filled in directly by the existing members).

extension AVCaptureDevice.Format: CaptureDeviceFormatProtocol {}

extension AVCaptureDevice: CaptureDeviceProtocol {
    public var captureFormat: CaptureDeviceFormatProtocol {
        return activeFormat
    }
}
