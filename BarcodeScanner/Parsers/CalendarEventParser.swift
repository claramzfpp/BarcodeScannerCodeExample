//
//  CalendarEventParser.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Parser for iCalendar `VEVENT` blocks embedded in a QR code.
///
/// Recognized when the payload contains `BEGIN:VEVENT` anywhere — generators
/// vary on whether they wrap the event in a full `VCALENDAR` envelope, so
/// this parser is intentionally permissive. Only the four fields the UI
/// surfaces (`SUMMARY`, `DTSTART`, `DTEND`, `LOCATION`) are extracted;
/// timezone parameters and recurrence rules are out of scope.
struct CalendarEventParser: ScanContentParser {
    func parse(_ raw: String) -> ScanContent? {
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
}
