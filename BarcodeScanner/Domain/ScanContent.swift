//
//  ScanContent.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Structured representation of the payload carried by a scanned code.
///
/// `ScanContent` is a closed sum type of every payload format the app knows
/// how to display. Conversion from a raw scan string is performed by
/// ``ScanContentParserRegistry`` — the entry point is the static
/// ``ScanContent/parse(_:)`` method, which returns the most specific case it
/// can recognize. When nothing matches a known schema the value is returned
/// as `.text(raw)` so the caller can still display it verbatim.
///
/// No side effects are ever performed during parsing — `ScanContent` is pure
/// data, safe to construct, compare and pass across boundaries.
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

extension ScanContent {
    /// Short human label describing the detected content kind.
    ///
    /// Used by the UI to title the "detected content" section. Localized in
    /// Portuguese to match the rest of the visible strings in the app.
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
