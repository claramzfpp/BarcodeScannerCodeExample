//
//  MockCaptureDevice.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

import AVFoundation
import CoreMedia
import BarcodeScanner

/// Test double for `AVCaptureDevice`.
///
/// Tracks how many times `lockForConfiguration` was called and the last
/// torch level requested so tests can assert on the side effects produced
/// by ``TorchManager``. The `set*Environment` helpers preset ISO and
/// exposure to values that, fed through the production brightness
/// estimator, fall on the dark/medium/bright sides of the torch thresholds.
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

    /// Sets ISO/exposure to values consistent with a dim environment.
    func setDarkEnvironment() {
        iso = 3200.0
        exposureDuration = CMTime(seconds: 0.3, preferredTimescale: 1000)
    }

    /// Sets ISO/exposure to values consistent with a bright environment.
    func setBrightEnvironment() {
        iso = 50.0
        exposureDuration = CMTime(seconds: 0.001, preferredTimescale: 1000)
    }

    /// Sets ISO/exposure to values between the dark and bright presets.
    func setMediumEnvironment() {
        iso = 400.0
        exposureDuration = CMTime(seconds: 0.05, preferredTimescale: 1000)
    }

    /// Restores every property to its initial default. Useful between
    /// related assertions inside a single test without re-instantiating.
    func reset() {
        torchMode = .off
        iso = 100.0
        exposureDuration = CMTime(seconds: 0.01, preferredTimescale: 1000)
        configurationLockCount = 0
        lastTorchLevel = 0.0
        hasTorch = true
    }
}
