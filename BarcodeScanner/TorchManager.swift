//
//  TorchManager.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation
internal import AVFoundation

/// Manager responsible for automatic torch control based on ambient brightness.
///
/// This manager monitors brightness levels and automatically enables/disables
/// the device's torch (flashlight) to improve QR code scanning in low-light conditions.
///
/// Features:
/// - Automatic brightness monitoring via sample buffers or device settings
/// - Hysteresis thresholds to prevent torch flickering
/// - Configurable torch intensity (default: 50%)
/// - Thread-safe operations
final class TorchManager {
    
    // MARK: - Configuration
    
    /// Brightness threshold below which the torch is turned ON
    /// EXIF Scale: 10+ = bright sun, 6-9 = normal indoor, 3-5 = dim indoor, 0-2 = twilight, < 0 = dark
    private let turnOnThreshold: Double
    
    /// Brightness threshold above which the torch is turned OFF
    /// Uses hysteresis to prevent flickering
    private let turnOffThreshold: Double
    
    /// Minimum time interval between torch state updates (in seconds)
    private let updateInterval: TimeInterval
    
    /// Torch brightness level when enabled (0.0 to 1.0)
    private let torchLevel: Float
    
    // MARK: - State
    
    /// Timestamp of the last torch update
    private var lastTorchUpdate: TimeInterval = 0
    
    /// Current torch state
    private var isTorchOn = false
    
    /// Brightness level recorded before torch was enabled
    /// Used to prevent torch's own light from affecting brightness readings
    private var brightnessBeforeTorch: Double?
    
    // MARK: - Initialization
    
    /// Creates a new TorchManager with configurable parameters.
    ///
    /// - Parameters:
    ///   - turnOnThreshold: Brightness level below which torch turns on (default: 3.0)
    ///   - turnOffThreshold: Brightness level above which torch turns off (default: 8.0)
    ///   - updateInterval: Minimum seconds between torch updates (default: 2.0)
    ///   - torchLevel: Torch brightness from 0.0 to 1.0 (default: 0.5)
    init(
        turnOnThreshold: Double = 3.0,
        turnOffThreshold: Double = 8.0,
        updateInterval: TimeInterval = 1.0,
        torchLevel: Float = 0.5
    ) {
        self.turnOnThreshold = turnOnThreshold
        self.turnOffThreshold = turnOffThreshold
        self.updateInterval = updateInterval
        self.torchLevel = torchLevel
    }
    
    // MARK: - Public Methods
    
    /// Processes a sample buffer to extract brightness and update torch state.
    ///
    /// This method should be called from `AVCaptureVideoDataOutputSampleBufferDelegate`.
    ///
    /// - Parameters:
    ///   - sampleBuffer: The sample buffer containing EXIF brightness metadata
    ///   - device: The capture device to control the torch on
    func updateTorch(_ sampleBuffer: CMSampleBuffer? = nil, device: CaptureDeviceProtocol) {
        let currentTime = ProcessInfo.processInfo.systemUptime
        
        // Throttle updates
        guard currentTime - lastTorchUpdate > updateInterval else { return }
        
        var brightnessValue: Double?
        
        if let sampleBuffer {
            brightnessValue = extractBrightnessValue(from: sampleBuffer)
        } else {
            brightnessValue = estimateBrightness(from: device)
        }
        
        updateTorchIfNeeded(for: brightnessValue ?? turnOffThreshold, device: device, at: currentTime)
    }
    
    /// Manually disables the torch.
    ///
    /// - Parameter device: The capture device to turn off torch on (optional)
    func disableTorch(device: CaptureDeviceProtocol? = nil) {
        let targetDevice = device ?? AVCaptureDevice.default(for: .video)
        guard let targetDevice = targetDevice, targetDevice.hasTorch else {
            return
        }
        
        do {
            try targetDevice.lockForConfiguration()
            defer { targetDevice.unlockForConfiguration() }
            
            targetDevice.torchMode = .off
            isTorchOn = false
            brightnessBeforeTorch = nil
        } catch {
            Logger.default?.error("Failed to disable torch: \(error.localizedDescription)")
        }
    }
    
    /// Resets the manager's state.
    ///
    /// Call this when stopping the scanner to ensure clean state.
    func reset() {
        lastTorchUpdate = 0
        isTorchOn = false
        brightnessBeforeTorch = nil
    }
    
    // MARK: - Private Methods - Brightness Extraction
    
