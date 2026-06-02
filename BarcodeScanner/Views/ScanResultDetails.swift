//
//  ScanResultDetails.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import SwiftUI

/// Renders every piece of information extracted from a scan, as plain text.
///
/// This view is intentionally passive: no buttons, no taps, no side effects.
/// It only formats whatever ``ScanResult`` (and its decoded ``ScanContent``)
/// already carry, so it can be embedded anywhere a read-only summary is
/// useful — main screen, history list, debug inspectors.
///
/// The body is split into three vertical sections:
/// 1. **Symbology** — the symbology that produced the scan.
/// 2. **Raw value** — the exact string returned by the scanner.
/// 3. **Detected content** — a per-case breakdown of the parsed
///    ``ScanContent``.
struct ScanResultDetails: View {
    let result: ScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            section("Symbology") {
                row("Type", String(describing: result.type))
            }

            section("Raw value") {
                Text(result.value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            section("Detected content: \(result.content.kindDescription)") {
                contentDetail(result.content)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Builds the per-case detail rows for a given ``ScanContent``.
    @ViewBuilder
    private func contentDetail(_ content: ScanContent) -> some View {
        switch content {
        case .url(let url):
            row("URL", url.absoluteString)
            if let host = url.host { row("Host", host) }
            if !url.path.isEmpty { row("Path", url.path) }
            if let query = url.query { row("Query", query) }

        case .wifi(let ssid, let password, let security, let hidden):
            row("SSID", ssid)
            row("Password", password ?? "—")
            row("Security", security ?? "—")
            row("Hidden", hidden ? "Yes" : "No")

        case .email(let to, let subject, let body):
            row("To", to)
            if let subject { row("Subject", subject) }
            if let body { row("Body", body) }

        case .sms(let to, let body):
            row("To", to)
            if let body { row("Message", body) }

        case .phone(let number):
            row("Number", number)

        case .geo(let lat, let lon, let query):
            row("Latitude", String(lat))
            row("Longitude", String(lon))
            if let query { row("Query", query) }

        case .contact(let card):
            if let name = card.fullName { row("Name", name) }
            if let org = card.organization { row("Organization", org) }
            if let title = card.title { row("Title", title) }
            if !card.phones.isEmpty { row("Phones", card.phones.joined(separator: ", ")) }
            if !card.emails.isEmpty { row("Emails", card.emails.joined(separator: ", ")) }
            if let address = card.address { row("Address", address) }
            if let url = card.url { row("URL", url) }

        case .calendarEvent(let summary, let start, let end, let location):
            if let summary { row("Title", summary) }
            if let start { row("Start", start) }
            if let end { row("End", end) }
            if let location { row("Location", location) }

        case .otpAuth(let label, let issuer, let secret, let algorithm):
            if let label { row("Account", label) }
            if let issuer { row("Issuer", issuer) }
            if let secret { row("Secret", secret) }
            if let algorithm { row("Algorithm", algorithm) }

        case .pixBRCode(let payload):
            row("Payload", payload)

        case .crypto(let scheme, let address):
            row("Network", scheme)
            row("Address", address)

        case .text(let text):
            Text(text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: layout helpers

    /// Wraps `content` in a labeled section with a trailing divider.
    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
            Divider()
        }
    }

    /// Renders a single "label : value" line, with the label fixed-width so
    /// successive rows align vertically.
    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
