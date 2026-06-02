//
//  WifiParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the de-facto "Wi-Fi network configuration" QR format.
///
/// Grammar (case-insensitive prefix, fields are `;`-delimited and may use
/// backslash escapes):
///
///     WIFI:S:<ssid>;P:<password>;T:<security>;H:<hidden>;;
///
/// Only `S` is required — everything else is optional. `H` is treated as a
/// boolean (`"true"` only); any other value collapses to `false`.
struct WifiParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.uppercased().hasPrefix("WIFI:") else { return nil }
        let body = String(raw.dropFirst("WIFI:".count))
        let fields = ScanPayloadEscaping.splitUnescaped(body, separator: ";")

        var ssid: String?
        var password: String?
        var security: String?
        var hidden = false

        for field in fields where !field.isEmpty {
            guard let colon = field.firstIndex(of: ":") else { continue }
            let key = field[..<colon].uppercased()
            let value = ScanPayloadEscaping.unescapeWifi(String(field[field.index(after: colon)...]))
            switch key {
            case "S": ssid = value
            case "P": password = value
            case "T": security = value
            case "H": hidden = (value.lowercased() == "true")
            default: break
            }
        }

        guard let ssid else { return nil }
        return .wifi(
            ssid: ssid,
            password: (password?.isEmpty == false) ? password : nil,
            security: (security?.isEmpty == false) ? security : nil,
            hidden: hidden
        )
    }
}
