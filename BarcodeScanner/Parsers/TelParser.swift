//
//  TelParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the `tel:` URI scheme (RFC 3966).
///
/// The number is taken verbatim from everything after the prefix — we do
/// **not** strip extension parameters (`;ext=`, `;phone-context=`) or
/// collapse whitespace, on the assumption that the UI's "tap to dial"
/// behavior should see exactly what the QR encoded.
struct TelParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.lowercased().hasPrefix("tel:") else { return nil }
        return .phone(String(raw.dropFirst("tel:".count)))
    }
}
