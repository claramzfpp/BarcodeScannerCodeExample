//
//  MeCardParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the MeCard contact format — the compact alternative to vCard
/// popularized by Japanese mobile carriers and still emitted by many QR
/// generators.
///
/// Grammar (case-insensitive prefix, `;`-delimited fields with the same
/// backslash escaping as Wi-Fi):
///
///     MECARD:N:<name>;TEL:<phone>;EMAIL:<email>;ADR:<address>;URL:<url>;;
///
/// MeCard has no notion of organization, title, or typed phone/email lists,
/// so those fields on ``VCard`` are always `nil`/empty in the output.
struct MeCardParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.uppercased().hasPrefix("MECARD:") else { return nil }
        let body = String(raw.dropFirst("MECARD:".count))
        let fields = ScanPayloadEscaping.splitUnescaped(body, separator: ";")

        var fullName: String?
        var phones: [String] = []
        var emails: [String] = []
        var address: String?
        var url: String?

        for field in fields where !field.isEmpty {
            guard let colon = field.firstIndex(of: ":") else { continue }
            let key = field[..<colon].uppercased()
            let value = String(field[field.index(after: colon)...])
            switch key {
            case "N": fullName = value
            case "TEL": phones.append(value)
            case "EMAIL": emails.append(value)
            case "ADR": address = value
            case "URL": url = value
            default: break
            }
        }

        return .contact(VCard(
            fullName: fullName,
            phones: phones,
            emails: emails,
            organization: nil,
            title: nil,
            address: address,
            url: url
        ))
    }
}
