//
//  ScanContentParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Strategy for recognizing a single ``ScanContent`` payload format.
///
/// Each conformer is responsible for exactly one schema (Wi-Fi, vCard, geo,
/// otpauth, …). Conformers MUST be pure: given the same input they always
/// return the same result, and they never touch I/O, the network, or shared
/// state. A `nil` return means "this is not my format" — it must NOT be used
/// to signal "my format but invalid"; in the latter case the parser should
/// either return its best-effort parse or `nil` and let the chain fall
/// through to ``ScanContent/text(_:)``.
///
/// The full list of parsers is consulted in order by
/// ``ScanContentParserRegistry``. To add a new format, implement this
/// protocol and append the parser to the registry's `parsers` array — no
/// existing parser needs to change (Open/Closed Principle).
protocol ScanContentParser {
    /// Attempts to interpret `raw` as this parser's format.
    ///
    /// - Parameter raw: The trimmed scan payload. Whitespace at the edges is
    ///   already stripped by the registry — parsers should not re-trim.
    /// - Returns: A populated ``ScanContent`` case on a successful match, or
    ///   `nil` if the payload is not recognized as this format.
    func parse(_ raw: String) -> ScanContent?
}
