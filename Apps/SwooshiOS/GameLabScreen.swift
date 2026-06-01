// Apps/SwooshiOS/GameLabScreen.swift — Local game loader for Cartridge

import SwiftUI
import SwooshArena
import WebKit

struct GameLabScreen: View {
    @AppStorage("cartridge.gameLab.url") private var urlString = "http://localhost:3000"
    @State private var loadedURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Local game URL") {
                    TextField("http://localhost:3000", text: $urlString)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    Button {
                        loadURL()
                    } label: {
                        Label("Load Game", systemImage: "play.rectangle.fill")
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .frame(maxHeight: 190)

            if let loadedURL {
                GameWebView(url: loadedURL)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            } else {
                ContentUnavailableView(
                    "No Game Loaded",
                    systemImage: "gamecontroller",
                    description: Text("Load a localhost, 127.0.0.1, ::1, 0.0.0.0, *.localhost, or file URL.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Game Lab")
        .task { loadURL() }
    }

    private func loadURL() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            loadedURL = try GameURLPolicy.validateLocalGameURL(trimmed)
            errorMessage = nil
        } catch {
            loadedURL = nil
            errorMessage = "Cartridge only loads local game URLs."
        }
    }
}

private struct GameWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView(frame: .zero)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
    }
}
