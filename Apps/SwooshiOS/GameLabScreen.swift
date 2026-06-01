// Apps/SwooshiOS/GameLabScreen.swift — Local game loader for Cartridge

import SwiftUI
import SwooshArena
import SwooshClient
import WebKit

struct GameLabScreen: View {
    @Environment(ClientSession.self) private var session
    @AppStorage("cartridge.gameLab.url") private var urlString = "http://localhost:3000"
    @State private var loadedURL: URL?
    @State private var errorMessage: String?
    @State private var cliStarters: [GameCLIStarterSummary] = GameLabScreen.localCLIStarters
    @State private var catalogError: String?
    @State private var isLoadingCatalog = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("CLI starters") {
                    ForEach(cliStarters) { starter in
                        VStack(alignment: .leading, spacing: 8) {
                            Label(starter.displayName, systemImage: iconName(for: starter.kind))
                                .font(.headline)
                            Text(starter.commandGroups.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(starter.inputModalities, id: \.self) { modality in
                                        Text(modality)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.thinMaterial, in: Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        Task { await loadCatalog() }
                    } label: {
                        Label(isLoadingCatalog ? "Refreshing" : "Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoadingCatalog)

                    if let catalogError {
                        Text(catalogError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

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
            .frame(maxHeight: 380)

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
        .task {
            loadURL()
            await loadCatalog()
        }
    }

    private func loadCatalog() async {
        guard !isLoadingCatalog else { return }
        isLoadingCatalog = true
        defer { isLoadingCatalog = false }
        guard session.isPaired, let client = session.client() else {
            cliStarters = Self.localCLIStarters
            catalogError = nil
            return
        }
        do {
            cliStarters = try await client.gameCreationCatalog().cliStarters
            catalogError = nil
        } catch {
            cliStarters = Self.localCLIStarters
            catalogError = "Using local Cartridge catalog."
        }
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

    private func iconName(for kind: String) -> String {
        switch kind {
        case "laptop": "laptopcomputer"
        case "agent": "cpu"
        case "character": "person.crop.circle"
        default: "terminal"
        }
    }

    private static let localCLIStarters: [GameCLIStarterSummary] = GameCLIStarterCatalog.all.map {
        GameCLIStarterSummary(
            id: $0.id,
            displayName: $0.displayName,
            kind: $0.kind.rawValue,
            capabilities: $0.capabilities.map(\.rawValue),
            inputModalities: $0.inputModalities.map(\.rawValue),
            outputFiles: $0.outputFiles,
            commandGroups: $0.commandGroups,
            recommendedFor: $0.recommendedFor,
            sourceInspirations: $0.sourceInspirations,
            notes: $0.notes
        )
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
