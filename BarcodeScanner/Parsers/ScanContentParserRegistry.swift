//
//  ScanContentParserRegistry.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Chain-of-Responsibility entry point for scan payload interpretation.
///
/// The registry holds an ordered list of ``ScanContentParser`` strategies
/// and consults them one by one, returning the first non-`nil` result. If
/// no parser claims the payload it falls back to ``ScanContent/text(_:)``
/// with the original (un-trimmed) string so the caller can still display
/// the raw value.
///
/// **Order matters.** More specific prefixes (`WIFI:`, `BEGIN:VCARD`,
/// `MECARD:`, calendar events, EMVCo/PIX) must be checked before generic
/// schemes (`otpauth:`, `mailto:`, `tel:`, …), and `http(s)` URLs come last
/// so they don't accidentally absorb structured payloads whose `URL(string:)`
/// happens to succeed.
enum ScanContentParserRegistry {

    /// Parsers consulted in order. Mutate via source change only — there is
    /// intentionally no runtime registration API to keep the chain
    /// deterministic and testable.
    static let parsers: [ScanContentParser] = [
        WifiParser(),
        VCardParser(),
        MeCardParser(),
        CalendarEventParser(),
        PixBRCodeParser(),
        OTPAuthParser(),
        MailtoParser(),
        SMSParser(),
        TelParser(),
        GeoParser(),
        CryptoParser(),
        URLParser(),
    ]

    /// Runs the chain over `raw` and returns the first successful match.
    ///
    /// - Parameter raw: The exact string emitted by the scanner.
    /// - Returns: The most specific ``ScanContent`` case the chain could
    ///   recognize. Always returns a value — falls back to `.text(raw)` when
    ///   nothing matches.
    static func parse(_ raw: String) -> ScanContent {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for parser in parsers {
            if let match = parser.parse(trimmed) {
                return match
            }
        }
        return .text(raw)
    }
}

extension ScanContent {
    /// Best-effort classification of a raw scan payload.
    ///
    /// Delegates to ``ScanContentParserRegistry`` — see that type's
    /// documentation for the strategy chain and ordering guarantees.
    static func parse(_ raw: String) -> ScanContent {
        ScanContentParserRegistry.parse(raw)
    }
}
