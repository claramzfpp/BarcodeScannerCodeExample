# BarcodeScanner

iOS barcode and QR code scanner built with SwiftUI. Supports two scanning
backends — VisionKit's `DataScannerViewController` on capable hardware, and an
AVFoundation fallback for older devices — with automatic torch control based
on ambient brightness and structured parsing of common payload formats
(Wi-Fi, vCard, PIX, OTP, geo, crypto, and more).

## Features

- **Dual scanner backend.** VisionKit when available (iOS 16+ with Neural
  Engine, A12 Bionic or newer); AVFoundation everywhere else. Selection is
  transparent to the rest of the app — see
  [`GenericQRCodeView`](BarcodeScanner/ScannerView/GenericQRCodeView.swift).
- **Automatic torch.** Ambient brightness is read from EXIF metadata on each
  video frame (AVFoundation path) or estimated from ISO/exposure (VisionKit
  path). Hysteresis thresholds prevent flicker. See
  [`TorchManager`](BarcodeScanner/TorchManager.swift).
- **Structured payload parsing.** Recognizes 12 payload formats out of the
  box: URL, Wi-Fi, e-mail (`mailto:`), SMS (`sms:`/`SMSTO:`), phone (`tel:`),
  geo (`geo:`), contacts (vCard / MeCard), calendar events (`VEVENT`), OTP
  (`otpauth://`), Brazilian PIX (EMVCo), and crypto URIs (bitcoin, ethereum,
  …). Unknown payloads fall through to plain text so they can still be
  displayed verbatim.
- **Symbologies.** QR, Data Matrix, Code 39, Code 128.

## Requirements

- Xcode 16+
- iOS 16.0+ deployment target (VisionKit features require iOS 16; the
  AVFoundation fallback works on the same range with broader hardware
  support)
- Physical device for camera testing (the simulator displays a "camera not
  available" placeholder)

## Building & running

```sh
git clone https://github.com/claramzfpp/BarcodeScannerCodeExample.git
cd BarcodeScannerCodeExample
open BarcodeScanner.xcodeproj
```

Then **⌘R** in Xcode. The app needs `NSCameraUsageDescription` (already in
`Info.plist`) and will prompt for camera permission on first launch.

## Running the tests

```sh
xcodebuild \
  -project BarcodeScanner.xcodeproj \
  -scheme BarcodeScanner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

Unit tests cover the torch manager end-to-end (27 cases against a mock
capture device); UI tests cover app launch and the basic scanning flow.

## Architecture

The project follows SOLID principles. The three patterns that carry the
most weight:

### Strategy + Chain of Responsibility — payload parsing

`ScanContent.parse(raw)` delegates to
[`ScanContentParserRegistry`](BarcodeScanner/Parsers/ScanContentParserRegistry.swift),
which holds an ordered list of
[`ScanContentParser`](BarcodeScanner/Parsers/ScanContentParser.swift)
strategies. The chain stops at the first non-`nil` match and falls back to
`.text(raw)` when nothing claims the payload.

**Adding a new format** means creating one file that conforms to
`ScanContentParser` and registering it in the registry — no existing
parser changes. That's the Open/Closed Principle in action.

```
Parsers/
├── ScanContentParser.swift          ← protocol (Strategy)
├── ScanContentParserRegistry.swift  ← chain orchestrator
├── ScanPayloadEscaping.swift        ← shared escaping helpers
├── WifiParser.swift
├── VCardParser.swift
├── MeCardParser.swift
├── CalendarEventParser.swift
├── PixBRCodeParser.swift
├── OTPAuthParser.swift
├── MailtoParser.swift
├── SMSParser.swift
├── TelParser.swift
├── GeoParser.swift
├── CryptoParser.swift
└── URLParser.swift
```

### Adapter + Dependency Inversion — capture device

`TorchManager` never touches `AVCaptureDevice` directly — it depends on
[`CaptureDeviceProtocol`](BarcodeScanner/CaptureDevice/CaptureDeviceProtocol.swift)
and
[`CaptureDeviceFormatProtocol`](BarcodeScanner/CaptureDevice/CaptureDeviceFormatProtocol.swift).
In production, AVFoundation conforms via
[`AVCaptureDevice+Conformance`](BarcodeScanner/CaptureDevice/AVCaptureDevice+Conformance.swift)
(zero-cost adapter); in tests, `MockCaptureDevice` plays the same role with
deterministic ISO/exposure presets.

### Separation of concerns — UI

[`ContentView`](BarcodeScanner/ContentView.swift) only orchestrates: pick a
scanner backend, hold the last result, hand it off.
[`ScanResultDetails`](BarcodeScanner/Views/ScanResultDetails.swift) only
renders. Neither knows about the other's responsibilities, so both are easy
to preview, test, and re-use.

## Project structure

```
BarcodeScanner/
├── BarcodeScannerApp.swift          ← @main entry point
├── ContentView.swift                 ← root screen
├── TorchManager.swift                ← brightness-driven torch control
├── Domain/                           ← pure value types
│   ├── ScanResult.swift
│   ├── CodeType.swift
│   ├── ScanContent.swift
│   └── VCard.swift
├── Parsers/                          ← Strategy + Chain of Responsibility
│   └── (see "Architecture" above)
├── CaptureDevice/                    ← AVFoundation abstraction layer
│   ├── CaptureDeviceProtocol.swift
│   ├── CaptureDeviceFormatProtocol.swift
│   └── AVCaptureDevice+Conformance.swift
├── Views/
│   └── ScanResultDetails.swift       ← parsed-payload renderer
└── ScannerView/
    ├── GenericQRCodeView.swift              ← backend selector
    ├── QrScannerVisionKitView.swift         ← VisionKit path
    ├── QrScannerVisionKitCoordinator.swift
    └── QRScannerView/
        ├── QRScannerView.swift              ← AVFoundation path
        ├── QRScannerCoordinator.swift
        └── QRScannerController.swift

BarcodeScannerTests/
├── TorchManagerTests.swift           ← 27 cases driving TorchManager
├── BarcodeScannerTests.swift         ← Xcode template
└── Mocks/
    ├── MockCaptureDevice.swift
    ├── MockCaptureDeviceFormat.swift
    └── MockSampleBuffer.swift        ← synthesizes CMSampleBuffers with EXIF
```

## License

No license declared — all rights reserved by default. Open an issue if you'd
like to use the code under a specific license.
