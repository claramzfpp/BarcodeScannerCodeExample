//
//  ScanContent.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Structured representation of the payload carried by a scanned code.
///
/// `ScanContent.parse(_:)` inspects the raw string of a scan and returns the most
/// specific case it can recognize. When nothing matches a known schema the value
/// is returned as `.text` so the caller can still display it verbatim.
///
/// No side effects are performed — parsing only extracts information.
enum ScanContent: Equatable {
    case url(URL)
    case wifi(ssid: String, password: String?, security: String?, hidden: Bool)
    case email(to: String, subject: String?, body: String?)
    case sms(to: String, body: String?)
    case phone(String)
    case geo(latitude: Double, longitude: Double, query: String?)
    case contact(VCard)
    case calendarEvent(summary: String?, start: String?, end: String?, location: String?)
    case otpAuth(label: String?, issuer: String?, secret: String?, algorithm: String?)
    case pixBRCode(payload: String)
    case crypto(scheme: String, address: String)
    case text(String)
}

/// Subset of vCard / MeCard fields that we surface to the UI.
struct VCard: Equatable {
    let fullName: String?
    let phones: [String]
    let emails: [String]
    let organization: String?
    let title: String?
    let address: String?
    let url: String?
}

extension ScanContent {
    /// Best-effort classification of a raw scan payload.
    static func parse(_ raw: String) -> ScanContent {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if let wifi = parseWifi(trimmed) { return wifi }
        if let vcard = parseVCard(trimmed) { return vcard }
        if let mecard = parseMeCard(trimmed) { return mecard }
        if let event = parseCalendarEvent(trimmed) { return event }
        if let pix = parsePixBRCode(trimmed) { return pix }
        if let otp = parseOTPAuth(trimmed) { return otp }
        if let mail = parseMailto(trimmed) { return mail }
        if let sms = parseSMS(trimmed) { return sms }
        if let tel = parseTel(trimmed) { return tel }
        if let geo = parseGeo(trimmed) { return geo }
        if let crypto = parseCrypto(trimmed) { return crypto }
        if let url = parseURL(trimmed) { return url }

        return .text(raw)
    }

    /// Short human label describing the detected content kind.
    var kindDescription: String {
        switch self {
        case .url: return "URL"
        case .wifi: return "Wi-Fi"
        case .email: return "E-mail"
        case .sms: return "SMS"
        case .phone: return "Telefone"
        case .geo: return "Localização"
        case .contact: return "Contato"
        case .calendarEvent: return "Evento de calendário"
        case .otpAuth: return "Autenticador (OTP)"
        case .pixBRCode: return "PIX BR Code"
        case .crypto: return "Endereço de criptomoeda"
        case .text: return "Texto"
        }
    }
}

// MARK: - Parsers

private extension ScanContent {

