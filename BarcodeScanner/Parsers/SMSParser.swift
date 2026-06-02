//
//  SMSParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the two competing SMS QR formats.
///
/// - `SMSTO:<number>:<body>` — the legacy NTT DoCoMo encoding.
/// - `sms:<number>?body=<body>` — the URL-style scheme registered with IANA.
///
/// Both yield ``ScanContent/sms(to:body:)``. The body is optional in both
/// grammars; an empty body becomes `nil`.
struct SMSParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        let lower = raw.lowercased()
        let prefix: String
        if lower.hasPrefix("smsto:") { prefix = "smsto:" }
        else if lower.hasPrefix("sms:") { prefix = "sms:" }
        else { return nil }

        let body = String(raw.dropFirst(prefix.count))
        if prefix == "smsto:" {
            let parts = body.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let to = String(parts[0])
            let text = parts.count > 1 ? String(parts[1]) : nil
            return .sms(to: to, body: text)
        } else {
            if let components = URLComponents(string: raw) {
                let to = components.path
                let text = components.queryItems?.first(where: { $0.name == "body" })?.value
                return .sms(to: to, body: text)
            }
            return .sms(to: body, body: nil)
        }
    }
}
