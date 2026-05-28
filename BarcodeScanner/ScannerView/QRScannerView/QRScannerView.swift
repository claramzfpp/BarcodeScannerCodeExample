//
//  QRScannerView.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

public import SwiftUI

/// Creates the view that is then integrated in ScanQRCodeView.
///
/// Note: `QRScanner` is the AVFoundation-based implementation. Prefer `GenericQRCodeScannerView`
/// when you want the app to choose the best available scanner implementation at runtime.
public struct QRScanner: UIViewControllerRepresentable {
    
    @Binding var result: ScanResult?

    init(_ result: Binding<ScanResult?>) {
        self._result = result
    }

    public func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {
    }

    public func makeCoordinator() -> QRScannerCoordinator {
        QRScannerCoordinator($result)
    }
}
