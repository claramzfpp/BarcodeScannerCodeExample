//
//  GeoParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for the `geo:` URI scheme (RFC 5870).
///
/// Grammar (altitude and `crs`/`u` parameters intentionally dropped):
///
///     geo:<lat>,<lon>[?q=<query>]
///
/// A failure to parse latitude/longitude as `Double` rejects the payload
/// outright — the registry will then fall through to the URL parser or
/// `.text` fallback rather than emit a half-built ``ScanContent/geo``.
struct GeoParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
        guard raw.lowercased().hasPrefix("geo:") else { return nil }
        let body = String(raw.dropFirst("geo:".count))
        let split = body.split(separator: "?", maxSplits: 1).map(String.init)
        let coords = split.first ?? ""
        let queryPart = split.count > 1 ? split[1] : ""

        let parts = coords.split(separator: ",", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1])
        else { return nil }

        let query: String?
        if queryPart.isEmpty {
            query = nil
        } else {
            query = URLComponents(string: "?\(queryPart)")?
                .queryItems?
                .first(where: { $0.name == "q" })?
                .value
        }
        return .geo(latitude: lat, longitude: lon, query: query)
    }
}
