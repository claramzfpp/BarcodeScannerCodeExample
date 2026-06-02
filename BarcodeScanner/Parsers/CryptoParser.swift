//
//  CryptoParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for cryptocurrency payment URIs.
///
/// Recognizes the `<scheme>:<address>[?...]` shape for a fixed list of
/// well-known networks (BIP-21 and analogues). The address is taken verbatim
/// up to the first `?` — request parameters (amount, label, message) are
/// dropped because the UI doesn't surface them today.
///
/// To add a new network, append its scheme to ``CryptoParser/knownSchemes``.
struct CryptoParser: ScanContentParser {

    /// Schemes considered cryptocurrency URIs by this parser.
    /// Lower-case; matched case-insensitively against the payload prefix.
    static let knownSchemes = ["bitcoin", "ethereum", "litecoin", "dogecoin", "monero"]

    func parse(_ raw: String) -> ScanContent? {
        for scheme in Self.knownSchemes {
            let prefix = "\(scheme):"
            if raw.lowercased().hasPrefix(prefix) {
                let rest = String(raw.dropFirst(prefix.count))
                let address = rest.split(separator: "?", maxSplits: 1).first.map(String.init) ?? rest
                return .crypto(scheme: scheme, address: address)
            }
        }
        return nil
    }
}
