// SwooshAPI/APIHelpers.swift — 0.9S Shared route + runtime helpers
//
// Pure functions used by both `SwooshAPIServer.build()` and the
// `APIRuntimeState` actor: error translation and runtime-config wire-format
// builders.

import Foundation
import Hummingbird
import SwooshClient
import SwooshConfig
import SwooshChatSDK
import SwooshTools

func makeChatAdaptersResponse(
    catalog: ChatAdapterCatalog,
    store: ChatAdapterToggleStore,
    stateCatalog: ChatStateAdapterCatalog,
    stateStore: ChatStateAdapterToggleStore
) async throws -> ChatAdaptersResponse {
    let statuses = try await catalog.statuses(store: store)
    let stateStatuses = try await stateCatalog.statuses(store: stateStore)
    return ChatAdapterProjection.response(platformStatuses: statuses, stateStatuses: stateStatuses)
}

func apiHTTPError(_ error: Error) -> HTTPError {
    if let apiError = error as? APIError {
        switch apiError {
        case .notFound(let message):
            return HTTPError(.notFound, message: message)
        case .unauthorized:
            return HTTPError(.unauthorized, message: "unauthorized")
        case .badRequest(let message):
            return HTTPError(.badRequest, message: message)
        case .internalError(let message):
            return HTTPError(.internalServerError, message: message)
        }
    }
    return HTTPError(.internalServerError, message: error.localizedDescription)
}

func runtimeConfigResponse(_ config: SwooshRuntimeConfig?) -> RuntimeConfigResponse {
    guard let config else {
        return RuntimeConfigResponse(
            configured: false,
            setupMode: nil,
            permissionProfile: nil,
            modelPath: nil,
            daemonHost: nil,
            daemonPort: nil,
            preferredProviderID: nil,
            localDiagnosticFallback: false,
            toolPolicy: nil,
            safetyFlags: []
        )
    }
    let policy = config.toolPolicy
    return RuntimeConfigResponse(
        configured: true,
        setupMode: config.setupMode,
        permissionProfile: config.permissionProfile,
        modelPath: config.modelPath,
        daemonHost: config.daemonHost,
        daemonPort: config.daemonPort,
        preferredProviderID: config.preferredProviderID,
        localDiagnosticFallback: config.localDiagnosticFallback,
        toolPolicy: ToolPolicySummary(
            maxToolCallsPerTurn: policy.maxToolCallsPerTurn,
            maxToolChainDepth: policy.maxToolChainDepth,
            allowModelToolCalls: policy.allowModelToolCalls,
            allowHumanOnlyFromModel: policy.allowHumanOnlyFromModel,
            allowCriticalToolsFromModel: policy.allowCriticalToolsFromModel,
            requireApprovalForMediumRiskAndAbove: policy.requireApprovalForMediumRiskAndAbove
        ),
        safetyFlags: safetyFlagSummaries(config.safetyConfig)
    )
}

func safetyFlagSummaries(_ config: SwooshSafetyConfig) -> [RuntimeFlagSummary] {
    [
        RuntimeFlagSummary(id: "autonomousTradingEnabled", label: "Autonomous trading", enabled: config.autonomousTradingEnabled),
        RuntimeFlagSummary(id: "humanPromptedTradingEnabled", label: "Human-prompted trading", enabled: config.humanPromptedTradingEnabled),
        RuntimeFlagSummary(id: "swapExecutionEnabled", label: "Swap execution", enabled: config.swapExecutionEnabled),
        RuntimeFlagSummary(id: "portfolioRecommendationsEnabled", label: "Portfolio recommendations", enabled: config.portfolioRecommendationsEnabled),
        RuntimeFlagSummary(id: "privateKeyCustodyEnabled", label: "Private-key custody", enabled: config.privateKeyCustodyEnabled),
        RuntimeFlagSummary(id: "seedPhraseIngestionEnabled", label: "Seed phrase ingestion", enabled: config.seedPhraseIngestionEnabled),
        RuntimeFlagSummary(id: "cookieIngestionEnabled", label: "Cookie ingestion", enabled: config.cookieIngestionEnabled),
        RuntimeFlagSummary(id: "shellToBlockchainBridgeEnabled", label: "Shell to blockchain bridge", enabled: config.shellToBlockchainBridgeEnabled),
        RuntimeFlagSummary(id: "modelSelfApprovalEnabled", label: "Model self-approval", enabled: config.modelSelfApprovalEnabled),
        RuntimeFlagSummary(id: "mainnetWritesByDefault", label: "Mainnet writes by default", enabled: config.mainnetWritesByDefault),
    ]
}
