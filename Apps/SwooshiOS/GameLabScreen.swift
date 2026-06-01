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
    @State private var integrations: [GameIntegrationSummary] = GameLabScreen.localIntegrations
    @State private var cliStarters: [GameCLIStarterSummary] = GameLabScreen.localCLIStarters
    @State private var twoDProviders: [GameAssetProviderSummary] = GameLabScreen.local2DProviders
    @State private var threeDProviders: [GameAssetProviderSummary] = GameLabScreen.local3DProviders
    @State private var pipelines: [GamePipelineTemplateSummary] = GameLabScreen.localPipelines
    @State private var catalogError: String?
    @State private var isLoadingCatalog = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Integrations") {
                    ForEach(integrations) { integration in
                        catalogRow(
                            title: integration.displayName,
                            subtitle: integration.pluginSurfaces.joined(separator: " · "),
                            systemImage: integrationIconName(for: integration.kind),
                            badges: integration.capabilities
                        )
                    }
                }

                Section("CLI starters") {
                    ForEach(cliStarters) { starter in
                        catalogRow(
                            title: starter.displayName,
                            subtitle: starter.commandGroups.joined(separator: " · "),
                            systemImage: cliIconName(for: starter.kind),
                            badges: starter.inputModalities
                        )
                    }
                }

                Section("2D creation") {
                    ForEach(twoDProviders) { provider in
                        catalogRow(
                            title: provider.displayName,
                            subtitle: provider.strengths.joined(separator: " · "),
                            systemImage: "photo.on.rectangle",
                            badges: provider.capabilities
                        )
                    }
                }

                Section("3D generation") {
                    ForEach(threeDProviders) { provider in
                        catalogRow(
                            title: provider.displayName,
                            subtitle: provider.strengths.joined(separator: " · "),
                            systemImage: "cube.transparent",
                            badges: provider.defaultOutputFormats
                        )
                    }
                }

                Section("Pipelines") {
                    ForEach(pipelines) { pipeline in
                        catalogRow(
                            title: pipeline.name,
                            subtitle: "\(pipeline.nodeCount) nodes · \(pipeline.edgeCount) edges",
                            systemImage: "point.3.connected.trianglepath.dotted",
                            badges: pipeline.integrationIDs
                        )
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
            applyLocalCatalog()
            catalogError = nil
            return
        }
        do {
            let catalog = try await client.gameCreationCatalog()
            integrations = catalog.integrations
            cliStarters = catalog.cliStarters
            twoDProviders = catalog.twoD
            threeDProviders = catalog.threeD
            pipelines = catalog.pipelines
            catalogError = nil
        } catch {
            applyLocalCatalog()
            catalogError = "Using local Cartridge catalog."
        }
    }

    private func applyLocalCatalog() {
        integrations = Self.localIntegrations
        cliStarters = Self.localCLIStarters
        twoDProviders = Self.local2DProviders
        threeDProviders = Self.local3DProviders
        pipelines = Self.localPipelines
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

    @ViewBuilder
    private func catalogRow(title: String, subtitle: String, systemImage: String, badges: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(badges.prefix(6), id: \.self) { badge in
                        Text(badge)
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

    private func cliIconName(for kind: String) -> String {
        switch kind {
        case "laptop": "laptopcomputer"
        case "agent": "cpu"
        case "character": "person.crop.circle"
        default: "terminal"
        }
    }

    private func integrationIconName(for kind: String) -> String {
        switch kind {
        case "webRuntime": "globe"
        case "gameEngine": "gamecontroller"
        case "dccTool": "cube"
        case "ugcPlatform": "person.3.sequence"
        case "moddingPlatform": "hammer"
        default: "puzzlepiece.extension"
        }
    }

    private static let localIntegrations: [GameIntegrationSummary] = GameIntegrationCatalog.all.map {
        GameIntegrationSummary(
            id: $0.id,
            displayName: $0.displayName,
            kind: $0.kind.rawValue,
            capabilities: $0.capabilities.map(\.rawValue),
            supportedModes: $0.supportedModes.map(\.rawValue),
            exportFormats: $0.exportFormats.map(\.rawValue),
            pluginSurfaces: $0.pluginSurfaces,
            localURLPatterns: $0.localURLPatterns,
            pipelineNodeKinds: $0.pipelineNodeKinds.map(\.rawValue),
            notes: $0.notes
        )
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

    private static let local2DProviders: [GameAssetProviderSummary] = Game2DCreationCatalog.all.map {
        GameAssetProviderSummary(
            id: $0.id,
            displayName: $0.displayName,
            dimension: "2d",
            deployment: $0.deployment.rawValue,
            websiteURL: $0.websiteURL,
            capabilities: $0.capabilities.map(\.rawValue),
            requiredSecretNames: $0.requiredSecretNames,
            defaultOutputFormats: $0.defaultOutputFormats.map(\.rawValue),
            integrationIDs: $0.integrationIDs,
            workflows: $0.workflows.map {
                GameAssetWorkflowSummary(
                    id: $0.id,
                    displayName: $0.displayName,
                    providerID: $0.providerID,
                    deployment: $0.deployment.rawValue,
                    capabilities: $0.capabilities.map(\.rawValue),
                    inputKinds: $0.inputKinds.map(\.rawValue),
                    outputFormats: $0.outputFormats.map(\.rawValue),
                    recommendedFor: $0.recommendedFor,
                    sourceURLs: $0.sourceURLs,
                    notes: $0.notes
                )
            },
            strengths: $0.strengths,
            limitations: $0.limitations,
            sourceURLs: $0.sourceURLs
        )
    }

    private static let local3DProviders: [GameAssetProviderSummary] = Game3DGenerationCatalog.all.map {
        GameAssetProviderSummary(
            id: $0.id,
            displayName: $0.displayName,
            dimension: "3d",
            deployment: $0.deployment.rawValue,
            websiteURL: $0.websiteURL,
            capabilities: $0.capabilities.map(\.rawValue),
            requiredSecretNames: $0.requiredSecretNames,
            defaultOutputFormats: $0.defaultOutputFormats.map(\.rawValue),
            integrationIDs: $0.integrationIDs,
            workflows: $0.models.map {
                var inputKinds: [String] = []
                if $0.supportsTextInput { inputKinds.append("textPrompt") }
                if $0.supportsImageInput { inputKinds.append("referenceImage") }
                return GameAssetWorkflowSummary(
                    id: $0.id,
                    displayName: $0.displayName,
                    providerID: $0.providerID,
                    deployment: $0.deployment.rawValue,
                    capabilities: $0.capabilities.map(\.rawValue),
                    inputKinds: inputKinds,
                    outputFormats: $0.outputFormats.map(\.rawValue),
                    recommendedFor: $0.recommendedFor,
                    sourceURLs: $0.sourceURLs,
                    notes: [$0.license] + $0.localRequirements
                )
            },
            strengths: $0.strengths,
            limitations: $0.limitations,
            sourceURLs: $0.sourceURLs
        )
    }

    private static let localPipelines: [GamePipelineTemplateSummary] = {
        let pipelines = (try? GamePipelineTemplateCatalog.list()) ?? []
        return pipelines.map {
            GamePipelineTemplateSummary(
                id: $0.id,
                name: $0.name,
                nodeCount: $0.nodes.count,
                edgeCount: $0.edges.count,
                integrationIDs: GamePipelineTemplateCatalog.integrationIDs(for: $0.id)
            )
        }
    }()
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