    /// Extracts the brightness value (EXIF LV) from a video sample buffer.
    ///
    /// - Parameter sampleBuffer: The sample buffer to extract brightness from
    /// - Returns: Brightness value on EXIF scale, or nil if unavailable
    private func extractBrightnessValue(from sampleBuffer: CMSampleBuffer) -> Double? {
        let attachmentMode = kCMAttachmentMode_ShouldPropagate
        
        guard let metadataDict = CMCopyDictionaryOfAttachments(
            allocator: nil,
            target: sampleBuffer,
            attachmentMode: attachmentMode
        ) as? [String: Any] else {
            return nil
        }
        
        guard let exifMetadata = metadataDict[
            kCGImagePropertyExifDictionary as String
        ] as? [String: Any] else {
            return nil
        }
        
        return exifMetadata[
            kCGImagePropertyExifBrightnessValue as String
        ] as? Double
    }
    
    /// Estimates brightness level based on camera ISO and exposure settings.
    ///
    /// This is used when EXIF brightness values are not available (e.g., VisionKit).
    ///
    /// - Parameter device: The capture device to read settings from
    /// - Returns: Estimated brightness on a scale similar to EXIF (0-10)
    private func estimateBrightness(from device: CaptureDeviceProtocol) -> Double {
        // Get current ISO (sensitivity to light)
        let currentISO = device.iso
        let minISO = device.captureFormat.minISO
        let maxISO = device.captureFormat.maxISO
        
        // Get current exposure duration
        let currentExposure = device.exposureDuration.seconds
        let minExposure = device.captureFormat.minExposureDuration.seconds
        let maxExposure = device.captureFormat.maxExposureDuration.seconds
        
        // Normalize ISO (0.0 = minimum ISO/bright, 1.0 = maximum ISO/dark)
        let normalizedISO = Double((currentISO - minISO) / (maxISO - minISO))
        
        // Normalize exposure (0.0 = fast/bright, 1.0 = slow/dark)
        let normalizedExposure = (currentExposure - minExposure) / (maxExposure - minExposure)
        
        // Combine ISO and exposure to estimate brightness
        // Higher ISO + longer exposure = darker environment
        let darknessFactor = (normalizedISO + normalizedExposure) / 2.0
        
        // Convert to EXIF-like scale (10 = bright, 0 = dark)
        return 10.0 * (1.0 - darknessFactor)
    }
    
    // MARK: - Private Methods - Torch Control
    
    /// Updates the torch mode based on the current brightness level.
    ///
    /// Uses hysteresis thresholds to prevent torch flickering:
    /// - Turns ON when brightness < turnOnThreshold
    /// - Turns OFF when brightness > turnOffThreshold
    ///
    /// - Parameters:
    ///   - brightnessValue: Current brightness level
    ///   - device: The capture device to control
    ///   - currentTime: Current system uptime
    private func updateTorchIfNeeded(
        for brightnessValue: Double,
        device: CaptureDeviceProtocol,
        at currentTime: TimeInterval
    ) {
        guard device.hasTorch else { return }
        
        let newMode = determineTorchMode(
            currentMode: device.torchMode,
            brightnessValue: brightnessValue
        )
        
        if newMode != device.torchMode {
            setTorchMode(newMode, on: device, at: currentTime)
        }
    }
    
    /// Determines the new torch mode based on current state and brightness.
    ///
    /// - Parameters:
    ///   - currentMode: Current torch mode
    ///   - brightnessValue: Current brightness level
    /// - Returns: Desired torch mode
    private func determineTorchMode(
        currentMode: AVCaptureDevice.TorchMode,
        brightnessValue: Double
    ) -> AVCaptureDevice.TorchMode {
        if !isTorchOn {
            // Torch is OFF: Check if environment is dark enough to turn ON
            if brightnessValue < turnOnThreshold {
                brightnessBeforeTorch = brightnessValue
                return .on
            }
        } else {
            // Torch is ON: Only turn off if VERY bright
            // This prevents the torch's own light from causing flickering
            if brightnessValue > turnOffThreshold {
                brightnessBeforeTorch = nil
                return .off
            }
        }
        
        return currentMode
    }
    
    /// Sets the torch mode on the device and updates internal state.
    ///
    /// - Parameters:
    ///   - mode: Desired torch mode
    ///   - device: The capture device to control
    ///   - currentTime: Current system uptime
    private func setTorchMode(
        _ mode: AVCaptureDevice.TorchMode,
        on device: CaptureDeviceProtocol,
        at currentTime: TimeInterval
    ) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            device.torchMode = mode
            
            if mode == .on {
                try device.setTorchModeOn(level: torchLevel)
                isTorchOn = true
            } else {
                isTorchOn = false
            }
            
            lastTorchUpdate = currentTime
        } catch {
            print("Torch configuration failed: \(error.localizedDescription)")
        }
    }
}
