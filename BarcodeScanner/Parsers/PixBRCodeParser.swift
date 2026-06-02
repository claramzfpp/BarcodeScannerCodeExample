//
//  PixBRCodeParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for Brazilian PIX QR codes (EMVCo Merchant Presented Mode payloads).
///
/// The full EMVCo / PIX BR Code spec is a TLV (Tag-Length-Value) tree with
/// embedded CRC and merchant-account-information sub-templates. We
/// intentionally do **not** decode it here — the UI shows the payload
/// verbatim and lets the user copy it into their bank app. Detection is
/// based on the fixed payload-format-indicator prefix (`00020126` for
/// dynamic, `00020101` for static), plus an ASCII-only sanity check to
/// reject mangled inputs.
struct PixBRCodeParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.hasPrefix("00020126") || raw.hasPrefix("00020101") else { return nil }
        guard raw.allSatisfy({ $0.isASCII }) else { return nil }
        return .pixBRCode(payload: raw)
    }
}
