//
//  VCard.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import Foundation

/// Subset of vCard / MeCard fields that we surface to the UI.
///
/// The model is intentionally lossy: full vCard 4.0 has dozens of properties
/// (NICKNAME, GENDER, BDAY, X-* extensions, parameter qualifiers, …) and most
/// of them are noise in a scanning context. This struct keeps the fields a
/// human typically wants to see at a glance after pointing the camera at a
/// contact code.
struct VCard: Equatable {
    let fullName: String?
    let phones: [String]
    let emails: [String]
    let organization: String?
    let title: String?
    let address: String?
    let url: String?
}
