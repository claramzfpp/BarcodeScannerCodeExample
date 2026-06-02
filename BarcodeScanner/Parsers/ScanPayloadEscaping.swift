//
//  ScanPayloadEscaping.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Backslash-aware string utilities shared by parsers that handle the
/// `KEY:VALUE;KEY:VALUE` micro-format used by WIFI and MECARD codes.
///
/// Both grammars allow a literal `\\;` (or `\\:`, `\\\\`) inside a value, so
/// a naive `split(separator: ";")` would corrupt SSIDs and contact fields
/// that contain those characters. The helpers here centralize the
/// escape-handling so each parser can stay focused on its schema.
enum ScanPayloadEscaping {

    /// Splits `input` on `separator` while honoring `\\` escape sequences.
    ///
    /// A backslash consumes the following character verbatim, so
    /// `"S:foo\\;bar;P:baz"` splits into `["S:foo;bar", "P:baz"]` instead of
    /// the three pieces a naive split would produce.
    ///
    /// - Parameters:
    ///   - input: The string to split.
    ///   - separator: The character to split on at the top escape level.
    /// - Returns: The resulting components in source order. An empty input
    ///   yields an empty array.
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

    /// Resolves backslash escapes inside a single Wi-Fi field value.
    ///
    /// Used after the field has already been separated from its key — at
    /// this point the surrounding `;` and `:` are gone and we only need to
    /// drop the escape character itself.
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
