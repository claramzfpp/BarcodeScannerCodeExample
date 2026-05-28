//
//  MockCaptureDevice.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

import AVFoundation
import CoreMedia
import BarcodeScanner

// MARK: - Mock Implementation

/// Simple mock for AVCaptureDevice.Format
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

/// Simple mock for AVCaptureDevice
final class MockCaptureDevice: CaptureDeviceProtocol {
    // MARK: - CaptureDeviceProtocol Properties
    
    var hasTorch: Bool = true
    var torchMode: AVCaptureDevice.TorchMode = .off
    var iso: Float = 100.0
    var exposureDuration: CMTime = CMTime(seconds: 0.01, preferredTimescale: 1000)
    var captureFormat: CaptureDeviceFormatProtocol = MockCaptureDeviceFormat()
    
    // MARK: - Test Tracking Properties
    
    var configurationLockCount = 0
    var lastTorchLevel: Float = 0.0
    var lockError: Error?
    
    // MARK: - Computed Properties for Testing
    
    var wasTorchTurnedOn: Bool {
        return torchMode == .on
    }
    
    var wasTorchTurnedOff: Bool {
        return torchMode == .off
    }
    
    // MARK: - CaptureDeviceProtocol Methods
    
    func lockForConfiguration() throws {
        if let error = lockError {
            throw error
        }
        configurationLockCount += 1
    }
    
    func unlockForConfiguration() {
        // Mock implementation - nothing to do
    }
    
    func setTorchModeOn(level torchLevel: Float) throws {
        lastTorchLevel = torchLevel
        torchMode = .on
    }
    
    // MARK: - Helper Methods for Tests
    func setDarkEnvironment() {
        iso = 3200.0
        exposureDuration = CMTime(seconds: 0.3, preferredTimescale: 1000)
    }

    func setBrightEnvironment() {
        iso = 50.0
        exposureDuration = CMTime(seconds: 0.001, preferredTimescale: 1000)
    }
    
    func setMediumEnvironment() {
        iso = 400.0
        exposureDuration = CMTime(seconds: 0.05, preferredTimescale: 1000)
    }
    
    func reset() {
        torchMode = .off
        iso = 100.0
        exposureDuration = CMTime(seconds: 0.01, preferredTimescale: 1000)
        configurationLockCount = 0
        lastTorchLevel = 0.0
        hasTorch = true
    }
}
