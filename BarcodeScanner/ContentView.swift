//
//  ContentView.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

internal import SwiftUI

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
            
            VStack {
                Text(result?.value ?? "").font(.title)
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: shouldUseVisionKit) { oldValue, newValue in
            result = nil
        }
    }
}

#Preview {
    ContentView()
}
