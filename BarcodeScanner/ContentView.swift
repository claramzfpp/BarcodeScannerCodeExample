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

            ScrollView {
                if let result {
                    ScanResultDetails(result: result)
                } else {
                    Text("Aponte a câmera para um código…")
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

/// Renders every piece of information extracted from a scan, as plain text.
/// No buttons, no taps, no side effects.
private struct ScanResultDetails: View {
    let result: ScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            section("Simbologia") {
                row("Tipo", String(describing: result.type))
            }

            section("Valor cru") {
                Text(result.value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            section("Conteúdo detectado: \(result.content.kindDescription)") {
                contentDetail(result.content)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func contentDetail(_ content: ScanContent) -> some View {
        switch content {
        case .url(let url):
            row("URL", url.absoluteString)
            if let host = url.host { row("Host", host) }
            if !url.path.isEmpty { row("Path", url.path) }
            if let query = url.query { row("Query", query) }

        case .wifi(let ssid, let password, let security, let hidden):
            row("SSID", ssid)
            row("Senha", password ?? "—")
            row("Segurança", security ?? "—")
            row("Oculta", hidden ? "Sim" : "Não")

        case .email(let to, let subject, let body):
            row("Para", to)
            if let subject { row("Assunto", subject) }
            if let body { row("Corpo", body) }

        case .sms(let to, let body):
            row("Para", to)
            if let body { row("Mensagem", body) }

        case .phone(let number):
            row("Número", number)

        case .geo(let lat, let lon, let query):
            row("Latitude", String(lat))
            row("Longitude", String(lon))
            if let query { row("Consulta", query) }

        case .contact(let card):
            if let name = card.fullName { row("Nome", name) }
            if let org = card.organization { row("Organização", org) }
            if let title = card.title { row("Cargo", title) }
            if !card.phones.isEmpty { row("Telefones", card.phones.joined(separator: ", ")) }
            if !card.emails.isEmpty { row("E-mails", card.emails.joined(separator: ", ")) }
            if let address = card.address { row("Endereço", address) }
            if let url = card.url { row("URL", url) }

        case .calendarEvent(let summary, let start, let end, let location):
            if let summary { row("Título", summary) }
            if let start { row("Início", start) }
            if let end { row("Fim", end) }
            if let location { row("Local", location) }

        case .otpAuth(let label, let issuer, let secret, let algorithm):
            if let label { row("Conta", label) }
            if let issuer { row("Emissor", issuer) }
            if let secret { row("Segredo", secret) }
            if let algorithm { row("Algoritmo", algorithm) }

        case .pixBRCode(let payload):
            row("Payload", payload)

        case .crypto(let scheme, let address):
            row("Rede", scheme)
            row("Endereço", address)

        case .text(let text):
            Text(text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: layout helpers

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
            Divider()
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ContentView()
}
