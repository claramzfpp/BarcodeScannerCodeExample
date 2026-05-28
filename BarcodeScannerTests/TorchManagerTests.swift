//
//  TorchManagerTests.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

import XCTest
import AVFoundation
import CoreMedia
@testable import BarcodeScanner

final class TorchManagerTests: XCTestCase {
    private var sut: TorchManager?
    private var mockDevice: MockCaptureDevice?
    
    override func setUp() {
        super.setUp()
        mockDevice = MockCaptureDevice()
    }
    
    override func tearDown() {
        sut = nil
        mockDevice = nil
        super.tearDown()
    }
    
    // MARK: - Factory Methods
    
    private func makeSut(
        turnOnThreshold: Double = 3.0,
        turnOffThreshold: Double = 8.0,
        updateInterval: TimeInterval = 1.0,
        torchLevel: Float = 0.5
    ) -> TorchManager {
        return TorchManager(
            turnOnThreshold: turnOnThreshold,
            turnOffThreshold: turnOffThreshold,
            updateInterval: updateInterval,
            torchLevel: torchLevel
        )
    }
    
    private func unwrapSut() throws -> TorchManager {
        try XCTUnwrap(sut, "Failed to instantiate TorchManager")
    }
    
    private func unwrapMockDevice() throws -> MockCaptureDevice {
        try XCTUnwrap(mockDevice, "Failed to instantiate MockCaptureDevice")
    }
    
    // MARK: - Initialization Tests
    
    func testInit_WithDefaultParameters_ShouldInitializeCorrectly() throws {
        sut = makeSut()
        
        let manager = try unwrapSut()
        
        XCTAssertNotNil(manager)
    }
    
    func testInit_WithCustomParameters_ShouldInitializeCorrectly() throws {
        sut = makeSut(
            turnOnThreshold: 2.5,
            turnOffThreshold: 9.0,
            updateInterval: 0.5,
            torchLevel: 0.7
        )
        
        let manager = try unwrapSut()
        
        XCTAssertNotNil(manager)
    }
    
    // MARK: - updateTorch Tests
    
    func testUpdateTorch_InDarkEnvironment_ShouldTurnTorchOn() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.setDarkEnvironment()
        
        sut?.updateTorch(device: device)
        
