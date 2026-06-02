//
//  MailtoParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the `mailto:` URI scheme (RFC 6068).
///
/// Supports `mailto:user@example.com?subject=...&body=...`. The recipient
/// comes from the URL's `path`; subject and body are read out of the query
/// items if present.
struct MailtoParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.lowercased().hasPrefix("mailto:"),
              let components = URLComponents(string: raw)
        else { return nil }
        let to = components.path
        let subject = components.queryItems?.first(where: { $0.name == "subject" })?.value
        let body = components.queryItems?.first(where: { $0.name == "body" })?.value
        return .email(to: to, subject: subject, body: body)
    }
}
