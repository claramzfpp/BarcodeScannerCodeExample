//
//  GenericQRCodeView.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import SwiftUI

/// A generic view for QR code scanning that automatically selects the best available
/// implementation based on device capabilities.
///
/// This view acts as an abstraction layer that dynamically chooses between two
/// QR code scanner implementations:
///
/// - **VisionKit** (`QrScannerVisionKitView`): Used when available, provides a modern
///   native iOS experience with advanced detection features and optimized interface.
///
/// - **AVFoundation** (`QRScanner`): Used as a fallback for devices that don't support
///   VisionKit, ensuring compatibility with older iOS versions and hardware.
///
/// ## Why not use VisionKit exclusively?
///
/// VisionKit with DataScannerViewController support (used for QR code scanning) requires:
/// - iOS 16.0 or later
/// - Hardware with Neural Engine support (A12 Bionic chips or later)
///
/// Many devices still in use run iOS 16 but lack the necessary hardware, including:
/// - iPhone 8 and 8 Plus (A11 chip)
/// - iPhone X (A11 chip)
/// - iPad 6th generation (A10 chip)
///
/// To maintain compatibility with these devices and ensure all users can scan QR codes,
/// we maintain an AVFoundation-based implementation as a fallback.
///
/// - Note: Availability checking is performed through the static property
///   `QrScannerVisionKitView.scannerAvailable` which detects both iOS version and
///   device hardware capabilities.
///
struct GenericQRCodeView: View {
    @Binding var result: ScanResult?
    @Binding var shouldUseVisionKit: Bool
    let payloadFilter: ((String) -> Bool)?

    init(
        result: Binding<ScanResult?>,
        shouldUseVisionKit: Binding<Bool>
    ) {
        self._result = result
        self._shouldUseVisionKit = shouldUseVisionKit
    }

    var body: some View {
        if QrScannerVisionKitView.scannerAvailable, shouldUseVisionKit {
            QrScannerVisionKitView($result)
        } else {
            QRScanner($result)
        }
    }
}
