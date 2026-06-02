//
//  ContentView.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import SwiftUI

/// Root screen of the app.
///
/// Orchestrates three responsibilities — and deliberately delegates each:
/// - **Pick a scanner backend.** ``GenericQRCodeView`` decides between
///   VisionKit and AVFoundation based on device capability + the user's
///   toggle.
/// - **Capture the latest scan.** Held locally as `result` and rebound to
///   the scanner via `@Binding`.
/// - **Render the parsed payload.** Handed off to ``ScanResultDetails``,
///   which has no knowledge of capture or backend selection.
///
/// Keeping each concern in its own type makes the view easy to preview and
/// easy to test — the only logic that lives here is "what to show while we
/// wait for a scan" and "reset the last scan when the backend toggle flips".
struct ContentView: View {
    @State private var shouldUseVisionKit: Bool = false
    @State private var result: ScanResult?

    var body: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $shouldUseVisionKit) {
                HStack(spacing: 0) {
                    Text("Should Use ").font(.title)
                    Text("VisionKit").font(.title).bold()
                }
            }

            GenericQRCodeView(
                result: $result,
                shouldUseVisionKit: $shouldUseVisionKit
            )
            .frame(maxHeight: 400)

            ScrollView {
                if let result {
                    ScanResultDetails(result: result)
                } else {
                    Text("Point the camera at a code…")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .onChange(of: shouldUseVisionKit) { _, _ in
            result = nil
        }
    }
}

#Preview {
    ContentView()
}
