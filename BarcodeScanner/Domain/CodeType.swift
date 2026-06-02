//
//  CodeType.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Vision

/// Symbologies recognized by the scanner pipeline.
///
/// The enum is intentionally narrower than `VNBarcodeSymbology` — it only
/// surfaces the formats the app actually handles in its UI. Anything else
/// collapses to `.unknown`, which the rendering layer treats as plain text.
public enum CodeType {
    case qr
    case dataMatrix
    case code39
    case code128
    case unknown

    /// Bridges Vision's `VNBarcodeSymbology` into the app's narrower enum.
    /// Unsupported symbologies fall through to `.unknown`.
    init(symbology: VNBarcodeSymbology) {
        switch symbology {
        case .qr:
            self = .qr
        case .dataMatrix:
            self = .dataMatrix
        case .code39:
            self = .code39
        case .code128:
            self = .code128
        default:
            self = .unknown
        }
    }
}
