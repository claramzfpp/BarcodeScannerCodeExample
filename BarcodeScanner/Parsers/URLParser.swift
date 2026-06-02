//
//  URLParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Fallback parser for plain `http(s)` URLs.
///
/// Must run **last** in the registry chain: `URL(string:)` happily accepts
/// arbitrary RFC 3986 syntax, so a payload like `mailto:...` or
/// `otpauth://...` would also pass — we restrict to `http`/`https` here to
/// keep this parser focused on web links and let the dedicated schemes
/// handle their own payloads earlier in the chain.
struct URLParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return .url(url)
    }
}
