//
//  ScanResult.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Vision

public struct ScanResult: Equatable {
    public let value: String
    public let type: CodeType

    /// Structured interpretation of `value`. Computed on access so callers can
    /// display the raw string and the parsed fields side by side without paying
    /// the parsing cost up front.
    var content: ScanContent { ScanContent.parse(value) }

    public init(value: String, type: CodeType) {
        self.value = value
        self.type = type
    }
}

public enum CodeType {
    case qr
    case dataMatrix
    case code39
    case code128
    case unknown

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
