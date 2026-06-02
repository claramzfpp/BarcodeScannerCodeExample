//
//  OTPAuthParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the `otpauth://` URI scheme used by Google Authenticator,
/// 1Password, Authy and friends to provision TOTP/HOTP secrets.
///
/// Reference: https://github.com/google/google-authenticator/wiki/Key-Uri-Format
///
/// The label (everything after `otpauth://totp/` or `otpauth://hotp/`) often
/// contains a colon-separated `issuer:account`. We surface it as a single
/// string and let the UI decide how to render it — the official spec is
/// ambiguous enough that splitting it here would be error-prone.
struct OTPAuthParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.lowercased().hasPrefix("otpauth://"),
              let components = URLComponents(string: raw)
        else { return nil }

        let label = components.path.isEmpty ? nil : String(components.path.dropFirst())
        let queryItems = components.queryItems ?? []
        let secret = queryItems.first(where: { $0.name == "secret" })?.value
        let issuer = queryItems.first(where: { $0.name == "issuer" })?.value
        let algorithm = queryItems.first(where: { $0.name == "algorithm" })?.value

        return .otpAuth(label: label, issuer: issuer, secret: secret, algorithm: algorithm)
    }
}