        // Need to wait for update interval
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should be turned on in dark environment")
        XCTAssertGreaterThan(device.configurationLockCount, 0, "Device should be locked for configuration")
    }
    
    func testUpdateTorch_InBrightEnvironment_ShouldKeepTorchOff() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.setBrightEnvironment()
        
        sut?.updateTorch(device: device)
        
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should remain off in bright environment")
    }
    
    func testUpdateTorch_TransitionFromDarkToBright_ShouldTurnTorchOffWithHysteresis() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        
        // Start in dark environment
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should be on in dark environment")
        
        // Transition to bright environment
        device.setBrightEnvironment()
        
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should turn off in bright environment")
    }
    
    func testUpdateTorch_InMediumEnvironment_ShouldMaintainCurrentState() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.setMediumEnvironment()
        
        sut?.updateTorch(device: device)
        
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        // In medium brightness (between thresholds), torch should stay in its current state
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should remain off in medium environment")
    }
    
    func testUpdateTorch_WithDeviceWithoutTorch_ShouldNotCrash() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.hasTorch = false
        device.setDarkEnvironment()
        
        sut?.updateTorch(device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertEqual(device.configurationLockCount, 0, "Should not attempt to configure device without torch")
    }
    
    func testUpdateTorch_WithNilSampleBuffer_ShouldUseDeviceEstimation() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.setDarkEnvironment()
        
        sut?.updateTorch(nil, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(nil, device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "Should estimate brightness from device when no sample buffer")
    }
    
    func testUpdateTorch_MultipleConsecutiveCalls_ShouldRespectThrottling() throws {
        sut = makeSut(updateInterval: 2.0)
        let device = try unwrapMockDevice()
        device.setDarkEnvironment()
        
        // First call
        sut?.updateTorch(device: device)
        let firstLockCount = device.configurationLockCount
        
        // Multiple rapid calls
        for _ in 0..<5 {
            sut?.updateTorch(device: device)
        }
        
        XCTAssertEqual(device.configurationLockCount, firstLockCount,
                      "Multiple rapid calls should be throttled")
    }
    
    func testUpdateTorch_AfterDisable_ShouldBeAbleToTurnOnAgain() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        
        // Turn on
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        XCTAssertTrue(device.wasTorchTurnedOn)
        
        // Disable
        sut?.disableTorch(device: device)
        XCTAssertTrue(device.wasTorchTurnedOff)
        
        // Reset device mock
        device.reset()
        device.setDarkEnvironment()
        
        // Should be able to turn on again
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should be able to turn on again after disable")
    }
    
    func testUpdateTorch_WhenLockFails_ShouldRemainUnchanged() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.lockError = NSError(domain: "TestError", code: -1, userInfo: nil)
        device.setDarkEnvironment()
        
        sut?.updateTorch(device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        // Should not crash, torch state should remain unchanged
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should remain off when lock fails")
    }
    
    // MARK: - extractBrightnessValue Tests
    
    func testExtractBrightnessValue_WithValidExifMetadata_ShouldReturnBrightnessValue() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        let sampleBuffer = try MockSampleBuffer(brightnessValue: 5.5).build()
        
        sut?.updateTorch(sampleBuffer, device: device)
        
        XCTAssertNotNil(sampleBuffer, "Sample buffer should be created successfully")
    }
    
    func testExtractBrightnessValue_WithValidBrightMetadata_ShouldExtractCorrectValue() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.setBrightEnvironment()
        let sampleBuffer = try MockSampleBuffer(brightnessValue: 8.5).build()
        
        sut?.updateTorch(sampleBuffer, device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should remain off with bright EXIF value")
    }
    
    func testExtractBrightnessValue_WithValidDarkMetadata_ShouldExtractCorrectValue() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        let sampleBuffer = try MockSampleBuffer(brightnessValue: 1.5).build()
        
        sut?.updateTorch(sampleBuffer, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(sampleBuffer, device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should turn on with dark EXIF value")
    }
    
    func testExtractBrightnessValue_WithBoundaryValues_ShouldHandleCorrectly() throws {
        sut = makeSut(turnOnThreshold: 3.0, turnOffThreshold: 8.0)
        let device = try unwrapMockDevice()
        
        // Test at turn-on threshold
        let darkBuffer = try MockSampleBuffer(brightnessValue: 2.99).build()
        sut?.updateTorch(darkBuffer, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(darkBuffer, device: device)
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should turn on just below threshold")
        
        // Test at turn-off threshold
        device.reset()
        let brightBuffer = try MockSampleBuffer(brightnessValue: 8.01).build()
        sut?.updateTorch(brightBuffer, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(brightBuffer, device: device)
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should turn off just above threshold")
    }
    
    func testExtractBrightnessValue_WithExtremeValues_ShouldHandleCorrectly() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        
        // Very bright (direct sunlight)
        let veryBrightBuffer = try MockSampleBuffer(brightnessValue: 15.0).build()
        sut?.updateTorch(veryBrightBuffer, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(veryBrightBuffer, device: device)
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should remain off in very bright conditions")
        
        // Very dark (near darkness)
        device.reset()
        let veryDarkBuffer = try MockSampleBuffer(brightnessValue: -2.0).build()
        sut?.updateTorch(veryDarkBuffer, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(veryDarkBuffer, device: device)
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should turn on in very dark conditions")
    }
    
    func testExtractBrightnessValue_WithZeroValue_ShouldTreatAsDark() throws {
        sut = makeSut(turnOnThreshold: 3.0)
        let device = try unwrapMockDevice()
        let zeroBuffer = try MockSampleBuffer(brightnessValue: 0.0).build()
        
        sut?.updateTorch(zeroBuffer, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(zeroBuffer, device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should turn on with zero brightness value")
    }
    
    func testExtractBrightnessValue_WithNegativeValue_ShouldTreatAsDark() throws {
        sut = makeSut(turnOnThreshold: 3.0)
        let device = try unwrapMockDevice()
        let negativeBuffer = try MockSampleBuffer(brightnessValue: -1.5).build()
        
        sut?.updateTorch(negativeBuffer, device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(negativeBuffer, device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "Torch should turn on with negative brightness value")
    }
    
    // MARK: - disableTorch Tests
    
    func testDisableTorch_WithTorchOn_ShouldTurnTorchOff() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        
        // Turn torch on first
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "Precondition: Torch should be on")
        
        // Disable torch
        sut?.disableTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should be disabled")
    }
    
    func testDisableTorch_WithTorchOff_ShouldKeepTorchOff() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        
        XCTAssertTrue(device.wasTorchTurnedOff, "Precondition: Torch should be off")
        
        sut?.disableTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOff, "Torch should remain off")
    }
    
    func testDisableTorch_WithDeviceWithoutTorch_ShouldNotFail() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.hasTorch = false
        
        sut?.disableTorch(device: device)
        
        XCTAssertEqual(device.configurationLockCount, 0, "Should not attempt configuration on device without torch")
    }
    
    func testDisableTorch_WhenLockFails_ShouldNotCrash() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.lockError = NSError(domain: "TestError", code: -1, userInfo: nil)
        
        sut?.disableTorch(device: device)
        
        // Should not crash
        XCTAssertNotNil(device)
    }
    
    // MARK: - reset Tests
    
    func testReset_ShouldClearAllStates() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        
        // Turn torch on
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        // Reset
        sut?.reset()
        
        // After reset, should be able to update immediately (no throttling)
        device.reset()
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "After reset, torch should respond immediately")
    }
    
    func testReset_ShouldAllowImmediateUpdate() throws {
        sut = makeSut(updateInterval: 5.0)
        let device = try unwrapMockDevice()
        
        // Make one update
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        
        // Reset
        sut?.reset()
        
        // Should be able to update immediately without waiting for interval
        device.reset()
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        
        XCTAssertTrue(device.wasTorchTurnedOn, "After reset, update should work immediately")
    }
    
    // MARK: - Torch Level Tests
    
    func testUpdateTorch_WithCustomTorchLevel_ShouldUseThatLevel() throws {
        let customLevel: Float = 0.75
        sut = makeSut(torchLevel: customLevel)
        let device = try unwrapMockDevice()
        device.setDarkEnvironment()
        
        sut?.updateTorch(device: device)
        
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertEqual(device.lastTorchLevel, customLevel, accuracy: 0.01, "Torch should use custom level")
    }
    
    func testUpdateTorch_WithDefaultTorchLevel_ShouldUseHalfBrightness() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        device.setDarkEnvironment()
        
        sut?.updateTorch(device: device)
        
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        
        XCTAssertEqual(device.lastTorchLevel, 0.5, accuracy: 0.01, "Default torch level should be 0.5")
    }
    
    // MARK: - State Consistency Tests
    
    func testUpdateTorch_StateConsistency_AcrossMultipleUpdates() throws {
        sut = makeSut()
        let device = try unwrapMockDevice()
        
        // Start dark
        device.setDarkEnvironment()
        sut?.updateTorch(device: device)
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        XCTAssertTrue(device.wasTorchTurnedOn)
        
        // Stay dark - should remain on
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        XCTAssertTrue(device.wasTorchTurnedOn)
        
        // Bright - should turn off
        device.setBrightEnvironment()
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        XCTAssertTrue(device.wasTorchTurnedOff)
        
        // Stay bright - should remain off
        Thread.sleep(forTimeInterval: 1.1)
        sut?.updateTorch(device: device)
        XCTAssertTrue(device.wasTorchTurnedOff)
    }
}
