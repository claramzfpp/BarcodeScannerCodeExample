//
//  VCardParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the vCard 2.1/3.0/4.0 contact format.
///
/// Recognized by the `BEGIN:VCARD` opener. Lines follow the
/// `PROPERTY[;PARAM=…]:VALUE` shape, and only the subset that maps cleanly to
/// ``VCard`` is extracted — TYPE/PREF parameters are deliberately ignored
/// because the UI doesn't surface them today. `ADR`'s `;`-separated parts
/// (PO box; ext.; street; city; …) are flattened into a single line.
struct VCardParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.uppercased().hasPrefix("BEGIN:VCARD") else { return nil }

        var fullName: String?
        var phones: [String] = []
        var emails: [String] = []
        var organization: String?
        var title: String?
        var address: String?
        var url: String?

        for line in raw.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let entry = String(line)
            guard let colon = entry.firstIndex(of: ":") else { continue }
            let rawKey = String(entry[..<colon]).uppercased()
            let value = String(entry[entry.index(after: colon)...])
            // Strip vCard parameters: e.g. "TEL;TYPE=CELL" -> "TEL"
            let key = rawKey.split(separator: ";").first.map(String.init) ?? rawKey

            switch key {
            case "FN": fullName = value
            case "TEL": phones.append(value)
            case "EMAIL": emails.append(value)
            case "ORG": organization = value
            case "TITLE": title = value
            case "ADR": address = value.replacingOccurrences(of: ";", with: " ").trimmingCharacters(in: .whitespaces)
            case "URL": url = value
            default: break
            }
        }

        let card = VCard(
            fullName: fullName,
            phones: phones,
            emails: emails,
            organization: organization,
            title: title,
            address: address,
            url: url
        )
        return .contact(card)
    }
}
