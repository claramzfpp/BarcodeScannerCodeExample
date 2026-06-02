//
//  ScanResult.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Value type describing a single successful scan.
///
/// `ScanResult` carries the raw payload returned by the scanner together with
/// the symbology that produced it. The structured interpretation of `value`
/// (URL, Wi-Fi, vCard, etc.) is exposed through the computed `content`
/// property so callers can choose whether they want the raw string, the parsed
/// representation, or both.
public struct ScanResult: Equatable {
    /// The exact string returned by the underlying scanner, untouched.
    public let value: String

    /// The symbology that originated `value` (QR, Data Matrix, Code39, …).
    public let type: CodeType

    /// Structured interpretation of `value`. Computed on access so callers can
    /// display the raw string and the parsed fields side by side without
    /// paying the parsing cost up front.
    var content: ScanContent { ScanContent.parse(value) }

    public init(value: String, type: CodeType) {
        self.value = value
        self.type = type
    }
}