    static func parseWifi(_ raw: String) -> ScanContent? {
        guard raw.uppercased().hasPrefix("WIFI:") else { return nil }
        let body = String(raw.dropFirst("WIFI:".count))
        let fields = splitUnescaped(body, separator: ";")

        var ssid: String?
        var password: String?
        var security: String?
        var hidden = false

        for field in fields where !field.isEmpty {
            guard let colon = field.firstIndex(of: ":") else { continue }
            let key = field[..<colon].uppercased()
            let value = unescapeWifi(String(field[field.index(after: colon)...]))
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

    static func parseVCard(_ raw: String) -> ScanContent? {
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

    static func parseMeCard(_ raw: String) -> ScanContent? {
        guard raw.uppercased().hasPrefix("MECARD:") else { return nil }
        let body = String(raw.dropFirst("MECARD:".count))
        let fields = splitUnescaped(body, separator: ";")

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

    static func parseCalendarEvent(_ raw: String) -> ScanContent? {
        let upper = raw.uppercased()
        guard upper.contains("BEGIN:VEVENT") else { return nil }

        var summary: String?
        var start: String?
        var end: String?
        var location: String?

        for line in raw.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let entry = String(line)
            guard let colon = entry.firstIndex(of: ":") else { continue }
            let rawKey = String(entry[..<colon]).uppercased()
            let value = String(entry[entry.index(after: colon)...])
            let key = rawKey.split(separator: ";").first.map(String.init) ?? rawKey
            switch key {
            case "SUMMARY": summary = value
            case "DTSTART": start = value
            case "DTEND": end = value
            case "LOCATION": location = value
            default: break
            }
        }

        return .calendarEvent(summary: summary, start: start, end: end, location: location)
    }

    static func parsePixBRCode(_ raw: String) -> ScanContent? {
        // EMVCo / PIX BR Code starts with "00020126" (payload format indicator 00 + GUI 0126)
        // and is composed of TLV fields. We only detect — full decode is out of scope.
        guard raw.hasPrefix("00020126") || raw.hasPrefix("00020101") else { return nil }
        guard raw.allSatisfy({ $0.isASCII }) else { return nil }
        return .pixBRCode(payload: raw)
    }

    static func parseOTPAuth(_ raw: String) -> ScanContent? {
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

    static func parseMailto(_ raw: String) -> ScanContent? {
        guard raw.lowercased().hasPrefix("mailto:"),
              let components = URLComponents(string: raw)
        else { return nil }
        let to = components.path
        let subject = components.queryItems?.first(where: { $0.name == "subject" })?.value
        let body = components.queryItems?.first(where: { $0.name == "body" })?.value
        return .email(to: to, subject: subject, body: body)
    }

    static func parseSMS(_ raw: String) -> ScanContent? {
        let lower = raw.lowercased()
        let prefix: String
        if lower.hasPrefix("smsto:") { prefix = "smsto:" }
        else if lower.hasPrefix("sms:") { prefix = "sms:" }
        else { return nil }

        let body = String(raw.dropFirst(prefix.count))
        // SMSTO:+5511...:hello world  OR  sms:+5511...?body=hello
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

    static func parseTel(_ raw: String) -> ScanContent? {
        guard raw.lowercased().hasPrefix("tel:") else { return nil }
        return .phone(String(raw.dropFirst("tel:".count)))
    }

    static func parseGeo(_ raw: String) -> ScanContent? {
        guard raw.lowercased().hasPrefix("geo:") else { return nil }
        let body = String(raw.dropFirst("geo:".count))
        let (coords, queryPart) = body.split(separator: "?", maxSplits: 1).map(String.init).pad(to: 2, with: "")
        let parts = coords.split(separator: ",", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1])
        else { return nil }
        let query: String?
        if queryPart.isEmpty {
            query = nil
        } else {
            let q = URLComponents(string: "?\(queryPart)")?.queryItems?.first(where: { $0.name == "q" })?.value
            query = q
        }
        return .geo(latitude: lat, longitude: lon, query: query)
    }

    static func parseCrypto(_ raw: String) -> ScanContent? {
        let knownSchemes = ["bitcoin", "ethereum", "litecoin", "dogecoin", "monero"]
        for scheme in knownSchemes {
            let prefix = "\(scheme):"
            if raw.lowercased().hasPrefix(prefix) {
                let rest = String(raw.dropFirst(prefix.count))
                let address = rest.split(separator: "?", maxSplits: 1).first.map(String.init) ?? rest
                return .crypto(scheme: scheme, address: address)
            }
        }
        return nil
    }

    static func parseURL(_ raw: String) -> ScanContent? {
        guard let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return .url(url)
    }

    // MARK: helpers

    /// Splits on `separator` while honoring backslash escapes (used by WIFI/MECARD).
    static func splitUnescaped(_ input: String, separator: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var escape = false
        for ch in input {
            if escape {
                current.append(ch)
                escape = false
            } else if ch == "\\" {
                escape = true
            } else if ch == separator {
                result.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    static func unescapeWifi(_ input: String) -> String {
        var out = ""
        var escape = false
        for ch in input {
            if escape {
                out.append(ch)
                escape = false
            } else if ch == "\\" {
                escape = true
            } else {
                out.append(ch)
            }
        }
        return out
    }
}

private extension Array where Element == String {
    func pad(to count: Int, with placeholder: String) -> (String, String) {
        let first = self.first ?? placeholder
        let second = self.count > 1 ? self[1] : placeholder
        _ = count
        return (first, second)
    }
}
