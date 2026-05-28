//
//  ContentView.swift
//  BarcodeScanner
//
//  Created by Clara Muniz on 28/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var shouldUseVisionKit: Bool = false
    
    var body: some View {
        VStack {
            
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
